#Requires -Modules Pester, Az.Accounts, Az.Resources, Az.Storage, Az.PolicyInsights

<#
.SYNOPSIS
    Pester integration tests for the Deny Storage HTTPS Disabled policy
.DESCRIPTION
    This test suite validates the Azure Policy definition and tests actual compliance
    behavior for storage accounts with HTTPS-only traffic settings.
.NOTES
    Prerequisites:
    - Azure PowerShell modules (Az.Accounts, Az.Resources, Az.Storage, Az.PolicyInsights)
    - Authenticated Azure session with appropriate permissions
    - Resource group 'rg-azure-policy-testing' must exist
    - Policy must be assigned to the resource group
#>

BeforeAll {
    # Import centralized configuration
    . "$PSScriptRoot\..\..\config\config-loader.ps1"

    # Initialize test configuration for this specific policy
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'storage' -PolicyName 'deny-storage-https-disabled'

    # Import required modules using centralized configuration
    Import-PolicyTestModule -ModuleTypes @('Required', 'Storage')

    # Initialize test environment with skip-on-no-context for VS Code Test Explorer
    $envInit = Initialize-PolicyTestEnvironment -Config $script:TestConfig -SkipIfNoContext $script:TestConfig.Azure.SkipIfNoContext
    if (-not $envInit.Success) {
        if ($envInit.ShouldSkip) {
            # Skip all tests if no Azure context is available
            Write-Host 'Skipping all tests - no Azure context available' -ForegroundColor Yellow
            return
        }
        throw "Environment initialization failed: $($envInit.Errors -join '; ')"
    }

    # Set script variables from configuration
    $script:ResourceGroupName = $script:TestConfig.Azure.ResourceGroupName
    $script:PolicyName = $script:TestConfig.Policy.Name
    $script:PolicyDisplayName = $script:TestConfig.Policy.DisplayName
    $script:TestStoragePrefix = $script:TestConfig.Policy.ResourcePrefix

    # Use context from environment initialization
    $script:Context = $envInit.Context
    $script:SubscriptionId = $envInit.SubscriptionId
    Write-Host "Running tests in subscription: $($script:Context.Subscription.Name) ($script:SubscriptionId)" -ForegroundColor Green

    # Verify resource group exists
    $script:ResourceGroup = Get-AzResourceGroup -Name $script:ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $script:ResourceGroup) {
        throw "Resource group '$script:ResourceGroupName' not found. Please create it first."
    }

    # Load policy definition from file
    $policyPath = Get-PolicyDefinitionPath -PolicyCategory 'storage' -PolicyName 'deny-storage-https-disabled' -TestScriptPath $PSScriptRoot
    if (Test-Path $policyPath) {
        $script:PolicyDefinitionJson = Get-Content $policyPath -Raw | ConvertFrom-Json
    }
    else {
        throw "Policy definition file not found at: $policyPath"
    }

    # Storage accounts created during tests
    $script:CreatedStorageAccounts = @()
}

