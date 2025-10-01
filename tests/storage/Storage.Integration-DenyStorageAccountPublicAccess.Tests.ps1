#Requires -Modules Pester, Az.Accounts, Az.Resources, Az.Storage, Az.PolicyInsights

<#
.SYNOPSIS
    Pester tests for the Deny Storage Account Public Access policy
.DESCRIPTION
    This test suite validates the Azure Policy definition and tests actual compliance
    behavior for storage accounts with public access configurations.
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
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access'

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
    $script:TestStorageAccountPrefix = $script:TestConfig.Policy.ResourcePrefix

    # Set Azure context variables
    $script:Context = $envInit.Context
    $script:SubscriptionId = $envInit.SubscriptionId
    $script:ResourceGroup = $envInit.ResourceGroup

    Write-Host "Running tests in subscription: $($script:Context.Subscription.Name) ($script:SubscriptionId)" -ForegroundColor Green

    # Load policy definition from file using centralized path resolution
    $policyPath = Get-PolicyDefinitionPath -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access' -TestScriptPath $PSScriptRoot
    if (Test-Path $policyPath) {
        $script:PolicyDefinitionJson = Get-Content $policyPath -Raw | ConvertFrom-Json
    }
    else {
        throw "Policy definition file not found at: $policyPath"
    }
}

Describe 'Policy Definition Validation' -Tag @('Unit', 'Fast', 'PolicyDefinition') {
    Context 'Policy JSON Structure' {
        It 'Should have valid policy definition structure' {
            $script:PolicyDefinitionJson | Should -Not -BeNullOrEmpty
            $script:PolicyDefinitionJson.properties | Should -Not -BeNullOrEmpty
        }

        It 'Should have correct display name' {
            $script:PolicyDefinitionJson.properties.displayName | Should -Be $script:PolicyDisplayName
        }

        It 'Should have description' {
            $script:PolicyDefinitionJson.properties.description | Should -Not -BeNullOrEmpty
        }

        It 'Should target Microsoft.Storage/storageAccounts resource type' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $policyRule.if.allOf[0].field | Should -Be 'type'
            $policyRule.if.allOf[0].equals | Should -Be 'Microsoft.Storage/storageAccounts'
        }

        It 'Should have parameterized effect' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $policyRule.then.effect | Should -Be "[parameters('effect')]"
        }

        It 'Should check allowBlobPublicAccess property' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf
            # The policy uses anyOf structure, so we need to check within that
            $anyOfConditions = $conditions | Where-Object { $_.anyOf -ne $null }
            $anyOfConditions | Should -Not -BeNullOrEmpty
            $blobCondition = $anyOfConditions.anyOf | Where-Object { $_.field -eq 'Microsoft.Storage/storageAccounts/allowBlobPublicAccess' }
            $blobCondition | Should -Not -BeNullOrEmpty
            $blobCondition.equals | Should -Be 'true'
        }

        It 'Should check publicNetworkAccess property' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf
            # The policy uses anyOf structure, so we need to check within that
            $anyOfConditions = $conditions | Where-Object { $_.anyOf -ne $null }
            $anyOfConditions | Should -Not -BeNullOrEmpty
            $networkCondition = $anyOfConditions.anyOf | Where-Object { $_.field -eq 'Microsoft.Storage/storageAccounts/publicNetworkAccess' }
            $networkCondition | Should -Not -BeNullOrEmpty
            $networkCondition.equals | Should -Be 'Enabled'
        }
    }
}

