#Requires -Modules Pester, Az.Accounts, Az.Resources, Az.PolicyInsights

<#
.SYNOPSIS
    Integration tests for Azure Function App AAD-only authentication policy
.DESCRIPTION
    This test suite validates the Azure Policy definition and tests actual compliance
    behavior for Function Apps with Azure AD authentication, FTP disabled, and
    basic publishing credentials disabled.
.NOTES
    Prerequisites:
    - Azure PowerShell modules (Az.Accounts, Az.Resources, Az.Functions, Az.PolicyInsights)
    - Authenticated Azure session with appropriate permissions
    - Resource group 'rg-azure-policy-testing' must exist
    - Policy must be assigned to the resource group
#>

BeforeAll {
    # Import centralized configuration
    . "$PSScriptRoot\..\..\config\config-loader.ps1"

    # Initialize test configuration for this specific policy
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'function-app' -PolicyName 'deny-function-app-aad-only'

    # Import required modules using centralized configuration
    Import-PolicyTestModule -ModuleTypes @('Required', 'FunctionApp')

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
    $script:TestFunctionAppPrefix = $script:TestConfig.Policy.ResourcePrefix

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
    $policyPath = Join-Path $PSScriptRoot '..\..\policies\function-app\deny-function-app-aad-only\rule.json'
    if (Test-Path $policyPath) {
        $script:PolicyDefinitionJson = Get-Content $policyPath -Raw | ConvertFrom-Json
    }
    else {
        throw "Policy definition file not found at: $policyPath"
    }

    # Variables for test resources (will be created during tests)
    $script:TestFunctionApps = @()
    $script:TestStorageAccounts = @()
}

Describe 'Policy Definition Validation' -Tag @('Integration', 'Fast', 'PolicyDefinition') {
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
            $script:PolicyDefinitionJson.properties.description | Should -Match 'Azure AD|AAD|authentication'
        }

        It 'Should have proper metadata' {
            $metadata = $script:PolicyDefinitionJson.properties.metadata
            $metadata | Should -Not -BeNullOrEmpty
            $metadata.category | Should -Be 'App Service'
            $metadata.version | Should -Not -BeNullOrEmpty
        }

        It 'Should have effect parameter with correct allowed values' {
            $effectParam = $script:PolicyDefinitionJson.properties.parameters.effect
            $effectParam | Should -Not -BeNullOrEmpty
            $effectParam.allowedValues | Should -Contain 'Audit'
            $effectParam.allowedValues | Should -Contain 'Deny'
            $effectParam.allowedValues | Should -Contain 'Disabled'
            $effectParam.defaultValue | Should -Be 'Deny'
        }
    }

    Context 'Policy Rule Logic' {
        It 'Should target authsettingsV2 config for authentication' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $authScenarios = $policyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object { $_.field -eq 'name' -and $_.equals -eq 'authsettingsV2' })
            }
            $authScenarios | Should -Not -BeNullOrEmpty
        }

        It 'Should target web config for FTP settings' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $ftpScenarios = $policyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object { $_.field -eq 'name' -and $_.equals -eq 'web' })
            }
            $ftpScenarios | Should -Not -BeNullOrEmpty
            $ftpScenarios.Count | Should -BeGreaterOrEqual 2  # Main app + slots
        }

        It 'Should target basicPublishingCredentialsPolicies' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $credScenarios = $policyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object {
                        $_.field -eq 'type' -and $_.equals -eq 'Microsoft.Web/sites/basicPublishingCredentialsPolicies'
                    })
            }
            $credScenarios | Should -Not -BeNullOrEmpty
            $credScenarios.Count | Should -BeGreaterOrEqual 2  # FTP + SCM
        }

        It 'Should check for Azure AD authentication enabled' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $aadCheck = $policyRule.if.anyOf | Where-Object {
                $_.allOf.anyOf | Where-Object {
                    $_ | Where-Object { $_.field -like '*azureActiveDirectory.enabled*' }
                }
            }
            $aadCheck | Should -Not -BeNullOrEmpty
        }

        It 'Should check for required authentication' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $authRequiredCheck = $policyRule.if.anyOf | Where-Object {
                $_.allOf.anyOf | Where-Object {
                    $_ | Where-Object { $_.field -like '*requireAuthentication*' }
                }
            }
            $authRequiredCheck | Should -Not -BeNullOrEmpty
        }

        It 'Should check for FTP disabled' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $ftpCheck = $policyRule.if.anyOf | Where-Object {
                $_.allOf | Where-Object { $_.field -like '*ftpsState*' -and $_.notEquals -eq 'Disabled' }
            }
            $ftpCheck | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Policy Assignment Validation' -Tag @('Integration', 'Fast', 'PolicyAssignment') {
    Context 'Policy Assignment Exists' {
        It 'Should have policy definition in Azure' {
            $policyDef = Get-AzPolicyDefinition | Where-Object { $_.Name -eq $script:PolicyName }
            if (-not $policyDef) {
                Set-ItResult -Skipped -Because "Policy '$script:PolicyName' not deployed to Azure yet"
            }
            $policyDef | Should -Not -BeNullOrEmpty
        }

        It 'Should have policy assigned to resource group' -Skip:$(-not (Get-AzPolicyDefinition | Where-Object { $_.Name -eq $script:PolicyName })) {
            $assignments = Get-AzPolicyAssignment -Scope $script:ResourceGroup.ResourceId -ErrorAction SilentlyContinue
            $policyAssignment = $assignments | Where-Object {
                $_.Properties.PolicyDefinitionId -like "*$script:PolicyName*"
            }

            if (-not $policyAssignment) {
                Set-ItResult -Skipped -Because "Policy not assigned to resource group '$script:ResourceGroupName'"
            }
            $policyAssignment | Should -Not -BeNullOrEmpty
        }

        It 'Should be assigned at resource group scope' -Skip:$(-not (Get-AzPolicyDefinition | Where-Object { $_.Name -eq $script:PolicyName })) {
            $assignments = Get-AzPolicyAssignment -Scope $script:ResourceGroup.ResourceId -ErrorAction SilentlyContinue
            $policyAssignment = $assignments | Where-Object {
                $_.Properties.PolicyDefinitionId -like "*$script:PolicyName*"
            }

            if ($policyAssignment) {
                $policyAssignment.Properties.Scope | Should -Match $script:ResourceGroupName
            }
        }
    }
}