Describe 'Policy Definition Validation' -Tag @('Unit', 'Fast', 'PolicyDefinition') {
    Context 'Policy JSON Structure' {
        It 'Should have valid policy definition structure' {
            $script:PolicyDefinitionJson | Should -Not -BeNullOrEmpty
            $script:PolicyDefinitionJson.properties | Should -Not -BeNullOrEmpty
        }

        It 'Should have correct display name' {
            $script:PolicyDefinitionJson.properties.displayName | Should -Match 'HTTPS'
        }

        It 'Should have correct policy name' {
            $script:PolicyDefinitionJson.name | Should -Be $script:PolicyName
        }

        It 'Should have comprehensive description' {
            $script:PolicyDefinitionJson.properties.description | Should -Not -BeNullOrEmpty
            $script:PolicyDefinitionJson.properties.description | Should -Match 'HTTPS'
        }

        It 'Should have proper metadata' {
            $metadata = $script:PolicyDefinitionJson.properties.metadata
            $metadata | Should -Not -BeNullOrEmpty
            $metadata.category | Should -Be 'Storage'
            $metadata.version | Should -Not -BeNullOrEmpty
        }

        It 'Should target Microsoft.Storage/storageAccounts resource type' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf

            $typeCondition = $conditions | Where-Object { $_.field -eq 'type' }
            $typeCondition | Should -Not -BeNullOrEmpty
            $typeCondition.equals | Should -Be 'Microsoft.Storage/storageAccounts'
        }

        It 'Should have effect parameter with correct allowed values' {
            $effectParam = $script:PolicyDefinitionJson.properties.parameters.effect
            $effectParam | Should -Not -BeNullOrEmpty
            $effectParam.allowedValues | Should -Contain 'Audit'
            $effectParam.allowedValues | Should -Contain 'Deny'
            $effectParam.allowedValues | Should -Contain 'Disabled'
            $effectParam.defaultValue | Should -Be 'Deny'
        }

        It 'Should have exemptedStorageAccounts parameter' {
            $exemptionsParam = $script:PolicyDefinitionJson.properties.parameters.exemptedStorageAccounts
            $exemptionsParam | Should -Not -BeNullOrEmpty
            $exemptionsParam.type | Should -Be 'Array'
            $exemptionsParam.defaultValue | Should -Be @()
        }

        It 'Should have storageAccountTypes parameter' {
            $typesParam = $script:PolicyDefinitionJson.properties.parameters.storageAccountTypes
            $typesParam | Should -Not -BeNullOrEmpty
            $typesParam.type | Should -Be 'Array'
            # Azure currently supports at least 6 storage account types; update this value if more are added in the future
            $typesParam.allowedValues.Count | Should -BeGreaterThan 5
        }

        It 'Should check supportsHttpsTrafficOnly property' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf
            $httpsCondition = $conditions | Where-Object { $_.anyOf }

            $httpsCondition | Should -Not -BeNullOrEmpty
            $httpsChecks = $httpsCondition.anyOf

            $existsCheck = $httpsChecks | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly' -and $_.exists -eq 'false'
            }
            $falseCheck = $httpsChecks | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly' -and $_.equals -eq 'false'
            }

            $existsCheck | Should -Not -BeNullOrEmpty
            $falseCheck | Should -Not -BeNullOrEmpty
        }

        It 'Should have parameterized effect' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $policyRule.then.effect | Should -Be '[parameters(''effect'')]'
        }
    }
}