Describe 'Policy Assignment Validation' -Tag @('Integration', 'Fast', 'PolicyAssignment') {
    Context 'Policy Assignment Exists' {
        BeforeAll {
            $script:PolicyAssignments = Get-AzPolicyAssignment -Scope $script:ResourceGroup.ResourceId
            # Look for the policy assignment by checking the policy definition name in the PolicyDefinitionId
            $script:TargetAssignment = $script:PolicyAssignments | Where-Object {
                $_.DisplayName -like "*$script:PolicyDisplayName*" -or
                $_.Name -like "*$script:PolicyName*" -or
                $_.PolicyDefinitionId -like "*$script:PolicyName*"
            }
        }

        It 'Should have policy assigned to resource group' {
            $script:TargetAssignment | Should -Not -BeNullOrEmpty -Because "Policy '$script:PolicyName' should be assigned to resource group '$script:ResourceGroupName'"
        }

        It 'Should be assigned at resource group scope' {
            if ($script:TargetAssignment) {
                $script:TargetAssignment.Scope | Should -Be $script:ResourceGroup.ResourceId
            }
        }

        It 'Should have policy definition associated' {
            if ($script:TargetAssignment) {
                $script:TargetAssignment.PolicyDefinitionId | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'Policy Compliance Testing' -Tag @('Integration', 'Slow', 'Compliance', 'RequiresCleanup') {
    Context 'Storage Account Compliance Scenarios' {
        BeforeAll {
            # Generate unique storage account names using centralized configuration
            $script:CompliantStorageName = New-PolicyTestResourceName -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access' -ResourceType 'compliant'  # pragma: allowlist secret
            $script:NonCompliantStorageName = New-PolicyTestResourceName -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access' -ResourceType 'nonCompliant'  # pragma: allowlist secret

            Write-Host "Test storage accounts: $script:CompliantStorageName, $script:NonCompliantStorageName" -ForegroundColor Yellow
        }

        It 'Should create compliant storage account (public access disabled)' {
            # Check if storage account already exists
            $existingStorage = Get-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                -Name $script:CompliantStorageName `
                -ErrorAction SilentlyContinue

            if ($existingStorage) {
                Write-Host "Storage account $script:CompliantStorageName already exists, using existing account" -ForegroundColor Yellow
                $script:CompliantStorage = $existingStorage
            }
            else {
                # Create storage account with public access disabled
                try {
                    $script:CompliantStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                        -Name $script:CompliantStorageName `
                        -Location $script:ResourceGroup.Location `
                        -SkuName $script:TestConfig.Policy.TestConfig.storageAccountSku `
                        -AllowBlobPublicAccess $false `
                        -PublicNetworkAccess 'Disabled' `
                        -ErrorAction Stop
                }
                catch {
                    Write-Host "Error creating storage account: $($_.Exception.Message)" -ForegroundColor Red
                    throw
                }
            }

            # Note: Using ($null -ne $variable) | Should -BeTrue instead of $variable | Should -Not -BeNull
            # due to Pester 5.7.1 bug where Should -Not -BeNull fails with PSStorageAccount objects
            ($null -ne $script:CompliantStorage) | Should -BeTrue
            $script:CompliantStorage.StorageAccountName | Should -Be $script:CompliantStorageName
        }

        It 'Should create non-compliant storage account (public access enabled)' {
            # Check if storage account already exists
            $existingStorage = Get-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                -Name $script:NonCompliantStorageName `
                -ErrorAction SilentlyContinue

            if ($existingStorage) {
                Write-Host "Storage account $script:NonCompliantStorageName already exists, using existing account" -ForegroundColor Yellow
                $script:NonCompliantStorage = $existingStorage
            }
            else {
                # Create storage account with public access enabled (violates policy)
                # Note: This may be blocked by policy if effect is set to 'Deny'
                try {
                    $script:NonCompliantStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                        -Name $script:NonCompliantStorageName `
                        -Location $script:ResourceGroup.Location `
                        -SkuName $script:TestConfig.Policy.TestConfig.storageAccountSku `
                        -AllowBlobPublicAccess $true `
                        -PublicNetworkAccess 'Enabled' `
                        -ErrorAction Stop
                }
                catch {
                    if ($_.Exception.Message -match 'RequestDisallowedByPolicy|disallowed by policy') {
                        Write-Host "Storage account creation blocked by policy (expected behavior for Deny effect)" -ForegroundColor Yellow
                        Set-ItResult -Skipped -Because "Policy with Deny effect prevents creation of non-compliant resources"
                        return
                    }
                    Write-Host "Error creating storage account: $($_.Exception.Message)" -ForegroundColor Red
                    throw
                }
            }

            # Note: Using ($null -ne $variable) | Should -BeTrue instead of $variable | Should -Not -BeNull
            # due to Pester 5.7.1 bug where Should -Not -BeNull fails with PSStorageAccount objects
            ($null -ne $script:NonCompliantStorage) | Should -BeTrue
            $script:NonCompliantStorage.StorageAccountName | Should -Be $script:NonCompliantStorageName
        }

        It 'Should wait for policy evaluation to complete' {
            # Wait for Azure Policy to evaluate the resources using centralized timeout
            $waitTime = $script:TestConfig.Timeouts.PolicyEvaluationWaitSeconds
            Write-Host "Waiting $waitTime seconds for policy evaluation..." -ForegroundColor Yellow
            Start-Sleep -Seconds $waitTime
        }
    }

    Context 'Policy Compliance Results' {
        BeforeAll {
            # Trigger policy compliance scan
            try {
                Start-AzPolicyComplianceScan -ResourceGroupName $script:ResourceGroupName -AsJob | Out-Null
                $complianceScanWait = $script:TestConfig.Timeouts.ComplianceScanWaitSeconds
                Start-Sleep -Seconds $complianceScanWait
            }
            catch {
                Write-Warning "Could not trigger compliance scan: $($_.Exception.Message)"
            }

            # Get compliance states
            $script:ComplianceStates = Get-AzPolicyState -ResourceGroupName $script:ResourceGroupName
        }

        It 'Should have compliance data available' {
            $script:ComplianceStates | Should -Not -BeNullOrEmpty
        }

        It 'Should show compliant storage account as compliant' -Skip:($null -eq $script:CompliantStorage) {
            $compliantState = $script:ComplianceStates | Where-Object {
                $_.ResourceId -like "*$script:CompliantStorageName*" -and
                $_.PolicyDefinitionAction -eq 'audit'
            }

            if ($compliantState) {
                $compliantState.ComplianceState | Should -Be 'Compliant'
            }
            else {
                Write-Warning 'Compliance state not yet available for compliant storage account'
            }
        }

        It 'Should show non-compliant storage account as non-compliant' -Skip:($null -eq $script:NonCompliantStorage) {
            $nonCompliantState = $script:ComplianceStates | Where-Object {
                $_.ResourceId -like "*$script:NonCompliantStorageName*" -and
                $_.PolicyDefinitionAction -eq 'audit'
            }

            if ($nonCompliantState) {
                $nonCompliantState.ComplianceState | Should -Be 'NonCompliant'
            }
            else {
                Write-Warning 'Compliance state not yet available for non-compliant storage account'
            }
        }
    }

    Context 'Policy Evaluation Details' {
        It 'Should provide detailed compliance information' {
            $policyStates = Get-AzPolicyState -ResourceGroupName $script:ResourceGroupName -Filter "PolicyDefinitionAction eq 'audit'"

            foreach ($state in $policyStates) {
                Write-Host "Resource: $($state.ResourceId)" -ForegroundColor Cyan
                Write-Host "  Compliance: $($state.ComplianceState)" -ForegroundColor $(if ($state.ComplianceState -eq 'Compliant') { 'Green' } else { 'Red' })
                Write-Host "  Policy: $($state.PolicyDefinitionName)" -ForegroundColor Gray
                Write-Host "  Timestamp: $($state.Timestamp)" -ForegroundColor Gray
                Write-Host ''
            }

            # This test always passes as it's informational
            $true | Should -Be $true
        }
    }
}

