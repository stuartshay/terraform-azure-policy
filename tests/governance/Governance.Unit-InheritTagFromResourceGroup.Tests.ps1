#Requires -Modules Pester

<#
.SYNOPSIS
    Quick unit tests for inherit-tag-from-resource-group Azure Policy definition
.DESCRIPTION
    This test suite validates the inherit-tag-from-resource-group policy JSON definition
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
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'governance' -PolicyName 'inherit-tag-from-resource-group'

    # Set script variables from configuration
    $script:PolicyPath = Get-PolicyDefinitionPath -PolicyCategory 'governance' -PolicyName 'inherit-tag-from-resource-group' -TestScriptPath $PSScriptRoot
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

        It 'Should use modify effect' {
            $script:PolicyRule.then.effect | Should -Be 'modify'
        }

        It 'Should have details for modify effect' {
            $script:PolicyRule.then.details | Should -Not -BeNullOrEmpty
        }

        It 'Should have roleDefinitionIds for modify effect' {
            $script:PolicyRule.then.details.roleDefinitionIds | Should -Not -BeNullOrEmpty
        }

        It 'Should have operations for modify effect' {
            $script:PolicyRule.then.details.operations | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Policy Parameters Validation' {
        BeforeAll {
            $script:Parameters = (Get-Content $script:PolicyPath -Raw | ConvertFrom-Json).properties.parameters
        }

        It 'Should have tagName parameter' {
            $script:Parameters.tagName | Should -Not -BeNullOrEmpty
        }

        It 'Should have default tag name' {
            $script:Parameters.tagName.defaultValue | Should -Not -BeNullOrEmpty
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

    Context 'Tag Inheritance Logic' {
        It 'Should use allOf for conditions' {
            $script:PolicyRule.if.allOf | Should -Not -BeNullOrEmpty
        }

        It 'Should check if resource does not have tag' {
            $allOfConditions = $script:PolicyRule.if.allOf
            $existsCondition = $allOfConditions | Where-Object {
                $_.exists -eq 'false'
            }
            $existsCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should check if resource group has tag' {
            $allOfConditions = $script:PolicyRule.if.allOf
            $rgCondition = $allOfConditions | Where-Object {
                $_.value -match 'resourceGroup'
            }
            $rgCondition | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Modify Effect Details' {
        It 'Should have add operation' {
            $operations = $script:PolicyRule.then.details.operations
            $addOp = $operations | Where-Object { $_.operation -eq 'add' }
            $addOp | Should -Not -BeNullOrEmpty
        }

        It 'Should copy value from resource group' {
            $operations = $script:PolicyRule.then.details.operations
            $addOp = $operations | Where-Object { $_.operation -eq 'add' }
            $addOp.value | Should -Match 'resourceGroup'
        }
    }
}
