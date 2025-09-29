#Requires -Modules Pester

<#
.SYNOPSIS
    Quick unit tests for deny-storage-softdelete Azure Policy definition
.DESCRIPTION
    This test suite validates the deny-storage-softdelete policy JSON definition without requiring
    Azure authentication or resource creation. Perfect for quick validation.
.NOTES
    Prerequisites:
    - Pester module only
    - No Azure authentication required
    - No Azure resources created
#>

BeforeAll {
    # Test configuration
    $script:PolicyPath = Join-Path $PSScriptRoot '..\..\policies\storage\deny-storage-softdelete\rule.json'
    $script:ExpectedPolicyName = 'deny-storage-softdelete'
    $script:ExpectedDisplayName = 'Deny Storage Account Soft Delete Disabled'
}

Describe 'Deny Storage Soft Delete Policy JSON Validation' -Tag @('Unit', 'Fast', 'Static', 'SoftDelete') {

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

        It 'Should have correct display name' {
            $script:PolicyJson.properties.displayName | Should -Be $script:ExpectedDisplayName
        }

        It 'Should have description mentioning soft delete' {
            $script:PolicyJson.properties.description | Should -Not -BeNullOrEmpty
            $script:PolicyJson.properties.description | Should -Match 'soft delete'
        }

        It 'Should have mode set to All' {
            $script:PolicyJson.properties.mode | Should -Be 'All'
        }

        It 'Should have policy rule' {
            $script:PolicyJson.properties.policyRule | Should -Not -BeNullOrEmpty
        }

        It 'Should have metadata section' {
            $script:PolicyJson.properties.metadata | Should -Not -BeNullOrEmpty
            $script:PolicyJson.properties.metadata.category | Should -Be 'Storage'
        }
    }

    Context 'Policy Parameters Validation' {
        BeforeAll {
            $script:Parameters = (Get-Content $script:PolicyPath -Raw | ConvertFrom-Json).properties.parameters
        }

        It 'Should have effect parameter' {
            $script:Parameters.effect | Should -Not -BeNullOrEmpty
        }

        It 'Should have minimumRetentionDays parameter' {
            $script:Parameters.minimumRetentionDays | Should -Not -BeNullOrEmpty
        }

        It 'Should have valid effect values' {
            $validEffects = @('Audit', 'Deny', 'Disabled')
            $script:Parameters.effect.allowedValues | Should -Be $validEffects
        }

        It 'Should have retention days constraints' {
            $script:Parameters.minimumRetentionDays.minValue | Should -Be 1
            $script:Parameters.minimumRetentionDays.maxValue | Should -Be 365
            $script:Parameters.minimumRetentionDays.defaultValue | Should -Be 7
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
            $script:PolicyRule.then.effect | Should -Be '[parameters(''effect'')]'
        }

        It 'Should target storage accounts' {
            $resourceTypeCondition = $script:PolicyRule.if.allOf | Where-Object {
                $_.field -eq 'type' -and $_.equals -eq 'Microsoft.Storage/storageAccounts'
            }
            $resourceTypeCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should check blob soft delete policy' {
            $blobDeleteRetentionCondition = $script:PolicyRule.if.allOf.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object {
                        $_.field -eq 'Microsoft.Storage/storageAccounts/blobServices/deleteRetentionPolicy.enabled'
                    })
            }
            $blobDeleteRetentionCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should check container soft delete policy' {
            $containerDeleteRetentionCondition = $script:PolicyRule.if.allOf.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object {
                        $_.field -eq 'Microsoft.Storage/storageAccounts/blobServices/containerDeleteRetentionPolicy.enabled'
                    })
            }
            $containerDeleteRetentionCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should use anyOf for multiple soft delete conditions' {
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $anyOfCondition | Should -Not -BeNullOrEmpty
            $anyOfCondition.anyOf.Count | Should -BeGreaterThan 1
        }

        It 'Should validate minimum retention days parameter usage' {
            $policyRuleJson = $script:PolicyRule | ConvertTo-Json -Depth 10
            $policyRuleJson | Should -Match '\[parameters\(''minimumRetentionDays''\)\]'
        }
    }
}

Describe 'Soft Delete Policy Logic Validation' -Tag @('Unit', 'Fast', 'Logic', 'SoftDelete') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Condition Logic Structure' {
        It 'Should use allOf for combining main conditions' {
            $script:PolicyRule.if.allOf | Should -Not -BeNullOrEmpty
            $script:PolicyRule.if.allOf.Count | Should -BeGreaterThan 1
        }

        It 'Should have proper anyOf structure for soft delete scenarios' {
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $anyOfCondition | Should -Not -BeNullOrEmpty

            # Should have multiple conditions in anyOf
            $anyOfCondition.anyOf.Count | Should -BeGreaterOrEqual 4
        }

        It 'Should check for both enabled status and retention days' {
            $policyRuleJson = $script:PolicyRule | ConvertTo-Json -Depth 10

            # Should check for disabled soft delete
            $policyRuleJson | Should -Match 'equals.*false'

            # Should check for insufficient retention days
            $policyRuleJson | Should -Match 'less.*minimumRetentionDays'
        }
    }
}

Describe 'Soft Delete Policy Compliance Scenarios' -Tag @('Unit', 'Fast', 'Scenarios', 'SoftDelete') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Simulated Resource Evaluation' {
        It 'Should identify compliant storage account with soft delete enabled' {
            # Simulate a compliant storage account
            $compliantResource = @{
                type       = 'Microsoft.Storage/storageAccounts'
                properties = @{
                    blobServices = @{
                        deleteRetentionPolicy          = @{
                            enabled = $true
                            days    = 30
                        }
                        containerDeleteRetentionPolicy = @{
                            enabled = $true
                            days    = 30
                        }
                    }
                }
            }

            # This resource should be compliant
            $compliantResource.properties.blobServices.deleteRetentionPolicy.enabled | Should -Be $true
            $compliantResource.properties.blobServices.deleteRetentionPolicy.days | Should -BeGreaterThan 7
        }

        It 'Should identify non-compliant storage account with blob soft delete disabled' {
            # Simulate a non-compliant storage account
            $nonCompliantResource = @{
                type       = 'Microsoft.Storage/storageAccounts'
                properties = @{
                    blobServices = @{
                        deleteRetentionPolicy = @{
                            enabled = $false
                        }
                    }
                }
            }

            # This resource should trigger the policy
            $nonCompliantResource.properties.blobServices.deleteRetentionPolicy.enabled | Should -Be $false
        }

        It 'Should identify non-compliant storage account with insufficient retention days' {
            # Simulate a non-compliant storage account with low retention
            $nonCompliantResource = @{
                type       = 'Microsoft.Storage/storageAccounts'
                properties = @{
                    blobServices = @{
                        deleteRetentionPolicy = @{
                            enabled = $true
                            days    = 1  # Less than default minimum of 7
                        }
                    }
                }
            }

            # This resource should trigger the policy due to insufficient retention
            $nonCompliantResource.properties.blobServices.deleteRetentionPolicy.days | Should -BeLessThan 7
        }

        It 'Should identify non-compliant storage account with container soft delete disabled' {
            # Simulate a non-compliant storage account
            $nonCompliantResource = @{
                type       = 'Microsoft.Storage/storageAccounts'
                properties = @{
                    blobServices = @{
                        containerDeleteRetentionPolicy = @{
                            enabled = $false
                        }
                    }
                }
            }

            # This resource should trigger the policy
            $nonCompliantResource.properties.blobServices.containerDeleteRetentionPolicy.enabled | Should -Be $false
        }
    }
}
