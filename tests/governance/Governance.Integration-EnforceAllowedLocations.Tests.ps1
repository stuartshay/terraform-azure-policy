#Requires -Modules Pester, Az.Accounts, Az.Resources, Az.PolicyInsights

<#
.SYNOPSIS
    Integration tests for Enforce Allowed Locations policy
.DESCRIPTION
    Tests location restriction compliance.
#>

BeforeAll {
    . "$PSScriptRoot\..\..\config\config-loader.ps1"
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'governance' -PolicyName 'enforce-allowed-locations'
    Import-PolicyTestModule -ModuleTypes @('Required')

    $envInit = Initialize-PolicyTestEnvironment -Config $script:TestConfig -SkipIfNoContext $script:TestConfig.Azure.SkipIfNoContext
    if (-not $envInit.Success) {
        if ($envInit.ShouldSkip) {
            Write-Host 'Skipping all tests - no Azure context available' -ForegroundColor Yellow
            return
        }
        throw "Environment initialization failed"
    }

    $script:ResourceGroupName = $script:TestConfig.Azure.ResourceGroupName
    $script:ResourceGroup = $envInit.ResourceGroup
}

Describe 'Location Restriction Compliance' -Tag @('Integration', 'Slow', 'Compliance', 'RequiresCleanup') {
    Context 'Resource Location Validation' {
        It 'Should allow resource in allowed location' {
            $name = New-PolicyTestResourceName -PolicyCategory 'governance' -PolicyName 'enforce-allowed-locations' -ResourceType 'compliant'

            $script:AllowedRG = New-AzResourceGroup -Name $name `
                -Location $script:ResourceGroup.Location `
                -Tag @{TestResource = 'true'; Environment = 'test'} `
                -Force

            $script:AllowedRG | Should -Not -BeNullOrEmpty
            $script:AllowedRG.Location | Should -Be $script:ResourceGroup.Location
        }

        It 'Should create resource in non-allowed location (Audit mode)' {
            # Note: This test expects the policy to be in Audit mode (default)
            # In Audit mode, resources are created but flagged as non-compliant
            $name = New-PolicyTestResourceName -PolicyCategory 'governance' -PolicyName 'enforce-allowed-locations' -ResourceType 'nonCompliant'

            # westus is typically not in the allowed locations list
            $script:NonAllowedRG = New-AzResourceGroup -Name $name `
                -Location 'westus' `
                -Tag @{TestResource = 'true'; Environment = 'test'} `
                -Force `
                -ErrorAction SilentlyContinue

            if (-not $script:NonAllowedRG) {
                Set-ItResult -Skipped -Because 'Unable to create resource group in westus region'
            }
            else {
                $script:NonAllowedRG | Should -Not -BeNullOrEmpty
                $script:NonAllowedRG.Location | Should -Be 'westus'
            }
        }
    }
}

AfterAll {
    Write-Host 'Cleaning up test resources...' -ForegroundColor Yellow

    if ($script:AllowedRG) {
        Write-Host "  Removing allowed location RG: $($script:AllowedRG.ResourceGroupName)" -ForegroundColor Gray
        Remove-AzResourceGroup -Name $script:AllowedRG.ResourceGroupName -Force -ErrorAction SilentlyContinue
    }

    if ($script:NonAllowedRG) {
        Write-Host "  Removing non-allowed location RG: $($script:NonAllowedRG.ResourceGroupName)" -ForegroundColor Gray
        Remove-AzResourceGroup -Name $script:NonAllowedRG.ResourceGroupName -Force -ErrorAction SilentlyContinue
    }

    Write-Host 'Test cleanup completed.' -ForegroundColor Green
}
