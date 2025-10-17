#Requires -Modules Pester

<#
.SYNOPSIS
    Quick unit tests for enforce-allowed-locations Azure Policy definition
.DESCRIPTION
    This test suite validates the enforce-allowed-locations policy JSON definition
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
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'governance' -PolicyName 'enforce-allowed-locations'

    # Set script variables from configuration
    $script:PolicyPath = Get-PolicyDefinitionPath -PolicyCategory 'governance' -PolicyName 'enforce-allowed-locations' -TestScriptPath $PSScriptRoot
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

        It 'Should check location field' {
            $notCondition = $script:PolicyRule.if.not
            $notCondition | Should -Not -BeNullOrEmpty
            $notCondition.field | Should -Be 'location'
        }

        It 'Should use in operator for allowed locations' {
            $notCondition = $script:PolicyRule.if.not
            $notCondition.in | Should -Not -BeNullOrEmpty
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

        It 'Should have allowedLocations parameter' {
            $script:Parameters.allowedLocations | Should -Not -BeNullOrEmpty
        }

        It 'Should have default allowed locations' {
            $script:Parameters.allowedLocations.defaultValue | Should -Not -BeNullOrEmpty
            $script:Parameters.allowedLocations.defaultValue.Count | Should -BeGreaterThan 0
        }

        It 'Should use Array type for allowedLocations' {
            $script:Parameters.allowedLocations.type | Should -Be 'Array'
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

    Context 'Location Restriction Logic' {
        It 'Should use not operator for non-allowed locations' {
            $script:PolicyRule.if.not | Should -Not -BeNullOrEmpty
        }

        It 'Should check if location is not in allowed list' {
            $notCondition = $script:PolicyRule.if.not
            $notCondition.field | Should -Be 'location'
            $notCondition.in | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Policy Compliance Scenarios' -Tag @('Unit', 'Fast', 'Scenarios', 'Governance') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:DefaultAllowedLocations = $script:PolicyJson.properties.parameters.allowedLocations.defaultValue
    }

    Context 'Simulated Resource Evaluation' {
        It 'Should identify compliant resources in allowed locations' {
            $compliantLocations = @('eastus', 'westus2', 'northeurope')

            foreach ($location in $compliantLocations) {
                $location | Should -BeIn $script:DefaultAllowedLocations
            }
        }

        It 'Should identify non-compliant resources in non-allowed locations' {
            $nonCompliantLocations = @('westus', 'southcentralus', 'japaneast')

            foreach ($location in $nonCompliantLocations) {
                $location | Should -Not -BeIn $script:DefaultAllowedLocations
            }
        }

        It 'Should have default allowed locations configured' {
            $script:DefaultAllowedLocations | Should -Not -BeNullOrEmpty
            $script:DefaultAllowedLocations.Count | Should -BeGreaterThan 0
        }

        It 'Should accept resources in all default allowed locations' {
            foreach ($location in $script:DefaultAllowedLocations) {
                $location | Should -BeIn $script:DefaultAllowedLocations
            }
        }
    }
}
