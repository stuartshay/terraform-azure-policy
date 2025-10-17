#Requires -Modules Pester, Az.Accounts, Az.Resources, Az.PolicyInsights

<#
.SYNOPSIS
    Integration tests for the Require CostCenter Tag policy
.DESCRIPTION
    This test suite validates policy compliance for resources with CostCenter tags.
#>

BeforeAll {
    . "$PSScriptRoot\..\..\config\config-loader.ps1"
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'governance' -PolicyName 'require-tag-costcenter'
    Import-PolicyTestModule -ModuleTypes @('Required')

    $envInit = Initialize-PolicyTestEnvironment -Config $script:TestConfig -SkipIfNoContext $script:TestConfig.Azure.SkipIfNoContext
    if (-not $envInit.Success) {
        if ($envInit.ShouldSkip) {
            Write-Host 'Skipping all tests - no Azure context available' -ForegroundColor Yellow
            return
        }
        throw "Environment initialization failed: $($envInit.Errors -join '; ')"
    }

    $script:ResourceGroupName = $script:TestConfig.Azure.ResourceGroupName
    $script:PolicyName = $script:TestConfig.Policy.Name
    $script:ResourceGroup = $envInit.ResourceGroup

    $policyPath = Get-PolicyDefinitionPath -PolicyCategory 'governance' -PolicyName 'require-tag-costcenter' -TestScriptPath $PSScriptRoot
    if (Test-Path $policyPath) {
        $script:PolicyDefinitionJson = Get-Content $policyPath -Raw | ConvertFrom-Json
    }
}

Describe 'Policy Compliance Testing' -Tag @('Integration', 'Slow', 'Compliance', 'RequiresCleanup') {
    Context 'CostCenter Tag Compliance' {
        BeforeAll {
            $script:CompliantName = New-PolicyTestResourceName -PolicyCategory 'governance' -PolicyName 'require-tag-costcenter' -ResourceType 'compliant'
            $script:NonCompliantName = New-PolicyTestResourceName -PolicyCategory 'governance' -PolicyName 'require-tag-costcenter' -ResourceType 'nonCompliant'
        }

        It 'Should create resource with valid CostCenter tag' {
            $script:CompliantRG = New-AzResourceGroup -Name $script:CompliantName `
                -Location $script:ResourceGroup.Location `
                -Tag @{CostCenter = 'CC-1234'; TestResource = 'true'} `
                -Force

            $script:CompliantRG | Should -Not -BeNullOrEmpty
            $script:CompliantRG.Tags['CostCenter'] | Should -Match '^CC-\d{4,6}$'
        }

        It 'Should create resource with invalid CostCenter tag' {
            try {
                $script:NonCompliantRG = New-AzResourceGroup -Name $script:NonCompliantName `
                    -Location $script:ResourceGroup.Location `
                    -Tag @{CostCenter = '1234'; TestResource = 'true'} `
                    -Force
            }
            catch {
                if ($_.Exception.Message -match 'RequestDisallowedByPolicy') {
                    Set-ItResult -Skipped -Because "Policy prevents creation"
                    return
                }
                throw
            }

            $script:NonCompliantRG | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    if ($script:CompliantRG) {
        Remove-AzResourceGroup -Name $script:CompliantName -Force -ErrorAction SilentlyContinue
    }
    if ($script:NonCompliantRG) {
        Remove-AzResourceGroup -Name $script:NonCompliantName -Force -ErrorAction SilentlyContinue
    }
}