Describe 'Policy Remediation Testing' -Tag @('Integration', 'Slow', 'Remediation', 'RequiresCleanup') {
    Context 'Storage Account Configuration Changes' {
        It 'Should be able to remediate non-compliant storage account' -Skip:($null -eq $script:NonCompliantStorage) {
            # Update the non-compliant storage account to be compliant
            $updatedStorage = Set-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                -Name $script:NonCompliantStorageName `
                -AllowBlobPublicAccess $false `
                -PublicNetworkAccess 'Disabled' `
                -ErrorAction SilentlyContinue

            $updatedStorage | Should -Not -BeNullOrEmpty
            $updatedStorage.AllowBlobPublicAccess | Should -Be $false
            $updatedStorage.PublicNetworkAccess | Should -Be 'Disabled'
        }

        It 'Should wait for policy re-evaluation after remediation' {
            $reEvalWait = $script:TestConfig.Timeouts.RemediationWaitSeconds
            Write-Host "Waiting $reEvalWait seconds for policy re-evaluation..." -ForegroundColor Yellow
            Start-Sleep -Seconds $reEvalWait
        }
    }
}

AfterAll {
    # Cleanup test resources
    Write-Host 'Cleaning up test storage accounts...' -ForegroundColor Yellow

    if ($script:CompliantStorage) {
        try {
            Remove-AzStorageAccount -ResourceGroupName $script:ResourceGroupName -Name $script:CompliantStorageName -Force -ErrorAction SilentlyContinue
            Write-Host "Removed compliant test storage account: $script:CompliantStorageName" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not remove compliant storage account: $($_.Exception.Message)"
        }
    }

    if ($script:NonCompliantStorage) {
        try {
            Remove-AzStorageAccount -ResourceGroupName $script:ResourceGroupName -Name $script:NonCompliantStorageName -Force -ErrorAction SilentlyContinue
            Write-Host "Removed non-compliant test storage account: $script:NonCompliantStorageName" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not remove non-compliant storage account: $($_.Exception.Message)"
        }
    }

    Write-Host 'Test cleanup completed.' -ForegroundColor Green
}