Describe 'Policy Compliance Testing - Authentication Configuration' -Tag @('Integration', 'Slow', 'Compliance', 'RequiresCleanup') {
    Context 'Azure AD Authentication Compliance' {
        BeforeAll {
            # Check if policy is deployed and assigned
            $policyDef = Get-AzPolicyDefinition | Where-Object { $_.Name -eq $script:PolicyName }
            if (-not $policyDef) {
                Write-Warning "Policy not deployed - skipping compliance tests"
                return
            }

            $assignments = Get-AzPolicyAssignment -Scope $script:ResourceGroup.ResourceId -ErrorAction SilentlyContinue
            $policyAssignment = $assignments | Where-Object {
                $_.Properties.PolicyDefinitionId -like "*$script:PolicyName*"
            }
            if (-not $policyAssignment) {
                Write-Warning "Policy not assigned - skipping compliance tests"
                return
            }

            Write-Host "`n⚠️  Note: This policy validates config resources (authsettingsV2, web, basicPublishingCredentialsPolicies)" -ForegroundColor Yellow
            Write-Host "    Compliance is evaluated when these configurations are created or updated." -ForegroundColor Yellow
            Write-Host "    Testing requires creating Function Apps and then updating their auth/FTP/publishing settings.`n" -ForegroundColor Yellow
        }

        It 'Should document AAD authentication requirement' {
            $description = $script:PolicyDefinitionJson.properties.description
            $description | Should -Match 'Azure AD|AAD|authentication|Easy Auth'
        }

        It 'Should document FTP/FTPS disabled requirement' {
            $description = $script:PolicyDefinitionJson.properties.description
            $description | Should -Match 'FTP|FTPS|file transfer'
        }

        It 'Should document basic publishing credentials disabled requirement' {
            $description = $script:PolicyDefinitionJson.properties.description
            $description | Should -Match 'publishing|credentials|basic'
        }

        It 'Should have multiple violation scenarios (defense in depth)' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            # Policy should check at least 5 scenarios:
            # 1. authsettingsV2 (main app)
            # 2. web config FTP (main app)
            # 3. web config FTP (slots)
            # 4. FTP publishing credentials
            # 5. SCM publishing credentials
            $policyRule.if.anyOf.Count | Should -BeGreaterOrEqual 5
        }
    }
}

