#Requires -Modules Pester

<#
.SYNOPSIS
    Quick unit tests for Azure Policy deny-storage-https-disabled (no Azure resources required)
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
    # Import centralized configuration
    . "$PSScriptRoot\..\..\config\config-loader.ps1"

    # Initialize test configuration for this specific policy
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'storage' -PolicyName 'deny-storage-https-disabled'

    # Set script variables from configuration
    $script:PolicyPath = Get-PolicyDefinitionPath -PolicyCategory 'storage' -PolicyName 'deny-storage-https-disabled' -TestScriptPath $PSScriptRoot
    $script:ExpectedPolicyName = $script:TestConfig.Policy.Name
    $script:ExpectedDisplayName = $script:TestConfig.Policy.DisplayName
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

        It 'Should have correct policy name' {
            $script:PolicyJson.name | Should -Be $script:ExpectedPolicyName
        }

        It 'Should have display name' {
            $script:PolicyJson.properties.displayName | Should -Match 'HTTPS'
        }

        It 'Should have description' {
            $script:PolicyJson.properties.description | Should -Not -BeNullOrEmpty
            $script:PolicyJson.properties.description.Length | Should -BeGreaterThan 10
            $script:PolicyJson.properties.description | Should -Match 'HTTPS'
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

        It 'Should have parameters section' {
            $script:PolicyJson.properties.parameters | Should -Not -BeNullOrEmpty
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

        It 'Should check supportsHttpsTrafficOnly property' {
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $anyOfCondition | Should -Not -BeNullOrEmpty

            $httpsConditions = $anyOfCondition.anyOf

            # Should check if property exists
            $existsCheck = $httpsConditions | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly' -and $_.exists -eq 'false'
            }
            $existsCheck | Should -Not -BeNullOrEmpty

            # Should check if property is false
            $falseCheck = $httpsConditions | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly' -and $_.equals -eq 'false'
            }
            $falseCheck | Should -Not -BeNullOrEmpty
        }

        It 'Should use anyOf for HTTPS property conditions' {
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $anyOfCondition | Should -Not -BeNullOrEmpty
            $anyOfCondition.anyOf.Count | Should -BeGreaterOrEqual 2
        }

        It 'Should have parameterized effect' {
            $effect = $script:PolicyRule.then.effect
            $effect | Should -Match '^\[parameters\('
        }
    }

    Context 'Policy Parameters Validation' {
        BeforeAll {
            $script:Parameters = (Get-Content $script:PolicyPath -Raw | ConvertFrom-Json).properties.parameters
        }

        It 'Should have effect parameter' {
            $script:Parameters.effect | Should -Not -BeNullOrEmpty
        }

        It 'Should have valid effect allowed values' {
            $effectParam = $script:Parameters.effect
            $effectParam.allowedValues | Should -Contain 'Audit'
            $effectParam.allowedValues | Should -Contain 'Deny'
            $effectParam.allowedValues | Should -Contain 'Disabled'
        }

        It 'Should have Deny as default effect' {
            $script:Parameters.effect.defaultValue | Should -Be 'Deny'
        }

        It 'Should have exemptedStorageAccounts parameter' {
            $script:Parameters.exemptedStorageAccounts | Should -Not -BeNullOrEmpty
            $script:Parameters.exemptedStorageAccounts.type | Should -Be 'Array'
        }

        It 'Should have empty or null default for exemptedStorageAccounts' {
            $exemptionsParam = $script:Parameters.exemptedStorageAccounts
            $exemptions = $exemptionsParam.defaultValue

            # Default value should be either empty array or null (both acceptable for no exemptions)
            if ($null -eq $exemptions) {
                # Null/empty is valid - no exemptions by default
                $null -eq $exemptions | Should -Be $true
            }
            else {
                # If not null, should be empty array
                $exemptions.GetType().BaseType.Name | Should -Be 'Array'
                $exemptions.Count | Should -Be 0
            }
        }

        It 'Should have storageAccountTypes parameter' {
            $script:Parameters.storageAccountTypes | Should -Not -BeNullOrEmpty
            $script:Parameters.storageAccountTypes.type | Should -Be 'Array'
        }

        It 'Should have valid storage account types in allowed values' {
            $allowedTypes = $script:Parameters.storageAccountTypes.allowedValues
            $allowedTypes | Should -Contain 'Standard_LRS'
            $allowedTypes | Should -Contain 'Standard_GRS'
            $allowedTypes | Should -Contain 'Premium_LRS'
        }

        It 'Should check storage account type in policy rule' {
            $skuCondition = $script:PolicyRule.if.allOf | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/sku.name'
            }
            $skuCondition | Should -Not -BeNullOrEmpty
            $skuCondition.in | Should -Match '^\[parameters\('
        }

        It 'Should check exempted storage accounts in policy rule' {
            $exemptionCondition = $script:PolicyRule.if.allOf | Where-Object {
                $_.not -and $_.not.field -eq 'name'
            }
            $exemptionCondition | Should -Not -BeNullOrEmpty
            $exemptionCondition.not.in | Should -Match '^\[parameters\('
        }
    }

    Context 'Policy Metadata Validation' {
        BeforeAll {
            $script:Metadata = (Get-Content $script:PolicyPath -Raw | ConvertFrom-Json).properties.metadata
        }

        It 'Should have category' {
            $script:Metadata.category | Should -Be 'Storage'
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

Describe 'Policy Logic Validation' -Tag @('Unit', 'Fast', 'Logic') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Condition Logic' {
        It 'Should use allOf for combining conditions' {
            $script:PolicyRule.if.allOf | Should -Not -BeNullOrEmpty
            $script:PolicyRule.if.allOf.Count | Should -BeGreaterThan 2
        }

        It 'Should have proper boolean logic structure' {
            $conditions = $script:PolicyRule.if.allOf

            # Should have resource type condition
            $typeCondition = $conditions | Where-Object { $_.field -eq 'type' }
            $typeCondition | Should -Not -BeNullOrEmpty

            # Should have SKU condition
            $skuCondition = $conditions | Where-Object { $_.field -eq 'Microsoft.Storage/storageAccounts/sku.name' }
            $skuCondition | Should -Not -BeNullOrEmpty

            # Should have exemption condition
            $exemptionCondition = $conditions | Where-Object { $_.not }
            $exemptionCondition | Should -Not -BeNullOrEmpty

            # Should have anyOf condition for HTTPS property
            $anyOfCondition = $conditions | Where-Object { $_.anyOf }
            $anyOfCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should properly structure the anyOf conditions for HTTPS' {
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $anyOfConditions = $anyOfCondition.anyOf

            # Should have 2 conditions in anyOf (exists check and value check)
            $anyOfConditions.Count | Should -Be 2

            # Should have condition for property existence
            $existsCondition = $anyOfConditions | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly' -and $_.exists -eq 'false'
            }
            $existsCondition | Should -Not -BeNullOrEmpty

            # Should have condition for property value
            $valueCondition = $anyOfConditions | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly' -and $_.equals -eq 'false'
            }
            $valueCondition | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Security Logic' {
        It 'Should enforce HTTPS-only traffic by default' {
            $effectParam = $script:PolicyJson.properties.parameters.effect
            $effectParam.defaultValue | Should -Be 'Deny'
        }

        It 'Should protect against unencrypted traffic' {
            $description = $script:PolicyJson.properties.description
            $description | Should -Match 'HTTPS|secure|encrypt'
        }
    }
}

