#Requires -Modules Pester, Az.Accounts, Az.Resources, Az.Storage, Az.PolicyInsights

<#
.SYNOPSIS
    Integration tests for the Deny Storage SAS Expiration policy
.DESCRIPTION
    This test suite validates the Azure Policy definition and tests actual compliance
    behavior for storage accounts with SAS expiration configurations.
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
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'storage' -PolicyName 'deny-storage-sas-expiration'

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
    $script:PolicyName = 'deny-storage-sas-expiration'
    $script:PolicyDisplayName = 'Deny Storage Account SAS Token Expiration Greater Than Maximum'
    $script:TestStorageAccountPrefix = 'testsassa'

    # Set Azure context variables
    $script:Context = $envInit.Context
    $script:SubscriptionId = $envInit.SubscriptionId
    $script:ResourceGroup = $envInit.ResourceGroup

    Write-Host "Running tests in subscription: $($script:Context.Subscription.Name) ($script:SubscriptionId)" -ForegroundColor Green

    # Load policy definition from file using centralized path resolution
    $policyPath = Get-PolicyDefinitionPath -PolicyCategory 'storage' -PolicyName 'deny-storage-sas-expiration' -TestScriptPath $PSScriptRoot
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

        It 'Should have correct policy name' {
            $script:PolicyDefinitionJson.name | Should -Be $script:PolicyName
        }

        It 'Should have comprehensive description' {
            $script:PolicyDefinitionJson.properties.description | Should -Not -BeNullOrEmpty
            $script:PolicyDefinitionJson.properties.description | Should -Match 'SAS|Shared Access Signature'
        }

        It 'Should have proper metadata' {
            $metadata = $script:PolicyDefinitionJson.properties.metadata
            $metadata | Should -Not -BeNullOrEmpty
            $metadata.category | Should -Be 'Storage'
            $metadata.version | Should -Not -BeNullOrEmpty
        }

        It 'Should target Microsoft.Storage/storageAccounts resource type' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $typeCondition = $policyRule.if.allOf | Where-Object { $_.field -eq 'type' }
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

        It 'Should have maxSasExpirationDays parameter' {
            $maxDaysParam = $script:PolicyDefinitionJson.properties.parameters.maxSasExpirationDays
            $maxDaysParam | Should -Not -BeNullOrEmpty
            $maxDaysParam.type | Should -Be 'Integer'
            $maxDaysParam.defaultValue | Should -Be 90
        }

        It 'Should have exemptedStorageAccounts parameter' {
            $exemptionParam = $script:PolicyDefinitionJson.properties.parameters.exemptedStorageAccounts
            $exemptionParam | Should -Not -BeNullOrEmpty
            $exemptionParam.type | Should -Be 'Array'
        }
    }
}