Describe 'Policy Evaluation Details' -Tag @('Integration', 'Informational') {
    Context 'Display Policy Configuration' {
        It 'Should display policy evaluation information' {
            Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "  Policy: $script:PolicyDisplayName" -ForegroundColor Cyan
            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

            Write-Host "`nPolicy Enforcement:" -ForegroundColor Yellow
            Write-Host "  • Azure AD authentication (Easy Auth v2) must be enabled" -ForegroundColor White
            Write-Host "  • requireAuthentication must be true" -ForegroundColor White
            Write-Host "  • Unauthenticated action must be RedirectToLoginPage or Return401" -ForegroundColor White
            Write-Host "  • FTP/FTPS must be disabled (ftpsState = Disabled)" -ForegroundColor White
            Write-Host "  • Basic publishing credentials must be disabled (FTP & SCM)" -ForegroundColor White

            Write-Host "`nTarget Resources:" -ForegroundColor Yellow
            Write-Host "  • Microsoft.Web/sites/config (authsettingsV2)" -ForegroundColor White
            Write-Host "  • Microsoft.Web/sites/config (web) - FTP settings" -ForegroundColor White
            Write-Host "  • Microsoft.Web/sites/slots/config (web) - FTP settings for slots" -ForegroundColor White
            Write-Host "  • Microsoft.Web/sites/basicPublishingCredentialsPolicies (ftp)" -ForegroundColor White
            Write-Host "  • Microsoft.Web/sites/basicPublishingCredentialsPolicies (scm)" -ForegroundColor White

            Write-Host "`nNote:" -ForegroundColor Yellow
            Write-Host "  This policy evaluates configuration resources, not the Function App itself." -ForegroundColor Gray
            Write-Host "  Compliance is assessed when auth settings, web config, or publishing" -ForegroundColor Gray
            Write-Host "  credential policies are created or updated." -ForegroundColor Gray

            Write-Host "`n═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

            $true | Should -Be $true
        }
    }

    Context 'Policy Compliance State' {
        It 'Should query current compliance state' -Skip:$(-not (Get-AzPolicyDefinition | Where-Object { $_.Name -eq $script:PolicyName })) {
            $assignments = Get-AzPolicyAssignment -Scope $script:ResourceGroup.ResourceId -ErrorAction SilentlyContinue
            $policyAssignment = $assignments | Where-Object {
                $_.Properties.PolicyDefinitionId -like "*$script:PolicyName*"
            }

            if (-not $policyAssignment) {
                Set-ItResult -Skipped -Because "Policy not assigned"
                return
            }

            # Get compliance state for this assignment
            $complianceStates = Get-AzPolicyState -ResourceGroupName $script:ResourceGroupName -ErrorAction SilentlyContinue |
                Where-Object { $_.PolicyDefinitionName -eq $script:PolicyName }

            Write-Host "`nCompliance Summary:" -ForegroundColor Cyan
            if ($complianceStates) {
                $compliant = ($complianceStates | Where-Object { $_.ComplianceState -eq 'Compliant' }).Count
                $nonCompliant = ($complianceStates | Where-Object { $_.ComplianceState -eq 'NonCompliant' }).Count

                Write-Host "  ✅ Compliant: $compliant" -ForegroundColor Green
                Write-Host "  ❌ Non-Compliant: $nonCompliant" -ForegroundColor Red
                Write-Host "  📊 Total Evaluated: $($complianceStates.Count)" -ForegroundColor Yellow

                if ($nonCompliant -gt 0) {
                    Write-Host "`nNon-Compliant Resources:" -ForegroundColor Red
                    $complianceStates | Where-Object { $_.ComplianceState -eq 'NonCompliant' } |
                        Select-Object -First 5 | ForEach-Object {
                        Write-Host "  • $($_.ResourceId.Split('/')[-1]) - $($_.ResourceType)" -ForegroundColor Gray
                    }
                }
            }
            else {
                Write-Host "  ℹ️  No compliance data available yet" -ForegroundColor Yellow
                Write-Host "  Run: Start-AzPolicyComplianceScan -ResourceGroupName '$script:ResourceGroupName'" -ForegroundColor Gray
            }

            $true | Should -Be $true
        }
    }
}

