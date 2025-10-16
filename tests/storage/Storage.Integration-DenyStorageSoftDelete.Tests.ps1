#Requires -Modules Pester, Az.Accounts, Az.Resources, Az.Storage, Az.PolicyInsights

<#
.SYNOPSIS
    Integration tests for the Deny Storage Soft Delete policy
.DESCRIPTION
    This test suite validates the Azure Policy definition and tests actual compliance
    behavior for storage accounts with soft delete configurations.
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
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'storage' -PolicyName 'deny-storage-softdelete'

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
    $script:PolicyName = 'deny-storage-softdelete'
    $script:PolicyDisplayName = 'Deny Storage Account Soft Delete Disabled'
    $script:TestStorageAccountPrefix = 'testsdsa'

    # Set Azure context variables
    $script:Context = $envInit.Context
    $script:SubscriptionId = $envInit.SubscriptionId
    $script:ResourceGroup = $envInit.ResourceGroup

    Write-Host "Running tests in subscription: $($script:Context.Subscription.Name) ($script:SubscriptionId)" -ForegroundColor Green

    # Load policy definition from file using centralized path resolution
    $policyPath = Get-PolicyDefinitionPath -PolicyCategory 'storage' -PolicyName 'deny-storage-softdelete' -TestScriptPath $PSScriptRoot
    if (Test-Path $policyPath) {
        $script:PolicyDefinitionJson = Get-Content $policyPath -Raw | ConvertFrom-Json
    } else {
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
            $script:PolicyDefinitionJson.properties.description | Should -Match 'soft delete'
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

        It 'Should have minimumRetentionDays parameter' {
            $retentionParam = $script:PolicyDefinitionJson.properties.parameters.minimumRetentionDays
            $retentionParam | Should -Not -BeNullOrEmpty
            $retentionParam.type | Should -Be 'Integer'
            $retentionParam.defaultValue | Should -Be 7
            $retentionParam.minValue | Should -Be 1
            $retentionParam.maxValue | Should -Be 365
        }
    }
}

