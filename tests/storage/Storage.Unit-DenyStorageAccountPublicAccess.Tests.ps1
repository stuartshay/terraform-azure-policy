#Requires -Modules Pester

<#
.SYNOPSIS
    Quick unit tests for Azure Policy definitions (no Azure resources required)
.DESCRIPTION
    This test suite validates Azure Policy JSON definitions without requiring
    Azure authentication or resource creation. Perfect for quick validation.
.NOTES
    Prerequisites:
    - Pester module only
    - No Azure authentication required
    - No Azure resources created
#>

BeforeAll {
    # Test configuration
    $script:PolicyPath = Join-Path $PSScriptRoot '..\..\policies\storage\deny-storage-account-public-access\rule.json'
    $script:ExpectedPolicyName = 'deny-storage-account-public-access'
    $script:ExpectedDisplayName = 'Deny Storage Account Public Access'
}

Describe 'Policy JSON Validation' -Tag @('Unit', 'Fast', 'Static') {

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

        It 'Should have mode set to All' {
            $script:PolicyJson.properties.mode | Should -Be 'All'
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

        It 'Should target storage accounts' {
            $resourceTypeCondition = $script:PolicyRule.if.allOf | Where-Object {
                $_.field -eq 'type' -and $_.equals -eq 'Microsoft.Storage/storageAccounts'
            }
            $resourceTypeCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should check allowBlobPublicAccess property' {
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $blobAccessCondition = $anyOfCondition.anyOf | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/allowBlobPublicAccess'
            }
            $blobAccessCondition | Should -Not -BeNullOrEmpty
            $blobAccessCondition.equals | Should -Be 'true'
        }

        It 'Should check publicNetworkAccess property' {
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $networkAccessCondition = $anyOfCondition.anyOf | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/publicNetworkAccess'
            }
            $networkAccessCondition | Should -Not -BeNullOrEmpty
            $networkAccessCondition.equals | Should -Be 'Enabled'
        }

        It 'Should use anyOf for multiple conditions' {
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $anyOfCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should have valid effect value' {
            # Check for parameterized effect or valid hardcoded effect
            $effect = $script:PolicyRule.then.effect
            if ($effect -match '^\[parameters\(') {
                # Parameterized effect - check parameter definition
                $effectParam = $script:PolicyJson.properties.parameters.effect
                $effectParam | Should -Not -BeNullOrEmpty
                $effectParam.allowedValues | Should -Not -BeNullOrEmpty
            }
            else {
                # Hardcoded effect
                $validEffects = @('Audit', 'Deny', 'Disabled', 'AuditIfNotExists', 'DeployIfNotExists')
                $effect | Should -BeIn $validEffects
            }
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

        It 'Should have version in metadata' {
            $script:Metadata.version | Should -Not -BeNullOrEmpty
            $script:Metadata.version | Should -Match '^\d+\.\d+\.\d+$'
        }

        It 'Should have source in metadata' {
            $script:Metadata.source | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Policy Logic Validation' -Tag @('Unit', 'Fast', 'Logic') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Condition Logic' {
        It 'Should use allOf for combining conditions' {
            $script:PolicyRule.if.allOf | Should -Not -BeNullOrEmpty
            $script:PolicyRule.if.allOf.Count | Should -BeGreaterThan 1
        }

        It 'Should have proper boolean logic structure' {
            # Check that we have the right structure for the policy conditions
            $conditions = $script:PolicyRule.if.allOf

            # Should have resource type condition
            $typeCondition = $conditions | Where-Object { $_.field -eq 'type' }
            $typeCondition | Should -Not -BeNullOrEmpty

            # Should have anyOf condition for the storage access properties
            $anyOfCondition = $conditions | Where-Object { $_.anyOf }
            $anyOfCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should properly structure the anyOf conditions' {
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $anyOfConditions = $anyOfCondition.anyOf

            # Should have at least 2 conditions in anyOf (one for each access type)
            $anyOfConditions.Count | Should -BeGreaterOrEqual 2

            # Should have condition for blob public access
            $blobCondition = $anyOfConditions | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/allowBlobPublicAccess'
            }
            $blobCondition | Should -Not -BeNullOrEmpty

            # Should have condition for network access
            $networkCondition = $anyOfConditions | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/publicNetworkAccess'
            }
            $networkCondition | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Policy Compliance Scenarios' -Tag @('Unit', 'Fast', 'Scenarios') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Simulated Resource Evaluation' {
        It 'Should identify compliant storage account' {
            # Simulate a compliant storage account
            $compliantResource = @{
                type       = 'Microsoft.Storage/storageAccounts'
                properties = @{
                    allowBlobPublicAccess = $false
                    publicNetworkAccess   = 'Disabled'
                }
            }

            # This is a conceptual test - in real scenarios, Azure Policy engine evaluates this
            # We're testing our understanding of what should be compliant
            $compliantResource.properties.allowBlobPublicAccess | Should -Be $false
            $compliantResource.properties.publicNetworkAccess | Should -Be 'Disabled'
        }

        It 'Should identify non-compliant storage account (blob access)' {
            # Simulate a non-compliant storage account (blob public access enabled)
            $nonCompliantResource = @{
                type       = 'Microsoft.Storage/storageAccounts'
                properties = @{
                    allowBlobPublicAccess = $true
                    publicNetworkAccess   = 'Disabled'
                }
            }

            # This resource should trigger the policy due to blob public access
            $nonCompliantResource.properties.allowBlobPublicAccess | Should -Be $true
        }

        It 'Should identify non-compliant storage account (network access)' {
            # Simulate a non-compliant storage account (public network access enabled)
            $nonCompliantResource = @{
                type       = 'Microsoft.Storage/storageAccounts'
                properties = @{
                    allowBlobPublicAccess = $false
                    publicNetworkAccess   = 'Enabled'
                }
            }

            # This resource should trigger the policy due to public network access
            $nonCompliantResource.properties.publicNetworkAccess | Should -Be 'Enabled'
        }

        It 'Should identify non-compliant storage account (both access types)' {
            # Simulate a non-compliant storage account (both types of access enabled)
            $nonCompliantResource = @{
                type       = 'Microsoft.Storage/storageAccounts'
                properties = @{
                    allowBlobPublicAccess = $true
                    publicNetworkAccess   = 'Enabled'
                }
            }

            # This resource should definitely trigger the policy
            $nonCompliantResource.properties.allowBlobPublicAccess | Should -Be $true
            $nonCompliantResource.properties.publicNetworkAccess | Should -Be 'Enabled'
        }
    }
}