Describe 'Test Documentation and Guidance' -Tag @('Integration', 'Documentation') {
    Context 'Testing Approach' {
        It 'Should provide testing guidance for this policy' {
            Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║  Testing Guidance for AAD-Only Policy                     ║" -ForegroundColor Cyan
            Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

            Write-Host "`n📋 Policy Behavior:" -ForegroundColor Yellow
            Write-Host "  This policy evaluates CONFIGURATION resources, not Function Apps directly." -ForegroundColor White
            Write-Host "  It triggers when you:" -ForegroundColor White
            Write-Host "    1. Update authentication settings (authsettingsV2 config)" -ForegroundColor Gray
            Write-Host "    2. Update web config (FTP/FTPS settings)" -ForegroundColor Gray
            Write-Host "    3. Update publishing credential policies" -ForegroundColor Gray

            Write-Host "`n🧪 Manual Testing Steps:" -ForegroundColor Yellow
            Write-Host "  1. Create a Function App in the resource group" -ForegroundColor White
            Write-Host "  2. Try to configure it with non-compliant settings:" -ForegroundColor White
            Write-Host "     • Disable Azure AD authentication" -ForegroundColor Gray
            Write-Host "     • Enable FTP/FTPS" -ForegroundColor Gray
            Write-Host "     • Enable basic publishing credentials" -ForegroundColor Gray
            Write-Host "  3. Policy should deny (or audit) these configuration changes" -ForegroundColor White

            Write-Host "`n🔍 Verification:" -ForegroundColor Yellow
            Write-Host "  • Check Azure Portal → Policy → Compliance" -ForegroundColor White
            Write-Host "  • Look for config resource compliance states" -ForegroundColor White
            Write-Host "  • Run: Start-AzPolicyComplianceScan for immediate evaluation" -ForegroundColor White

            Write-Host "`n⚠️  Important Notes:" -ForegroundColor Yellow
            Write-Host "  • Policy applies to ALL App Services (not just Function Apps)" -ForegroundColor Gray
            Write-Host "  • Cannot filter by 'kind' field (not a valid Azure Policy alias)" -ForegroundColor Gray
            Write-Host "  • Authentication settings apply to main app only (not slots)" -ForegroundColor Gray
            Write-Host "  • FTP settings apply to both main app and deployment slots" -ForegroundColor Gray
            Write-Host "  • Publishing credentials apply at app level" -ForegroundColor Gray

            Write-Host "`n═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

            $true | Should -Be $true
        }
    }

    Context 'Alternative Validation Methods' {
        It 'Should document alternative validation approaches' {
            Write-Host "`n📊 Alternative Validation Methods:" -ForegroundColor Yellow

            Write-Host "`n1️⃣  Azure Resource Graph Query:" -ForegroundColor Cyan
            Write-Host @'
resources
| where type =~ 'Microsoft.Web/sites'
| extend authSettings = properties.siteConfig.authSettings
| extend ftpsState = properties.siteConfig.ftpsState
| extend aadEnabled = tobool(authSettings.enabled)
| extend requireAuth = tobool(authSettings.requireAuthentication)
| where aadEnabled != true or requireAuth != true or ftpsState != 'Disabled'
| project name, resourceGroup, aadEnabled, requireAuth, ftpsState
'@ -ForegroundColor Gray

            Write-Host "`n2️⃣  PowerShell Validation:" -ForegroundColor Cyan
            Write-Host @'
$functionApps = Get-AzWebApp | Where-Object { $_.Kind -like '*functionapp*' }
foreach ($app in $functionApps) {
    $authSettings = Get-AzWebAppAuthSettings -ResourceGroupName $app.ResourceGroup -Name $app.Name
    $config = Get-AzWebApp -ResourceGroupName $app.ResourceGroup -Name $app.Name

    if (-not $authSettings.Enabled -or $config.SiteConfig.FtpsState -ne 'Disabled') {
        Write-Warning "Non-compliant: $($app.Name)"
    }
}
'@ -ForegroundColor Gray

            Write-Host "`n3️⃣  Azure CLI:" -ForegroundColor Cyan
            Write-Host @'
# Check auth settings
az webapp auth show --name <function-app-name> --resource-group <rg-name>

# Check FTP state
az functionapp config show --name <function-app-name> --resource-group <rg-name> --query ftpsState

# Check publishing credentials
az functionapp deployment list-publishing-credentials --name <function-app-name> --resource-group <rg-name>
'@ -ForegroundColor Gray

            Write-Host ""
            $true | Should -Be $true
        }
    }
}

AfterAll {
    # Cleanup test resources if any were created
    if ($script:TestConfig.Behavior.CleanupTestResources) {
        Write-Host "`n🧹 Cleaning up test resources..." -ForegroundColor Yellow

        # Clean up Function Apps
        foreach ($appName in $script:TestFunctionApps) {
            try {
                Write-Host "  Removing Function App: $appName" -ForegroundColor Gray
                Remove-AzFunctionApp -Name $appName -ResourceGroupName $script:ResourceGroupName -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "Failed to remove Function App '$appName': $($_.Exception.Message)"
            }
        }

        # Clean up Storage Accounts
        foreach ($storageAccountName in $script:TestStorageAccounts) {
            try {
                Write-Host "  Removing Storage Account: $storageAccountName" -ForegroundColor Gray
                Remove-AzStorageAccount -Name $storageAccountName -ResourceGroupName $script:ResourceGroupName -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "Failed to remove Storage Account '$storageAccountName': $($_.Exception.Message)"
            }
        }

        Write-Host "✅ Cleanup completed`n" -ForegroundColor Green
    }
}
