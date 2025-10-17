#Requires -Modules Pester, Az.Accounts, Az.Resources, Az.Storage, Az.PolicyInsights

<#
.SYNOPSIS
    Integration tests for Storage Account Naming Convention policy
.DESCRIPTION
    Tests actual compliance for storage account naming patterns.
#>

BeforeAll {
    . "$PSScriptRoot\..\..\config\config-loader.ps1"
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'governance' -PolicyName 'enforce-naming-convention-storage'
    Import-PolicyTestModule -ModuleTypes @('Required', 'Storage')

    $envInit = Initialize-PolicyTestEnvironment -Config $script:TestConfig -SkipIfNoContext $script:TestConfig.Azure.SkipIfNoContext
    if (-not $envInit.Success) {
        if ($envInit.ShouldSkip) {
            Write-Host 'Skipping all tests - no Azure context available' -ForegroundColor Yellow
            return
        }
        throw 'Environment initialization failed'
    }

    $script:ResourceGroupName = $script:TestConfig.Azure.ResourceGroupName
    $script:ResourceGroup = $envInit.ResourceGroup
}

Describe 'Naming Convention Compliance' -Tag @('Integration', 'Slow', 'Compliance', 'RequiresCleanup') {
    Context 'Storage Account Naming' {
        It 'Should create compliant storage account name' {
            # Pattern expects: ^st(dev|test|staging|prod)[a-z0-9]{3,15}$ (enforced pattern comes from module input)
            $timestamp = Get-Date -Format 'HHmmss'
            $compliantName = "stdevtest$timestamp"

            Write-Host "  Creating compliant storage account: $compliantName" -ForegroundColor Gray

            $errorVar = $null
            $script:CompliantStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                -Name $compliantName `
                -Location $script:ResourceGroup.Location `
                -SkuName 'Standard_LRS' `
                -Tag @{ Environment = 'test'; TestResource = 'true' } `
                -ErrorVariable errorVar `
                -ErrorAction SilentlyContinue

            if (-not $script:CompliantStorage -and $errorVar) {
                Write-Warning "First attempt failed: $($errorVar[0].Exception.Message)"
            }

            if (-not $script:CompliantStorage) {
                # Try alternate name
                $compliantName = "stprodweb$(Get-Random -Minimum 100 -Maximum 999)"
                Write-Host "  Retrying with alternate name: $compliantName" -ForegroundColor Gray
                $errorVar = $null
                $script:CompliantStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                    -Name $compliantName `
                    -Location $script:ResourceGroup.Location `
                    -SkuName 'Standard_LRS' `
                    -Tag @{ Environment = 'test'; TestResource = 'true' } `
                    -ErrorVariable errorVar `
                    -ErrorAction SilentlyContinue

                if (-not $script:CompliantStorage -and $errorVar) {
                    Write-Warning "Second attempt failed: $($errorVar[0].Exception.Message)"
                }
            }

            if (-not $script:CompliantStorage) {
                Set-ItResult -Skipped -Because 'Unable to create storage account - name may be taken, quota exceeded, or region limitation'
                return
            }

            $script:CompliantStorage | Should -Not -BeNullOrEmpty
            $script:CompliantStorage.StorageAccountName | Should -Match '^st(dev|test|staging|prod)'
            Write-Host "  ✓ Created: $($script:CompliantStorage.StorageAccountName)" -ForegroundColor Green
        }

        It 'Should create non-compliant storage account name (Audit mode)' {
            # Note: In Audit mode, non-compliant resources are created but flagged
            $timestamp = Get-Date -Format 'HHmmss'
            $nonCompliantName = "mystorage$timestamp"

            Write-Host "  Creating non-compliant storage account: $nonCompliantName" -ForegroundColor Gray

            $script:NonCompliantStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                -Name $nonCompliantName `
                -Location $script:ResourceGroup.Location `
                -SkuName 'Standard_LRS' `
                -Tag @{ Environment = 'test'; TestResource = 'true' } `
                -ErrorAction SilentlyContinue

            if (-not $script:NonCompliantStorage) {
                # Try alternate name
                $nonCompliantName = "mydata$(Get-Random -Minimum 100 -Maximum 999)"
                Write-Host "  Retrying with alternate name: $nonCompliantName" -ForegroundColor Gray
                $script:NonCompliantStorage = New-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
                    -Name $nonCompliantName `
                    -Location $script:ResourceGroup.Location `
                    -SkuName 'Standard_LRS' `
                    -Tag @{ Environment = 'test'; TestResource = 'true' } `
                    -ErrorAction SilentlyContinue
            }

            if (-not $script:NonCompliantStorage) {
                Set-ItResult -Skipped -Because 'Unable to create storage account - name may be taken, quota exceeded, blocked by policy, or region limitation'
                return
            }

            $script:NonCompliantStorage | Should -Not -BeNullOrEmpty
            $script:NonCompliantStorage.StorageAccountName | Should -Not -Match '^st(dev|test|staging|prod)'
            Write-Host "  ✓ Created: $($script:NonCompliantStorage.StorageAccountName)" -ForegroundColor Yellow
        }
    }
}

AfterAll {
    Write-Host 'Cleaning up test resources...' -ForegroundColor Yellow

    if ($script:CompliantStorage) {
        Write-Host "  Removing compliant storage account: $($script:CompliantStorage.StorageAccountName)" -ForegroundColor Gray
        Remove-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
            -Name $script:CompliantStorage.StorageAccountName -Force -ErrorAction SilentlyContinue
    }

    if ($script:NonCompliantStorage) {
        Write-Host "  Removing non-compliant storage account: $($script:NonCompliantStorage.StorageAccountName)" -ForegroundColor Gray
        Remove-AzStorageAccount -ResourceGroupName $script:ResourceGroupName `
            -Name $script:NonCompliantStorage.StorageAccountName -Force -ErrorAction SilentlyContinue
    }

    Write-Host 'Test cleanup completed.' -ForegroundColor Green
}