Describe 'Policy Assignment Validation' -Tag @('Integration', 'Fast', 'PolicyAssignment') {
    Context 'Policy Assignment Exists' {
        BeforeAll {
            $script:PolicyAssignments = Get-AzPolicyAssignment -Scope $script:ResourceGroup.ResourceId -ErrorAction SilentlyContinue
            $script:TargetAssignment = $script:PolicyAssignments | Where-Object {
                $_.DisplayName -like "*$script:PolicyDisplayName*" -or
                $_.Name -like "*$script:PolicyName*" -or
                $_.PolicyDefinitionId -like "*$script:PolicyName*"
            }
        }

        It 'Should have policy assigned to resource group (or can skip if not deployed)' {
            if ($script:TargetAssignment) {
                $script:TargetAssignment | Should -Not -BeNullOrEmpty
                Write-Host "Policy assignment found: $($script:TargetAssignment.Name)" -ForegroundColor Green
            }
            else {
                Write-Host "Policy not yet assigned - skipping assignment tests" -ForegroundColor Yellow
                Set-ItResult -Skipped -Because "Policy not yet deployed/assigned"
            }
        }

        It 'Should be assigned at resource group scope' -Skip:($null -eq $script:TargetAssignment) {
            $script:TargetAssignment.Scope | Should -Be $script:ResourceGroup.ResourceId
        }

        It 'Should have policy definition associated' -Skip:($null -eq $script:TargetAssignment) {
            $script:TargetAssignment.PolicyDefinitionId | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Policy Compliance Testing' -Tag @('Integration', 'Slow', 'Compliance', 'RequiresCleanup') {
    Context 'Storage Account SAS Expiration Scenarios' {
        BeforeAll {
            # Generate unique storage account names (max 24 chars for storage accounts)
            $timestamp = Get-Date -Format 'HHmmss'
            $script:CompliantStorageName = "sascmpl$timestamp"  # 13 chars
            $script:NonCompliantStorageName = "sasnoncmpl$timestamp"  # 17 chars
            $script:NoSasPolicyStorageName = "sasnopol$timestamp"  # 15 chars

            Write-Host "Test storage accounts: $script:CompliantStorageName, $script:NonCompliantStorageName, $script:NoSasPolicyStorageName" -ForegroundColor Yellow

            # Test resources collection for cleanup
            $script:TestResources = @()
        }

        It 'Should create compliant storage account (SAS expiration 30 days)' {
            # Create storage account with SAS expiration set to 30 days (compliant with 90 day max)
            try {
                $script:CompliantStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                    -Name $script:CompliantStorageName `
                    -Location $script:ResourceGroup.Location `
                    -SkuName 'Standard_LRS' `
                    -SasExpirationPeriod '30.00:00:00' `
                    -ErrorAction Stop

                $script:TestResources += $script:CompliantStorageName
            }
            catch {
                Write-Host "Error creating compliant storage account: $($_.Exception.Message)" -ForegroundColor Red
                throw
            }

            ($null -ne $script:CompliantStorage) | Should -BeTrue
            $script:CompliantStorage.StorageAccountName | Should -Be $script:CompliantStorageName
            $script:CompliantStorage.SasPolicy | Should -Not -BeNullOrEmpty
            $script:CompliantStorage.SasPolicy.SasExpirationPeriod | Should -Be '30.00:00:00'
        }

        It 'Should create non-compliant storage account (SAS expiration 180 days)' {
            # Create storage account with SAS expiration set to 180 days (exceeds 90 day max)
            # This may be blocked if policy effect is 'Deny', or allowed if 'Audit'
            try {
                $script:NonCompliantStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                    -Name $script:NonCompliantStorageName `
                    -Location $script:ResourceGroup.Location `
                    -SkuName 'Standard_LRS' `
                    -SasExpirationPeriod '180.00:00:00' `
                    -ErrorAction Stop

                $script:TestResources += $script:NonCompliantStorageName
                Write-Host "Non-compliant storage account created (policy in Audit mode or not assigned)" -ForegroundColor Yellow
            }
            catch {
                if ($_.Exception.Message -match 'policy|denied|disallowed') {
                    Write-Host "Storage account creation blocked by policy (expected with Deny effect)" -ForegroundColor Green
                    Set-ItResult -Skipped -Because "Policy correctly denied non-compliant resource"
                }
                else {
                    Write-Host "Error creating non-compliant storage account: $($_.Exception.Message)" -ForegroundColor Red
                    throw
                }
            }

            if ($script:NonCompliantStorage) {
                ($null -ne $script:NonCompliantStorage) | Should -BeTrue
                $script:NonCompliantStorage.StorageAccountName | Should -Be $script:NonCompliantStorageName
                $script:NonCompliantStorage.SasPolicy.SasExpirationPeriod | Should -Be '180.00:00:00'
            }
        }

        It 'Should create storage account without SAS policy (non-compliant)' {
            # Create storage account without SAS expiration policy configured
            try {
                $script:NoSasPolicyStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                    -Name $script:NoSasPolicyStorageName `
                    -Location $script:ResourceGroup.Location `
                    -SkuName 'Standard_LRS' `
                    -ErrorAction Stop

                $script:TestResources += $script:NoSasPolicyStorageName
                Write-Host "Storage account without SAS policy created (policy in Audit mode or not assigned)" -ForegroundColor Yellow
            }
            catch {
                if ($_.Exception.Message -match 'policy|denied|disallowed') {
                    Write-Host "Storage account creation blocked by policy (expected with Deny effect)" -ForegroundColor Green
                    Set-ItResult -Skipped -Because "Policy correctly denied resource without SAS policy"
                }
                else {
                    Write-Host "Error creating storage account: $($_.Exception.Message)" -ForegroundColor Red
                    throw
                }
            }

            if ($script:NoSasPolicyStorage) {
                ($null -ne $script:NoSasPolicyStorage) | Should -BeTrue
                $script:NoSasPolicyStorage.StorageAccountName | Should -Be $script:NoSasPolicyStorageName
            }
        }

        It 'Should wait for policy evaluation to complete' {
            # Azure Policy evaluation can take several minutes
            Write-Host "Waiting 90 seconds for policy evaluation..." -ForegroundColor Yellow
            Start-Sleep -Seconds 90
            $true | Should -Be $true
        }
    }

    Context 'Policy Compliance Validation' -Skip:($script:TestResources.Count -eq 0) {
        BeforeAll {
            # Trigger policy compliance scan
            try {
                Write-Host "Triggering policy compliance scan..." -ForegroundColor Yellow
                Start-AzPolicyComplianceScan -ResourceGroupName $script:ResourceGroupName -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 30
            }
            catch {
                Write-Host "Could not trigger compliance scan: $($_.Exception.Message)" -ForegroundColor Yellow
            }

            # Get compliance states
            $script:PolicyStates = Get-AzPolicyState -ResourceGroupName $script:ResourceGroupName -ErrorAction SilentlyContinue |
            Where-Object { $_.PolicyDefinitionName -like "*$script:PolicyName*" }
        }

        It 'Should have policy states available' {
            if ($script:PolicyStates) {
                $script:PolicyStates.Count | Should -BeGreaterThan 0
                Write-Host "Found $($script:PolicyStates.Count) policy state(s)" -ForegroundColor Green
            }
            else {
                Write-Host "No policy states found yet - evaluation may still be in progress" -ForegroundColor Yellow
                Set-ItResult -Skipped -Because "Policy evaluation not yet complete"
            }
        }

        It 'Should show compliant storage account as Compliant' -Skip:($null -eq $script:PolicyStates) {
            $compliantState = $script:PolicyStates | Where-Object {
                $_.ResourceId -like "*$script:CompliantStorageName*"
            }

            if ($compliantState) {
                $compliantState.ComplianceState | Should -Be 'Compliant'
                Write-Host "Compliant storage account correctly evaluated: $($compliantState.ComplianceState)" -ForegroundColor Green
            }
            else {
                Write-Host "Compliant storage account state not found in evaluation results" -ForegroundColor Yellow
                Set-ItResult -Skipped -Because "Policy state not yet available for compliant resource"
            }
        }

        It 'Should show non-compliant storage accounts as NonCompliant' -Skip:($null -eq $script:PolicyStates) {
            $nonCompliantStates = $script:PolicyStates | Where-Object {
                $_.ResourceId -like "*$script:NonCompliantStorageName*" -or
                $_.ResourceId -like "*$script:NoSasPolicyStorageName*"
            }

            if ($nonCompliantStates) {
                $nonCompliantStates | ForEach-Object {
                    Write-Host "Storage account: $($_.ResourceId) - State: $($_.ComplianceState)" -ForegroundColor Yellow
                }
                $nonCompliantStates | Where-Object { $_.ComplianceState -eq 'NonCompliant' } | Should -Not -BeNullOrEmpty
            }
            else {
                Write-Host "Non-compliant storage account states not found in evaluation results" -ForegroundColor Yellow
                Set-ItResult -Skipped -Because "Policy states not yet available for non-compliant resources"
            }
        }
    }

    Context 'Policy Evaluation Details' {
        It 'Should display detailed compliance information' {
            if ($script:PolicyStates) {
                Write-Host "`n=== Policy Compliance Details ===" -ForegroundColor Cyan
                $script:PolicyStates | ForEach-Object {
                    Write-Host "Resource: $($_.ResourceId)" -ForegroundColor White
                    Write-Host "  Compliance: $($_.ComplianceState)" -ForegroundColor $(if ($_.ComplianceState -eq 'Compliant') { 'Green' } else { 'Red' })
                    Write-Host "  Policy: $($_.PolicyDefinitionName)" -ForegroundColor Gray
                    Write-Host "  Timestamp: $($_.Timestamp)" -ForegroundColor Gray
                    Write-Host ""
                }
            }
            $true | Should -Be $true
        }
    }
}

AfterAll {
    # Cleanup test resources
    if ($script:TestResources -and $script:TestResources.Count -gt 0) {
        Write-Host "`n=== Cleaning Up Test Resources ===" -ForegroundColor Cyan
        foreach ($storageName in $script:TestResources) {
            try {
                Write-Host "Removing storage account: $storageName" -ForegroundColor Yellow
                Remove-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                    -Name $storageName `
                    -Force `
                    -ErrorAction SilentlyContinue
                Write-Host "  Removed: $storageName" -ForegroundColor Green
            }
            catch {
                Write-Host "  Could not remove $storageName : $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
}