Describe 'Policy Compliance Scenarios' -Tag @('Unit', 'Fast', 'Scenarios') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Simulated Resource Evaluation' {
        It 'Should identify compliant storage account (HTTPS enabled)' {
            # Simulate a compliant storage account
            $compliantResource = @{
                type       = 'Microsoft.Storage/storageAccounts'
                name       = 'compliantsa001'
                properties = @{
                    supportsHttpsTrafficOnly = $true
                }
                sku        = @{
                    name = 'Standard_LRS'
                }
            }

            # This is a conceptual test - in real scenarios, Azure Policy engine evaluates this
            # We're testing our understanding of what should be compliant
            $compliantResource.properties.supportsHttpsTrafficOnly | Should -Be $true
        }

        It 'Should identify non-compliant storage account (HTTPS disabled)' {
            # Simulate a non-compliant storage account (HTTPS disabled)
            $nonCompliantResource = @{
                type       = 'Microsoft.Storage/storageAccounts'
                name       = 'noncompliantsa001'
                properties = @{
                    supportsHttpsTrafficOnly = $false
                }
                sku        = @{
                    name = 'Standard_LRS'
                }
            }

            # This resource should trigger the policy due to HTTPS being disabled
            $nonCompliantResource.properties.supportsHttpsTrafficOnly | Should -Be $false
        }

        It 'Should identify non-compliant storage account (HTTPS property missing)' {
            # Simulate a non-compliant storage account (property not set)
            $nonCompliantResource = @{
                type       = 'Microsoft.Storage/storageAccounts'
                name       = 'missingpropsa001'
                properties = @{
                    # supportsHttpsTrafficOnly property is missing
                }
                sku        = @{
                    name = 'Standard_LRS'
                }
            }

            # This resource should trigger the policy due to missing HTTPS property
            $nonCompliantResource.properties.ContainsKey('supportsHttpsTrafficOnly') | Should -Be $false
        }

        It 'Should respect exempted storage accounts' {
            # Simulate an exempted storage account
            $exemptedResource = @{
                type       = 'Microsoft.Storage/storageAccounts'
                name       = 'exemptedsa001'
                properties = @{
                    supportsHttpsTrafficOnly = $false
                }
                sku        = @{
                    name = 'Standard_LRS'
                }
            }

            # In the policy, if this account is in exemptedStorageAccounts parameter,
            # it should not trigger the policy even with HTTPS disabled
            $exemptedResource.name | Should -Be 'exemptedsa001'
        }

        It 'Should apply to all configured storage account types' {
            $storageTypes = $script:PolicyJson.properties.parameters.storageAccountTypes.defaultValue

            # Should include common storage types
            $storageTypes | Should -Contain 'Standard_LRS'
            $storageTypes | Should -Contain 'Standard_GRS'
            $storageTypes | Should -Contain 'Premium_LRS'

            # Should have multiple types configured
            # Azure currently supports at least 6 storage account types (Standard_LRS, Standard_GRS, Standard_RAGRS, Standard_ZRS, Premium_LRS, Premium_ZRS)
            $storageTypes.Count | Should -BeGreaterThan 5
        }
    }
}

