#Requires -Modules Pester

<#
.SYNOPSIS
    Quick unit tests for enforce-naming-convention-func-app Azure Policy definition
.DESCRIPTION
    This test suite validates the enforce-naming-convention-func-app policy JSON definition
    without requiring Azure authentication or resource creation.
.NOTES
    Prerequisites:
    - Pester module only
    - No Azure authentication required
    - No Azure resources created
#>

BeforeAll {
    # Import centralized configuration
    . "$PSScriptRoot\..\..\config\config-loader.ps1"

    # Initialize test configuration for this specific policy
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'governance' -PolicyName 'enforce-naming-convention-func-app'

    # Set script variables from configuration
    $script:PolicyPath = Get-PolicyDefinitionPath -PolicyCategory 'governance' -PolicyName 'enforce-naming-convention-func-app' -TestScriptPath $PSScriptRoot
    $script:ExpectedPolicyName = $script:TestConfig.Policy.Name
    $script:ExpectedDisplayName = $script:TestConfig.Policy.DisplayName
}

Describe 'Policy JSON Validation' -Tag @('Unit', 'Fast', 'Static', 'Governance') {

    Context 'File Structure' {
        It 'Should have policy definition file' {
            Test-Path $script:PolicyPath | Should -Be $true
        }

        It 'Should be valid JSON' {
            { Get-Content $script:PolicyPath -Raw | ConvertFrom-Json } | Should -Not -Throw
        }
    }

    Context 'Policy Content Validation' {
        BeforeAll {
            $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        }

        It 'Should have properties section' {
            $script:PolicyJson.properties | Should -Not -BeNullOrEmpty
        }

        It 'Should have display name' {
            $script:PolicyJson.properties.displayName | Should -Be $script:ExpectedDisplayName
        }

        It 'Should have description' {
            $script:PolicyJson.properties.description | Should -Not -BeNullOrEmpty
            $script:PolicyJson.properties.description.Length | Should -BeGreaterThan 10
        }

        It 'Should have mode set to Indexed' {
            $script:PolicyJson.properties.mode | Should -Be 'Indexed'
        }

        It 'Should have policy rule' {
            $script:PolicyJson.properties.policyRule | Should -Not -BeNullOrEmpty
        }

        It 'Should have metadata section' {
            $script:PolicyJson.properties.metadata | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Policy Rule Validation' {
        BeforeAll {
            $script:PolicyRule = (Get-Content $script:PolicyPath -Raw | ConvertFrom-Json).properties.policyRule
        }

        It 'Should have if condition' {
            $script:PolicyRule.if | Should -Not -BeNullOrEmpty
        }

        It 'Should have then effect' {
            $script:PolicyRule.then | Should -Not -BeNullOrEmpty
            $script:PolicyRule.then.effect | Should -Not -BeNullOrEmpty
        }

        It 'Should target Function Apps' {
            $allOfConditions = $script:PolicyRule.if.allOf
            $typeCondition = $allOfConditions | Where-Object {
                $_.field -eq 'type' -and $_.equals -eq 'Microsoft.Web/sites'
            }
            $typeCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should check for functionapp kind' {
            $allOfConditions = $script:PolicyRule.if.allOf
            $kindCondition = $allOfConditions | Where-Object {
                $_.field -eq 'kind' -and $_.contains -eq 'functionapp'
            }
            $kindCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should check Function App name pattern' {
            $allOfConditions = $script:PolicyRule.if.allOf
            $nameCondition = $allOfConditions | Where-Object {
                $_.field -eq 'name' -and $_.notMatch
            }
            $nameCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should have valid effect value' {
            $effect = $script:PolicyRule.then.effect
            if ($effect -match '^\[parameters\(') {
                $effectParam = $script:PolicyJson.properties.parameters.effect
                $effectParam | Should -Not -BeNullOrEmpty
                $effectParam.allowedValues | Should -Not -BeNullOrEmpty
            }
            else {
                $validEffects = @('Audit', 'Deny', 'Disabled')
                $effect | Should -BeIn $validEffects
            }
        }
    }

    Context 'Policy Parameters Validation' {
        BeforeAll {
            $script:Parameters = (Get-Content $script:PolicyPath -Raw | ConvertFrom-Json).properties.parameters
        }

        It 'Should have effect parameter' {
            $script:Parameters.effect | Should -Not -BeNullOrEmpty
        }

        It 'Should have namePattern parameter' {
            $script:Parameters.namePattern | Should -Not -BeNullOrEmpty
        }

        It 'Should have default naming pattern' {
            $script:Parameters.namePattern.defaultValue | Should -Not -BeNullOrEmpty
            $script:Parameters.namePattern.defaultValue | Should -Match '^\^func-'
        }
    }

    Context 'Policy Metadata Validation' {
        BeforeAll {
            $script:Metadata = (Get-Content $script:PolicyPath -Raw | ConvertFrom-Json).properties.metadata
        }

        It 'Should have category' {
            $script:Metadata.category | Should -Not -BeNullOrEmpty
        }

        It 'Should have version' {
            $script:Metadata.version | Should -Not -BeNullOrEmpty
            $script:Metadata.version | Should -Match '^\d+\.\d+\.\d+$'
        }

        It 'Should have source in metadata' {
            $script:Metadata.source | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Policy Logic Validation' -Tag @('Unit', 'Fast', 'Logic', 'Governance') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Naming Convention Logic' {
        It 'Should use allOf for combining conditions' {
            $script:PolicyRule.if.allOf | Should -Not -BeNullOrEmpty
        }

        It 'Should check resource type, kind, and name pattern' {
            $allOfConditions = $script:PolicyRule.if.allOf
            $allOfConditions.Count | Should -BeGreaterOrEqual 3
        }
    }
}

Describe 'Policy Compliance Scenarios' -Tag @('Unit', 'Fast', 'Scenarios', 'Governance') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:DefaultPattern = $script:PolicyJson.properties.parameters.namePattern.defaultValue
    }

    Context 'Simulated Resource Evaluation' {
        It 'Should identify compliant Function App names' {
            $validNames = @('func-dev-api-001', 'func-prod-payment-002', 'func-test-notification-123')

            foreach ($name in $validNames) {
                $name | Should -Match $script:DefaultPattern
            }
        }

        It 'Should identify non-compliant Function App names' {
            $invalidNames = @('myfunction', 'funcdevapi001', 'func-qa-api-001')

            foreach ($name in $invalidNames) {
                $name | Should -Not -Match $script:DefaultPattern
            }
        }

        It 'Should enforce hyphen-separated format' {
            'funcdevapi001' | Should -Not -Match $script:DefaultPattern
            'func-dev-api-001' | Should -Match $script:DefaultPattern
        }

        It 'Should enforce environment prefix with hyphens' {
            'funcdevapi001' | Should -Not -Match $script:DefaultPattern
            'func-dev-api-001' | Should -Match $script:DefaultPattern
        }

        It 'Should require valid environment values' {
            'func-qa-api-001' | Should -Not -Match $script:DefaultPattern
            'func-dev-api-001' | Should -Match $script:DefaultPattern
        }
    }
}
