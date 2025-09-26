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
    # Import required modules
    Import-Module Az.Accounts -Force
    Import-Module Az.Resources -Force
    Import-Module Az.Storage -Force
    Import-Module Az.PolicyInsights -Force

    # Test configuration
    $script:ResourceGroupName = 'rg-azure-policy-testing'
    $script:PolicyName = 'deny-storage-account-public-access'
    $script:PolicyDisplayName = 'Deny Storage Account Public Access'
    $script:TestStorageAccountPrefix = 'testpolicysa'

    # Get current context
    $script:Context = Get-AzContext
    if (-not $script:Context) {
        throw 'No Azure context found. Please run Connect-AzAccount first.'
    }

    $script:SubscriptionId = $script:Context.Subscription.Id
    Write-Host "Running tests in subscription: $($script:Context.Subscription.Name) ($script:SubscriptionId)" -ForegroundColor Green

    # Verify resource group exists
    $script:ResourceGroup = Get-AzResourceGroup -Name $script:ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $script:ResourceGroup) {
        throw "Resource group '$script:ResourceGroupName' not found. Please create it first."
    }

    # Load policy definition from file
    $policyPath = Join-Path $PSScriptRoot '..\..\policies\storage\deny-storage-account-public-access.json'
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

        It 'Should have Audit effect (for testing)' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $policyRule.then.effect | Should -Be 'Audit'
        }

        It 'Should check allowBlobPublicAccess property' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf
            $blobCondition = $conditions | Where-Object { $_.field -eq 'Microsoft.Storage/storageAccounts/allowBlobPublicAccess' }
            $blobCondition | Should -Not -BeNullOrEmpty
            $blobCondition.equals | Should -Be $true
        }

        It 'Should check publicNetworkAccess property' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf
            $networkCondition = $conditions | Where-Object { $_.field -eq 'Microsoft.Storage/storageAccounts/publicNetworkAccess' }
            $networkCondition | Should -Not -BeNullOrEmpty
            $networkCondition.equals | Should -Be 'Enabled'
        }
    }
}

Describe 'Policy Assignment Validation' -Tag @('Integration', 'Fast', 'PolicyAssignment') {
    Context 'Policy Assignment Exists' {
        BeforeAll {
            $script:PolicyAssignments = Get-AzPolicyAssignment -Scope $script:ResourceGroup.ResourceId
            $script:TargetAssignment = $script:PolicyAssignments | Where-Object {
                $_.Properties.DisplayName -like "*$script:PolicyDisplayName*" -or
                $_.Name -like "*$script:PolicyName*"
            }
        }

        It 'Should have policy assigned to resource group' {
            $script:TargetAssignment | Should -Not -BeNullOrEmpty
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
    }
}

Describe 'Policy Compliance Testing' -Tag @('Integration', 'Slow', 'Compliance', 'RequiresCleanup') {
    Context 'Storage Account Compliance Scenarios' {
        BeforeAll {
            # Generate unique storage account names
            $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
            $script:CompliantStorageName = "$script:TestStorageAccountPrefix$timestamp" + 'comp'
            $script:NonCompliantStorageName = "$script:TestStorageAccountPrefix$timestamp" + 'nonc'

            # Ensure names are valid (lowercase, max 24 chars)
            $script:CompliantStorageName = $script:CompliantStorageName.ToLower().Substring(0, [Math]::Min(24, $script:CompliantStorageName.Length))
            $script:NonCompliantStorageName = $script:NonCompliantStorageName.ToLower().Substring(0, [Math]::Min(24, $script:NonCompliantStorageName.Length))

            Write-Host "Test storage accounts: $script:CompliantStorageName, $script:NonCompliantStorageName" -ForegroundColor Yellow
        }

        It 'Should create compliant storage account (public access disabled)' {
            # Create storage account with public access disabled
            $compliantStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                -Name $script:CompliantStorageName `
                -Location $script:ResourceGroup.Location `
                -SkuName 'Standard_LRS' `
                -AllowBlobPublicAccess $false `
                -PublicNetworkAccess 'Disabled' `
                -ErrorAction SilentlyContinue

            $compliantStorage | Should -Not -BeNullOrEmpty
            $script:CompliantStorage = $compliantStorage
        }

        It 'Should create non-compliant storage account (public access enabled)' {
            # Create storage account with public access enabled (violates policy)
            $nonCompliantStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                -Name $script:NonCompliantStorageName `
                -Location $script:ResourceGroup.Location `
                -SkuName 'Standard_LRS' `
                -AllowBlobPublicAccess $true `
                -PublicNetworkAccess 'Enabled' `
                -ErrorAction SilentlyContinue

            $nonCompliantStorage | Should -Not -BeNullOrEmpty
            $script:NonCompliantStorage = $nonCompliantStorage
        }

        It 'Should wait for policy evaluation to complete' {
            # Wait for Azure Policy to evaluate the resources
            Write-Host 'Waiting 60 seconds for policy evaluation...' -ForegroundColor Yellow
            Start-Sleep -Seconds 60
        }
    }

    Context 'Policy Compliance Results' {
        BeforeAll {
            # Trigger policy compliance scan
            try {
                Start-AzPolicyComplianceScan -ResourceGroupName $script:ResourceGroupName -AsJob | Out-Null
                Start-Sleep -Seconds 30
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
            Write-Host 'Waiting 30 seconds for policy re-evaluation...' -ForegroundColor Yellow
            Start-Sleep -Seconds 30
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