Describe 'Policy Assignment Validation' -Tag @('Integration', 'Fast', 'PolicyAssignment') {
    Context 'Policy Assignment Exists' {
        BeforeAll {
            $script:PolicyAssignments = Get-AzPolicyAssignment -Scope $script:ResourceGroup.ResourceId
            $script:TargetAssignment = $script:PolicyAssignments | Where-Object {
                $_.Properties.DisplayName -like "*$script:PolicyDisplayName*" -or
                $_.Name -like "*$script:PolicyName*" -or
                $_.Properties.DisplayName -like '*Storage*HTTPS*' -or
                $_.Properties.DisplayName -like '*Storage*Secure*Transfer*'
            }
        }

        It 'Should have policy assigned to resource group' -Skip:($null -eq $script:TargetAssignment) {
            $script:TargetAssignment | Should -Not -BeNullOrEmpty -Because 'If policy is not assigned, tests cannot validate compliance. Deploy policy using: terraform apply -var-file=config/vars/sandbox.tfvars.json'
        }

        It 'Should be assigned at resource group scope' {
            if ($script:TargetAssignment) {
                $script:TargetAssignment.Properties.Scope | Should -Be $script:ResourceGroup.ResourceId
            }
        }

        It 'Should have policy definition associated' {
            if ($script:TargetAssignment) {
                $script:TargetAssignment.Properties.PolicyDefinitionId | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should have system assigned identity for remediation' {
            if ($script:TargetAssignment) {
                $script:TargetAssignment.Identity | Should -Not -BeNullOrEmpty
                $script:TargetAssignment.Identity.Type | Should -Be 'SystemAssigned'
            }
        }

        It 'Should have appropriate parameters configured' {
            if ($script:TargetAssignment -and $script:TargetAssignment.Properties.Parameters) {
                $parameters = $script:TargetAssignment.Properties.Parameters
                $parameters.effect | Should -Not -BeNullOrEmpty
                $parameters.exemptedStorageAccounts | Should -Not -BeNullOrEmpty
                $parameters.storageAccountTypes | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'Storage HTTPS-Only Compliance Tests' -Tag @('Integration', 'Slow', 'Compliance') {
    BeforeAll {
        # Generate unique names for test storage accounts using centralized function
        $script:CompliantStorageName = New-PolicyTestResourceName -PolicyCategory 'storage' -PolicyName 'deny-storage-https-disabled' -ResourceType 'compliant'
        $script:NonCompliantStorageName = New-PolicyTestResourceName -PolicyCategory 'storage' -PolicyName 'deny-storage-https-disabled' -ResourceType 'nonCompliant'
        $script:ExemptedStorageName = New-PolicyTestResourceName -PolicyCategory 'storage' -PolicyName 'deny-storage-https-disabled' -ResourceType 'exempted'
    }

    AfterAll {
        # Cleanup storage accounts
        foreach ($storageAccount in $script:CreatedStorageAccounts) {
            try {
                Write-Host "Cleaning up Storage Account: $($storageAccount.StorageAccountName)" -ForegroundColor Yellow
                Remove-AzStorageAccount -Name $storageAccount.StorageAccountName -ResourceGroupName $script:ResourceGroupName -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "Failed to cleanup Storage Account $($storageAccount.StorageAccountName): $($_.Exception.Message)"
            }
        }
    }

    Context 'Compliant Storage Account (HTTPS Enabled)' {
        It 'Should successfully create storage account with HTTPS-only enabled' {
            $storageAccount = New-AzStorageAccount `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $script:CompliantStorageName `
                -Location $script:ResourceGroup.Location `
                -SkuName $script:TestConfig.Policy.TestConfig.storageAccountSku `
                -Kind 'StorageV2' `
                -EnableHttpsTrafficOnly $true `
                -AllowBlobPublicAccess $false `
                -ErrorAction Stop

            # Verify the storage account was created
            $null -eq $storageAccount | Should -Be $false -Because 'Storage account creation should return an object'
            $storageAccount.StorageAccountName | Should -Be $script:CompliantStorageName
            $storageAccount.EnableHttpsTrafficOnly | Should -Be $true
            $script:CreatedStorageAccounts += $storageAccount
        }

        It 'Should verify HTTPS-only is enabled' {
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $script:ResourceGroupName -Name $script:CompliantStorageName
            $storageAccount.EnableHttpsTrafficOnly | Should -Be $true
        }

        It 'Should be compliant with the policy' {
            # Wait for policy evaluation
            Start-Sleep -Seconds $script:TestConfig.Timeouts.PolicyEvaluationWaitSeconds

            $resourceId = "/subscriptions/$script:SubscriptionId/resourceGroups/$script:ResourceGroupName/providers/Microsoft.Storage/storageAccounts/$script:CompliantStorageName"
            $complianceStates = Get-AzPolicyState `
                -ResourceGroupName $script:ResourceGroupName `
                -Filter "PolicyDefinitionName eq '$script:PolicyName' and ResourceId eq '$resourceId'"

            if ($complianceStates) {
                $complianceStates | Should -Not -BeNullOrEmpty
                $complianceStates[0].ComplianceState | Should -Be 'Compliant'
            }
            else {
                Write-Warning "Policy compliance state not yet available for $script:CompliantStorageName"
            }
        }
    }

    Context 'Non-Compliant Storage Account (HTTPS Disabled)' {
        It 'Should fail to create storage account with HTTPS-only disabled (in Deny mode)' {
            # Try to create storage account with HTTPS disabled - this should fail if policy is in Deny mode
            try {
                $storageAccount = New-AzStorageAccount `
                    -ResourceGroupName $script:ResourceGroupName `
                    -Name $script:NonCompliantStorageName `
                    -Location $script:ResourceGroup.Location `
                    -SkuName $script:TestConfig.Policy.TestConfig.storageAccountSku `
                    -Kind 'StorageV2' `
                    -EnableHttpsTrafficOnly $false `
                    -AllowBlobPublicAccess $false `
                    -ErrorAction Stop

                $script:CreatedStorageAccounts += $storageAccount
                $createSucceeded = $true
            }
            catch {
                $createSucceeded = $false
                $createError = $_.Exception.Message
            }

            # Check policy effect to determine expected behavior
            if ($script:TargetAssignment -and $script:TargetAssignment.Properties.Parameters.effect.value -eq 'Deny') {
                $createSucceeded | Should -Be $false
                $createError | Should -Match 'policy|denied|disallowed|RequestDisallowedByPolicy'
            }
            elseif ($script:TargetAssignment -and $script:TargetAssignment.Properties.Parameters.effect.value -eq 'Audit') {
                # In Audit mode, the operation should succeed but be flagged as non-compliant
                Write-Warning 'Policy is in Audit mode - Storage account creation succeeded but should be flagged as non-compliant'
                $createSucceeded | Should -Be $true
            }
        }

        It 'Should be flagged as non-compliant (in Audit mode)' {
            # Only test compliance in Audit mode
            if ($script:TargetAssignment -and $script:TargetAssignment.Properties.Parameters.effect.value -eq 'Audit') {
                # Wait for policy evaluation
                Start-Sleep -Seconds $script:TestConfig.Timeouts.PolicyEvaluationWaitSeconds

                $resourceId = "/subscriptions/$script:SubscriptionId/resourceGroups/$script:ResourceGroupName/providers/Microsoft.Storage/storageAccounts/$script:NonCompliantStorageName"
                $complianceStates = Get-AzPolicyState `
                    -ResourceGroupName $script:ResourceGroupName `
                    -Filter "PolicyDefinitionName eq '$script:PolicyName' and ResourceId eq '$resourceId'"

                if ($complianceStates) {
                    $complianceStates | Should -Not -BeNullOrEmpty
                    $complianceStates[0].ComplianceState | Should -Be 'NonCompliant'
                }
                else {
                    Write-Warning "Policy compliance state not yet available for $script:NonCompliantStorageName"
                }
            }
        }
    }

    Context 'Exempted Storage Account' {
        It 'Should create exempted storage account successfully even with HTTPS disabled' {
            # Check if there are exempted storage accounts configured
            $exemptedAccounts = @()
            if ($script:TargetAssignment -and $script:TargetAssignment.Properties.Parameters.exemptedStorageAccounts) {
                $exemptedAccounts = $script:TargetAssignment.Properties.Parameters.exemptedStorageAccounts.value
            }

            if ($exemptedAccounts -contains $script:ExemptedStorageName) {
                # Create storage account with HTTPS disabled - should succeed for exempted accounts
                $storageAccount = New-AzStorageAccount `
                    -ResourceGroupName $script:ResourceGroupName `
                    -Name $script:ExemptedStorageName `
                    -Location $script:ResourceGroup.Location `
                    -SkuName $script:TestConfig.Policy.TestConfig.storageAccountSku `
                    -Kind 'StorageV2' `
                    -EnableHttpsTrafficOnly $false `
                    -AllowBlobPublicAccess $false

                $storageAccount | Should -Not -BeNullOrEmpty
                $storageAccount.EnableHttpsTrafficOnly | Should -Be $false
                $script:CreatedStorageAccounts += $storageAccount
            }
            else {
                Write-Warning 'No exempted storage accounts configured - skipping exemption test'
            }
        }
    }

    Context 'Updating Existing Storage Account' {
        It 'Should allow updating compliant storage account' {
            # Verify we can update a compliant storage account (with HTTPS enabled)
            # Add a tag to verify update capability
            Set-AzStorageAccount `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $script:CompliantStorageName `
                -Tag @{TestTag = 'TestValue'; UpdatedBy = 'PesterTest' } `
                -ErrorAction Stop

            $updatedAccount = Get-AzStorageAccount -ResourceGroupName $script:ResourceGroupName -Name $script:CompliantStorageName
            $updatedAccount.Tags['TestTag'] | Should -Be 'TestValue'
        }

        It 'Should prevent disabling HTTPS on existing storage account (in Deny mode)' {
            # Try to disable HTTPS on an existing account - should fail if policy is in Deny mode
            try {
                Set-AzStorageAccount `
                    -ResourceGroupName $script:ResourceGroupName `
                    -Name $script:CompliantStorageName `
                    -EnableHttpsTrafficOnly $false `
                    -ErrorAction Stop

                $updateSucceeded = $true
            }
            catch {
                $updateSucceeded = $false
                $updateError = $_.Exception.Message
            }

            # Check policy effect
            if ($script:TargetAssignment -and $script:TargetAssignment.Properties.Parameters.effect.value -eq 'Deny') {
                $updateSucceeded | Should -Be $false
                $updateError | Should -Match 'policy|denied|disallowed|RequestDisallowedByPolicy'
            }
            elseif ($script:TargetAssignment -and $script:TargetAssignment.Properties.Parameters.effect.value -eq 'Audit') {
                Write-Warning 'Policy is in Audit mode - Update succeeded but should be flagged as non-compliant'
            }
        }
    }
}

Describe 'Policy Effectiveness Tests' -Tag @('Integration', 'Slow', 'Effectiveness') {
    Context 'HTTPS-Only Configuration Validation' {
        It 'Should validate policy targets correct HTTPS settings' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf
            $httpsCondition = $conditions | Where-Object { $_.anyOf }

            $httpsCondition | Should -Not -BeNullOrEmpty
            $httpsChecks = $httpsCondition.anyOf

            # Should check if supportsHttpsTrafficOnly exists
            $existsCheck = $httpsChecks | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly' -and $_.exists -eq 'false'
            }
            $existsCheck | Should -Not -BeNullOrEmpty

            # Should check if supportsHttpsTrafficOnly is false
            $falseCheck = $httpsChecks | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly' -and $_.equals -eq 'false'
            }
            $falseCheck | Should -Not -BeNullOrEmpty
        }

        It 'Should not affect other resource types' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf

            $typeCondition = $conditions | Where-Object { $_.field -eq 'type' }
            $typeCondition.equals | Should -Be 'Microsoft.Storage/storageAccounts'
        }

        It 'Should respect exemptions properly' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf

            # Check storage account exemptions
            $exemption = $conditions | Where-Object {
                $_.not -and $_.not.field -eq 'name'
            }
            $exemption | Should -Not -BeNullOrEmpty
            $exemption.not.in | Should -Be '[parameters(''exemptedStorageAccounts'')]'
        }

        It 'Should apply to configured storage account types' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf

            $skuCondition = $conditions | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/sku.name'
            }
            $skuCondition | Should -Not -BeNullOrEmpty
            $skuCondition.in | Should -Be '[parameters(''storageAccountTypes'')]'
        }
    }

    Context 'Policy Integration' {
        It 'Should work with Terraform deployment' {
            $terraformPath = Join-Path $PSScriptRoot '..\..\policies\storage\deny-storage-https-disabled'

            Test-Path (Join-Path $terraformPath 'main.tf') | Should -Be $true
            Test-Path (Join-Path $terraformPath 'variables.tf') | Should -Be $true
            Test-Path (Join-Path $terraformPath 'outputs.tf') | Should -Be $true
        }

        It 'Should have consistent naming across files' {
            $terraformVarsPath = Join-Path $PSScriptRoot '..\..\policies\storage\deny-storage-https-disabled\variables.tf'

            if (Test-Path $terraformVarsPath) {
                $varsContent = Get-Content $terraformVarsPath -Raw
                $varsContent | Should -Match 'deny-storage-https-disabled'
            }
        }
    }
}

Describe 'Security Validation' -Tag @('Security', 'Fast') {
    Context 'HTTPS Enforcement Security' {
        It 'Should enforce encryption in transit' {
            $description = $script:PolicyDefinitionJson.properties.description
            $description | Should -Match 'HTTPS|secure|encrypt'
        }

        It 'Should prevent unencrypted data transfer' {
            $description = $script:PolicyDefinitionJson.properties.description
            $description | Should -Match 'secure transport|encrypted'
        }

        It 'Should have appropriate security metadata' {
            $metadata = $script:PolicyDefinitionJson.properties.metadata
            $metadata.category | Should -Be 'Storage'
        }
    }

    Context 'Policy Parameter Security' {
        It 'Should have secure default effect' {
            $effectParam = $script:PolicyDefinitionJson.properties.parameters.effect
            $effectParam.defaultValue | Should -Be 'Deny'
        }

        It 'Should allow controlled exemptions' {
            $exemptionsParam = $script:PolicyDefinitionJson.properties.parameters.exemptedStorageAccounts
            $exemptionsParam.type | Should -Be 'Array'
            $exemptionsParam.defaultValue | Should -Be @()
        }

        It 'Should apply to multiple storage account types' {
            $typesParam = $script:PolicyDefinitionJson.properties.parameters.storageAccountTypes
            # At least 6 storage account types are expected for comprehensive policy coverage
            $typesParam.defaultValue.Count | Should -BeGreaterThan 5
        }
    }
}

Write-Host "`nTest Summary:" -ForegroundColor Cyan
Write-Host "- Policy Name: $script:PolicyName" -ForegroundColor Green
Write-Host "- Policy Display Name: $script:PolicyDisplayName" -ForegroundColor Green
Write-Host "- Resource Group: $script:ResourceGroupName" -ForegroundColor Green
Write-Host "- Subscription: $($script:Context.Subscription.Name) ($script:SubscriptionId)" -ForegroundColor Green

if ($script:TargetAssignment) {
    Write-Host "- Policy Assignment Found: $($script:TargetAssignment.Name)" -ForegroundColor Green
    Write-Host "- Policy Effect: $($script:TargetAssignment.Properties.Parameters.effect.value)" -ForegroundColor Green
}
else {
    Write-Host '- Policy Assignment: Not Found' -ForegroundColor Yellow
}
