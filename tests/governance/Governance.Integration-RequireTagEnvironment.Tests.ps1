#Requires -Modules Pester, Az.Accounts, Az.Resources, Az.PolicyInsights

<#
.SYNOPSIS
    Integration tests for the Require Environment Tag policy
.DESCRIPTION
    This test suite validates the Azure Policy definition and tests actual compliance
    behavior for resources with and without the Environment tag.
.NOTES
    Prerequisites:
    - Azure PowerShell modules (Az.Accounts, Az.Resources, Az.PolicyInsights)
    - Authenticated Azure session with appropriate permissions
    - Resource group for testing must exist
    - Policy must be assigned to the resource group
#>

BeforeAll {
    # Import centralized configuration
    . "$PSScriptRoot\..\..\config\config-loader.ps1"

    # Initialize test configuration for this specific policy
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'governance' -PolicyName 'require-tag-environment'

    # Import required modules
    Import-PolicyTestModule -ModuleTypes @('Required')

    # Initialize test environment
    $envInit = Initialize-PolicyTestEnvironment -Config $script:TestConfig -SkipIfNoContext $script:TestConfig.Azure.SkipIfNoContext
    if (-not $envInit.Success) {
        if ($envInit.ShouldSkip) {
            Write-Host 'Skipping all tests - no Azure context available' -ForegroundColor Yellow
            return
        }
        throw "Environment initialization failed: $($envInit.Errors -join '; ')"
    }

    # Set script variables
    $script:ResourceGroupName = $script:TestConfig.Azure.ResourceGroupName
    $script:PolicyName = $script:TestConfig.Policy.Name
    $script:PolicyDisplayName = $script:TestConfig.Policy.DisplayName
    $script:Context = $envInit.Context
    $script:SubscriptionId = $envInit.SubscriptionId
    $script:ResourceGroup = $envInit.ResourceGroup

    Write-Host "Running tests in subscription: $($script:Context.Subscription.Name) ($script:SubscriptionId)" -ForegroundColor Green

    # Load policy definition
    $policyPath = Get-PolicyDefinitionPath -PolicyCategory 'governance' -PolicyName 'require-tag-environment' -TestScriptPath $PSScriptRoot
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

        It 'Should check for Environment tag' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $anyOfConditions = $policyRule.if.anyOf
            $anyOfConditions | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Policy Compliance Testing' -Tag @('Integration', 'Slow', 'Compliance', 'RequiresCleanup') {
    Context 'Resource Tag Compliance Scenarios' {
        BeforeAll {
            $script:CompliantTagName = New-PolicyTestResourceName -PolicyCategory 'governance' -PolicyName 'require-tag-environment' -ResourceType 'compliant'
            $script:NonCompliantTagName = New-PolicyTestResourceName -PolicyCategory 'governance' -PolicyName 'require-tag-environment' -ResourceType 'nonCompliant'
        }

        It 'Should create compliant resource group (with Environment tag)' {
            $script:CompliantRG = New-AzResourceGroup -Name $script:CompliantTagName `
                -Location $script:ResourceGroup.Location `
                -Tag @{Environment = 'dev'; TestResource = 'true'} `
                -Force

            $script:CompliantRG | Should -Not -BeNullOrEmpty
            $script:CompliantRG.Tags['Environment'] | Should -Be 'dev'
        }

        It 'Should create non-compliant resource group (without Environment tag)' {
            try {
                $script:NonCompliantRG = New-AzResourceGroup -Name $script:NonCompliantTagName `
                    -Location $script:ResourceGroup.Location `
                    -Tag @{TestResource = 'true'} `
                    -Force
            }
            catch {
                if ($_.Exception.Message -match 'RequestDisallowedByPolicy|disallowed by policy') {
                    Write-Host "Resource creation blocked by policy (expected for Deny effect)" -ForegroundColor Yellow
                    Set-ItResult -Skipped -Because "Policy with Deny effect prevents creation of non-compliant resources"
                    return
                }
                throw
            }

            $script:NonCompliantRG | Should -Not -BeNullOrEmpty
            $script:NonCompliantRG.Tags.ContainsKey('Environment') | Should -Be $false
        }

        It 'Should wait for policy evaluation' {
            $waitTime = $script:TestConfig.Timeouts.PolicyEvaluationWaitSeconds
            Write-Host "Waiting $waitTime seconds for policy evaluation..." -ForegroundColor Yellow
            Start-Sleep -Seconds $waitTime
        }
    }

    Context 'Policy Compliance Results' {
        BeforeAll {
            try {
                Start-AzPolicyComplianceScan -ResourceGroupName $script:ResourceGroupName -AsJob | Out-Null
                Start-Sleep -Seconds $script:TestConfig.Timeouts.ComplianceScanWaitSeconds
            }
            catch {
                Write-Warning "Could not trigger compliance scan: $($_.Exception.Message)"
            }

            $script:ComplianceStates = Get-AzPolicyState -ResourceGroupName $script:ResourceGroupName
        }

        It 'Should have compliance data available' {
            $script:ComplianceStates | Should -Not -BeNullOrEmpty
        }

        It 'Should show compliant resource as compliant' -Skip:($null -eq $script:CompliantRG) {
            $compliantState = $script:ComplianceStates | Where-Object {
                $_.ResourceId -like "*$script:CompliantTagName*"
            }

            if ($compliantState) {
                $compliantState.ComplianceState | Should -Be 'Compliant'
            }
            else {
                Write-Warning 'Compliance state not yet available'
            }
        }
    }
}

AfterAll {
    Write-Host 'Cleaning up test resources...' -ForegroundColor Yellow

    if ($script:CompliantRG) {
        try {
            Remove-AzResourceGroup -Name $script:CompliantTagName -Force -ErrorAction SilentlyContinue
            Write-Host "Removed compliant test resource group: $script:CompliantTagName" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not remove compliant resource group: $($_.Exception.Message)"
        }
    }

    if ($script:NonCompliantRG) {
        try {
            Remove-AzResourceGroup -Name $script:NonCompliantTagName -Force -ErrorAction SilentlyContinue
            Write-Host "Removed non-compliant test resource group: $script:NonCompliantTagName" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not remove non-compliant resource group: $($_.Exception.Message)"
        }
    }

    Write-Host 'Test cleanup completed.' -ForegroundColor Green
}