Describe 'Policy Assignment Validation' -Tag @('Integration', 'Fast', 'PolicyAssignment') {
    Context 'Policy Assignment Exists' {
        BeforeAll {
            $script:PolicyAssignments = Get-AzPolicyAssignment -Scope $script:ResourceGroup.ResourceId -ErrorAction SilentlyContinue
            $script:TargetAssignment = $script:PolicyAssignments | Where-Object {
                $_.DisplayName -like "*$script:PolicyDisplayName*" -or
                $_.Properties.DisplayName -like "*$script:PolicyDisplayName*" -or
                $_.Name -like "*$script:PolicyName*" -or
                $_.PolicyDefinitionId -like "*$script:PolicyName*" -or
                $_.Properties.PolicyDefinitionId -like "*$script:PolicyName*"
            }
        }

        It 'Should have policy assigned to resource group (or can skip if not deployed)' {
            if ($script:TargetAssignment) {
                $script:TargetAssignment | Should -Not -BeNullOrEmpty
                Write-Host "Policy assignment found: $($script:TargetAssignment.Name)" -ForegroundColor Green
            } else {
                Write-Host 'Policy not yet assigned - skipping assignment tests' -ForegroundColor Yellow
                Set-ItResult -Skipped -Because 'Policy not yet deployed/assigned'
            }
        }

        It 'Should be assigned at resource group scope' {
            if (-not $script:TargetAssignment) {
                Set-ItResult -Skipped -Because 'Policy assignment not found'
                return
            }
            $scope = if ($script:TargetAssignment.Properties.Scope) { $script:TargetAssignment.Properties.Scope } else { $script:TargetAssignment.Scope }
            $scope | Should -Be $script:ResourceGroup.ResourceId
        }

        It 'Should have policy definition associated' {
            if (-not $script:TargetAssignment) {
                Set-ItResult -Skipped -Because 'Policy assignment not found'
                return
            }
            $policyDefId = if ($script:TargetAssignment.Properties.PolicyDefinitionId) { $script:TargetAssignment.Properties.PolicyDefinitionId } else { $script:TargetAssignment.PolicyDefinitionId }
            $policyDefId | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Policy Compliance Testing' -Tag @('Integration', 'Slow', 'Compliance', 'RequiresCleanup') {
    Context 'Storage Account Soft Delete Scenarios' {
        BeforeAll {
            # Generate unique storage account names (max 24 chars for storage accounts)
            $timestamp = Get-Date -Format 'HHmmss'
            $randSuffix = "{0:D4}" -f (Get-Random -Minimum 0 -Maximum 10000)
            $script:CompliantStorageName = "sdcmpl$timestamp$randSuffix"  # 16 chars
            $script:NonCompliantBlobStorageName = "sdncblob$timestamp$randSuffix"  # 18 chars
            $script:NonCompliantContainerStorageName = "sdnccntr$timestamp$randSuffix"  # 18 chars
            $script:LowRetentionStorageName = "sdlowret$timestamp$randSuffix"  # 18 chars

            Write-Host "Test storage accounts: $script:CompliantStorageName, $script:NonCompliantBlobStorageName, $script:NonCompliantContainerStorageName, $script:LowRetentionStorageName" -ForegroundColor Yellow

            # Test resources collection for cleanup
            $script:TestResources = @()
        }

        It 'Should create compliant storage account (blob and container soft delete enabled with 30 day retention)' {
            # Create storage account with soft delete enabled for both blobs and containers
            try {
                # Step 1: Create the storage account
                $script:CompliantStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                    -Name $script:CompliantStorageName `
                    -Location $script:ResourceGroup.Location `
                    -SkuName 'Standard_LRS' `
                    -ErrorAction Stop

                $script:TestResources += $script:CompliantStorageName

                # Step 2: Enable soft delete for blobs and containers
                Enable-AzStorageBlobDeleteRetentionPolicy -ResourceGroupName $script:ResourceGroupName `
                    -StorageAccountName $script:CompliantStorageName `
                    -RetentionDays 30 `
                    -ErrorAction Stop

                Enable-AzStorageContainerDeleteRetentionPolicy -ResourceGroupName $script:ResourceGroupName `
                    -StorageAccountName $script:CompliantStorageName `
                    -RetentionDays 30 `
                    -ErrorAction Stop

            } catch {
                Write-Host "Error creating compliant storage account: $($_.Exception.Message)" -ForegroundColor Red
                throw
            }

            ($null -ne $script:CompliantStorage) | Should -BeTrue
            $script:CompliantStorage.StorageAccountName | Should -Be $script:CompliantStorageName

            # Verify soft delete configuration
            Write-Host "Verifying soft delete configuration for compliant storage account..." -ForegroundColor Yellow

            # Poll for up to 60 seconds for the expected soft delete configuration
            $maxAttempts = 12
            $attempt = 0
            do {
                $blobService = Get-AzStorageBlobServiceProperty -ResourceGroupName $script:ResourceGroupName `
                    -StorageAccountName $script:CompliantStorageName
                $blobDeleteEnabled = $blobService.DeleteRetentionPolicy.Enabled -eq $true
                $blobDeleteDaysOk = $blobService.DeleteRetentionPolicy.Days -ge 7
                $containerDeleteEnabled = $blobService.ContainerDeleteRetentionPolicy.Enabled -eq $true
                $containerDeleteDaysOk = $blobService.ContainerDeleteRetentionPolicy.Days -ge 7
                if ($blobDeleteEnabled -and $blobDeleteDaysOk -and $containerDeleteEnabled -and $containerDeleteDaysOk) {
                    break
                }
                Start-Sleep -Seconds 5
                $attempt++
            } while ($attempt -lt $maxAttempts)

            $blobService.DeleteRetentionPolicy.Enabled | Should -Be $true
            $blobService.DeleteRetentionPolicy.Days | Should -BeGreaterOrEqual 7
            $blobService.ContainerDeleteRetentionPolicy.Enabled | Should -Be $true
            $blobService.ContainerDeleteRetentionPolicy.Days | Should -BeGreaterOrEqual 7
        }

        It 'Should create non-compliant storage account (blob soft delete disabled)' {
            # Create storage account with blob soft delete disabled
            # This may be blocked if policy effect is 'Deny', or allowed if 'Audit'
            try {
                $script:NonCompliantBlobStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                    -Name $script:NonCompliantBlobStorageName `
                    -Location $script:ResourceGroup.Location `
                    -SkuName 'Standard_LRS' `
                    -ErrorAction Stop

                # Explicitly disable blob soft delete (it's disabled by default, but let's be explicit)
                Disable-AzStorageBlobDeleteRetentionPolicy -ResourceGroupName $script:ResourceGroupName `
                    -StorageAccountName $script:NonCompliantBlobStorageName `
                    -ErrorAction SilentlyContinue

                $script:TestResources += $script:NonCompliantBlobStorageName
                Write-Host 'Non-compliant storage account created (policy in Audit mode or not assigned)' -ForegroundColor Yellow
            } catch {
                if ($_.Exception.Message -match 'policy|denied|disallowed') {
                    Write-Host 'Storage account creation blocked by policy (expected with Deny effect)' -ForegroundColor Green
                    Set-ItResult -Skipped -Because 'Policy correctly denied non-compliant resource'
                } else {
                    Write-Host "Error creating non-compliant storage account: $($_.Exception.Message)" -ForegroundColor Red
                    throw
                }
            }

            if ($script:NonCompliantBlobStorage) {
                ($null -ne $script:NonCompliantBlobStorage) | Should -BeTrue
                $script:NonCompliantBlobStorage.StorageAccountName | Should -Be $script:NonCompliantBlobStorageName

                # Verify soft delete is disabled
                Start-Sleep -Seconds 5
                $blobService = Get-AzStorageBlobServiceProperty -ResourceGroupName $script:ResourceGroupName `
                    -StorageAccountName $script:NonCompliantBlobStorageName
                $blobService.DeleteRetentionPolicy.Enabled | Should -Be $false
            }
        }

        It 'Should create non-compliant storage account (container soft delete disabled)' {
            # Create storage account with container soft delete disabled
            try {
                $script:NonCompliantContainerStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                    -Name $script:NonCompliantContainerStorageName `
                    -Location $script:ResourceGroup.Location `
                    -SkuName 'Standard_LRS' `
                    -ErrorAction Stop

                # Enable blob soft delete but leave container soft delete disabled
                Enable-AzStorageBlobDeleteRetentionPolicy -ResourceGroupName $script:ResourceGroupName `
                    -StorageAccountName $script:NonCompliantContainerStorageName `
                    -RetentionDays 30 `
                    -ErrorAction Stop

                # Container soft delete is disabled by default, just verify
                $script:TestResources += $script:NonCompliantContainerStorageName
                Write-Host 'Storage account with container soft delete disabled created (policy in Audit mode or not assigned)' -ForegroundColor Yellow
            } catch {
                if ($_.Exception.Message -match 'policy|denied|disallowed') {
                    Write-Host 'Storage account creation blocked by policy (expected with Deny effect)' -ForegroundColor Green
                    Set-ItResult -Skipped -Because 'Policy correctly denied resource without container soft delete'
                } else {
                    Write-Host "Error creating storage account: $($_.Exception.Message)" -ForegroundColor Red
                    throw
                }
            }

            if ($script:NonCompliantContainerStorage) {
                ($null -ne $script:NonCompliantContainerStorage) | Should -BeTrue
                $script:NonCompliantContainerStorage.StorageAccountName | Should -Be $script:NonCompliantContainerStorageName

                # Verify container soft delete is disabled (null or false both indicate disabled)
                Start-Sleep -Seconds 5
                $blobService = Get-AzStorageBlobServiceProperty -ResourceGroupName $script:ResourceGroupName `
                    -StorageAccountName $script:NonCompliantContainerStorageName
                $blobService.ContainerDeleteRetentionPolicy.Enabled | Should -Not -Be $true
            }
        }

        It 'Should create non-compliant storage account (retention days below minimum)' {
            # Create storage account with retention days below the minimum (7 days)
            try {
                $script:LowRetentionStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                    -Name $script:LowRetentionStorageName `
                    -Location $script:ResourceGroup.Location `
                    -SkuName 'Standard_LRS' `
                    -ErrorAction Stop

                # Enable soft delete with low retention days (below minimum)
                Enable-AzStorageBlobDeleteRetentionPolicy -ResourceGroupName $script:ResourceGroupName `
                    -StorageAccountName $script:LowRetentionStorageName `
                    -RetentionDays 3 `
                    -ErrorAction Stop

                Enable-AzStorageContainerDeleteRetentionPolicy -ResourceGroupName $script:ResourceGroupName `
                    -StorageAccountName $script:LowRetentionStorageName `
                    -RetentionDays 3 `
                    -ErrorAction Stop

                $script:TestResources += $script:LowRetentionStorageName
                Write-Host 'Storage account with low retention created (policy in Audit mode or not assigned)' -ForegroundColor Yellow
            } catch {
                if ($_.Exception.Message -match 'policy|denied|disallowed') {
                    Write-Host 'Storage account creation blocked by policy (expected with Deny effect)' -ForegroundColor Green
                    Set-ItResult -Skipped -Because 'Policy correctly denied resource with insufficient retention'
                } else {
                    Write-Host "Error creating storage account: $($_.Exception.Message)" -ForegroundColor Red
                    throw
                }
            }

            if ($script:LowRetentionStorage) {
                ($null -ne $script:LowRetentionStorage) | Should -BeTrue
                $script:LowRetentionStorage.StorageAccountName | Should -Be $script:LowRetentionStorageName

                # Verify low retention days using polling loop (retry every 5s up to 60s)
                $maxAttempts = 12
                $attempt = 0
                $retentionDays = $null
                do {
                    $blobService = Get-AzStorageBlobServiceProperty -ResourceGroupName $script:ResourceGroupName `
                        -StorageAccountName $script:LowRetentionStorageName
                    $retentionDays = $blobService.DeleteRetentionPolicy.Days
                    if ($retentionDays -lt 7) { break }
                    Start-Sleep -Seconds 5
                    $attempt++
                } while ($attempt -lt $maxAttempts)
                $retentionDays | Should -BeLessThan 7
            }
        }

        It 'Should wait for policy evaluation to complete' {
            # Azure Policy evaluation can take several minutes
            Write-Host 'Waiting 90 seconds for policy evaluation...' -ForegroundColor Yellow
            Start-Sleep -Seconds 90
            $true | Should -Be $true
        }
    }

    Context 'Policy Compliance Validation' -Skip:($script:TestResources.Count -eq 0) {
        BeforeAll {
            # Trigger policy compliance scan
            try {
                Write-Host 'Triggering policy compliance scan...' -ForegroundColor Yellow
                Start-AzPolicyComplianceScan -ResourceGroupName $script:ResourceGroupName -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 30
            } catch {
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
            } else {
                Write-Host 'No policy states found yet - evaluation may still be in progress' -ForegroundColor Yellow
                Set-ItResult -Skipped -Because 'Policy evaluation not yet complete'
            }
        }

        It 'Should show compliant storage account as Compliant' -Skip:($null -eq $script:PolicyStates) {
            $compliantState = $script:PolicyStates | Where-Object {
                $_.ResourceId -like "*$script:CompliantStorageName*"
            }

            if ($compliantState) {
                $compliantState.ComplianceState | Should -Be 'Compliant'
                Write-Host "Compliant storage account correctly evaluated: $($compliantState.ComplianceState)" -ForegroundColor Green
            } else {
                Write-Host 'Compliant storage account state not found in evaluation results' -ForegroundColor Yellow
                Set-ItResult -Skipped -Because 'Policy state not yet available for compliant resource'
            }
        }

        It 'Should show non-compliant storage accounts as NonCompliant' -Skip:($null -eq $script:PolicyStates) {
            $nonCompliantStates = $script:PolicyStates | Where-Object {
                $_.ResourceId -like "*$script:NonCompliantBlobStorageName*" -or
                $_.ResourceId -like "*$script:NonCompliantContainerStorageName*" -or
                $_.ResourceId -like "*$script:LowRetentionStorageName*"
            }

            if ($nonCompliantStates) {
                $nonCompliantStates | ForEach-Object {
                    Write-Host "Storage account: $($_.ResourceId) - State: $($_.ComplianceState)" -ForegroundColor Yellow
                }
                $nonCompliantStates | Where-Object { $_.ComplianceState -eq 'NonCompliant' } | Should -Not -BeNullOrEmpty
            } else {
                Write-Host 'Non-compliant storage account states not found in evaluation results' -ForegroundColor Yellow
                Set-ItResult -Skipped -Because 'Policy states not yet available for non-compliant resources'
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
                    Write-Host ''
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
            } catch {
                Write-Host "  Could not remove $storageName : $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
}
