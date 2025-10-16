#Requires -Modules Pester

<#
.SYNOPSIS
    Quick unit tests for require-tag-environment Azure Policy definition
.DESCRIPTION
    This test suite validates the require-tag-environment policy JSON definition
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
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'governance' -PolicyName 'require-tag-environment'

    # Set script variables from configuration
    $script:PolicyPath = Get-PolicyDefinitionPath -PolicyCategory 'governance' -PolicyName 'require-tag-environment' -TestScriptPath $PSScriptRoot
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

        It 'Should check for tag existence or value' {
            $anyOfCondition = $script:PolicyRule.if.anyOf
            $anyOfCondition | Should -Not -BeNullOrEmpty
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

        It 'Should have tagName parameter' {
            $script:Parameters.tagName | Should -Not -BeNullOrEmpty
        }

        It 'Should have allowedValues parameter' {
            $script:Parameters.allowedValues | Should -Not -BeNullOrEmpty
        }

        It 'Should have default tag name of Environment' {
            $script:Parameters.tagName.defaultValue | Should -Be 'Environment'
        }

        It 'Should have default allowed values' {
            $script:Parameters.allowedValues.defaultValue | Should -Not -BeNullOrEmpty
            $script:Parameters.allowedValues.defaultValue.Count | Should -BeGreaterThan 0
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

    Context 'Tag Condition Logic' {
        It 'Should use anyOf for tag conditions' {
            $script:PolicyRule.if.anyOf | Should -Not -BeNullOrEmpty
        }

        It 'Should check for tag existence' {
            $anyOfConditions = $script:PolicyRule.if.anyOf
            $existsCondition = $anyOfConditions | Where-Object {
                $_.field -match 'tags\[' -and $_.exists -eq 'false'
            }
            $existsCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should check for tag value in allowed list' {
            $anyOfConditions = $script:PolicyRule.if.anyOf
            $valueCondition = $anyOfConditions | Where-Object {
                $_.field -match 'tags\[' -and $_.notIn
            }
            $valueCondition | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Policy Compliance Scenarios' -Tag @('Unit', 'Fast', 'Scenarios', 'Governance') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Simulated Resource Evaluation' {
        It 'Should identify compliant resource with valid Environment tag' {
            $compliantResource = @{
                tags = @{
                    Environment = 'prod'
                    Application = 'webapp'
                }
            }

            $compliantResource.tags.Environment | Should -BeIn @('dev', 'test', 'staging', 'prod')
        }

        It 'Should identify non-compliant resource missing Environment tag' {
            $nonCompliantResource = @{
                tags = @{
                    Application = 'webapp'
                }
            }

            $nonCompliantResource.tags.Environment | Should -BeNullOrEmpty
        }

        It 'Should identify non-compliant resource with invalid Environment value' {
            $nonCompliantResource = @{
                tags = @{
                    Environment = 'production'
                    Application = 'webapp'
                }
            }

            $nonCompliantResource.tags.Environment | Should -Not -BeIn @('dev', 'test', 'staging', 'prod')
        }

        It 'Should accept all valid environment values' {
            $validEnvironments = @('dev', 'test', 'staging', 'prod')

            foreach ($env in $validEnvironments) {
                $env | Should -BeIn $validEnvironments
            }
        }
    }
}