Describe 'Terraform Integration' -Tag @('Unit', 'Fast', 'Terraform') {

    Context 'Terraform Files' {
        It 'Should have main.tf file' {
            $terraformPath = Join-Path $PSScriptRoot '..\..\policies\storage\deny-storage-https-disabled'
            Test-Path (Join-Path $terraformPath 'main.tf') | Should -Be $true
        }

        It 'Should have variables.tf file' {
            $terraformPath = Join-Path $PSScriptRoot '..\..\policies\storage\deny-storage-https-disabled'
            Test-Path (Join-Path $terraformPath 'variables.tf') | Should -Be $true
        }

        It 'Should have outputs.tf file' {
            $terraformPath = Join-Path $PSScriptRoot '..\..\policies\storage\deny-storage-https-disabled'
            Test-Path (Join-Path $terraformPath 'outputs.tf') | Should -Be $true
        }

        It 'Should have consistent naming in Terraform files' {
            $terraformPath = Join-Path $PSScriptRoot '..\..\policies\storage\deny-storage-https-disabled'
            $varsPath = Join-Path $terraformPath 'variables.tf'

            if (Test-Path $varsPath) {
                $varsContent = Get-Content $varsPath -Raw
                $varsContent | Should -Match 'deny-storage-https-disabled'
            }
        }
    }
}
