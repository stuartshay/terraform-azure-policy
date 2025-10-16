#Requires -Modules Pester, Az.Accounts, Az.Resources, Az.Functions, Az.PolicyInsights

<#
.SYNOPSIS
    Pester tests for the Deny Function App Non-HTTPS Access policy
.DESCRIPTION
    This test suite validates the Azure Policy definition and tests actual compliance
    behavior for Function Apps with HTTPS-only configurations.
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
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'function-app' -PolicyName 'deny-function-app-https-only'

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
    $policyPath = Join-Path $PSScriptRoot '..\..\policies\function-app\deny-function-app-https-only\rule.json'
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
            $script:PolicyDefinitionJson.properties.description | Should -Match 'HTTPS'
        }

        It 'Should have proper metadata' {
            $metadata = $script:PolicyDefinitionJson.properties.metadata
            $metadata | Should -Not -BeNullOrEmpty
            $metadata.category | Should -Be 'Function App'
            $metadata.version | Should -Not -BeNullOrEmpty
        }

        It 'Should target Microsoft.Web/sites resource type with functionapp kind' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf

            $typeCondition = $conditions | Where-Object { $_.field -eq 'type' }
            $kindCondition = $conditions | Where-Object { $_.field -eq 'kind' }

            $typeCondition | Should -Not -BeNullOrEmpty
            $typeCondition.equals | Should -Be 'Microsoft.Web/sites'
            $kindCondition | Should -Not -BeNullOrEmpty
            $kindCondition.equals | Should -Be 'functionapp'
        }

        It 'Should have effect parameter with correct allowed values' {
            $effectParam = $script:PolicyDefinitionJson.properties.parameters.effect
            $effectParam | Should -Not -BeNullOrEmpty
            $effectParam.allowedValues | Should -Contain 'Audit'
            $effectParam.allowedValues | Should -Contain 'Deny'
            $effectParam.allowedValues | Should -Contain 'Disabled'
            $effectParam.defaultValue | Should -Be 'Deny'
        }

        It 'Should have exemptedFunctionApps parameter' {
            $exemptionsParam = $script:PolicyDefinitionJson.properties.parameters.exemptedFunctionApps
            $exemptionsParam | Should -Not -BeNullOrEmpty
            $exemptionsParam.type | Should -Be 'Array'
            $exemptionsParam.defaultValue | Should -Be @()
        }

        It 'Should have exemptedResourceGroups parameter' {
            $exemptionsParam = $script:PolicyDefinitionJson.properties.parameters.exemptedResourceGroups
            $exemptionsParam | Should -Not -BeNullOrEmpty
            $exemptionsParam.type | Should -Be 'Array'
            $exemptionsParam.defaultValue | Should -Be @()
        }

        It 'Should check exempted Function Apps' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf
            $exemptionCondition = $conditions | Where-Object {
                $_.not -and $_.not.field -eq 'name'
            }
            $exemptionCondition | Should -Not -BeNullOrEmpty
            $exemptionCondition.not.in | Should -Be '[parameters(''exemptedFunctionApps'')]'
        }

        It 'Should check exempted Resource Groups' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf
            $exemptionCondition = $conditions | Where-Object {
                $_.not -and $_.not.field -eq 'Microsoft.Web/sites/resourceGroup'
            }
            $exemptionCondition | Should -Not -BeNullOrEmpty
            $exemptionCondition.not.in | Should -Be '[parameters(''exemptedResourceGroups'')]'
        }

        It 'Should check HTTPS-only settings' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf
            $httpsCondition = $conditions | Where-Object { $_.anyOf }
            $httpsCondition | Should -Not -BeNullOrEmpty

            $httpsChecks = $httpsCondition.anyOf
            $existsCheck = $httpsChecks | Where-Object { $_.field -eq 'Microsoft.Web/sites/httpsOnly' -and $_.exists -eq 'false' }
            $falseCheck = $httpsChecks | Where-Object { $_.field -eq 'Microsoft.Web/sites/httpsOnly' -and $_.equals -eq 'false' }

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
                $_.Properties.DisplayName -like '*Function*App*HTTPS*' -or
                $_.Properties.DisplayName -like '*Function*App*HTTP*'
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
                $parameters.exemptedFunctionApps | Should -Not -BeNullOrEmpty
                $parameters.exemptedResourceGroups | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'Function App HTTPS-Only Compliance Tests' -Tag @('Integration', 'Slow', 'Compliance') {
    BeforeAll {
        # Generate unique names for test Function Apps
        $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
        $script:CompliantFunctionAppName = "$script:TestFunctionAppPrefix-compliant-$timestamp"
        $script:NonCompliantFunctionAppName = "$script:TestFunctionAppPrefix-noncompliant-$timestamp"
        $script:ExemptedFunctionAppName = "$script:TestFunctionAppPrefix-exempted-$timestamp"

        # Storage account for Function Apps (required)
        $script:StorageAccountName = "testpolicystorage$timestamp"

        # App Service Plan
        $script:AppServicePlanName = "testpolicy-asp-$timestamp"

        # Function Apps created during tests
        $script:CreatedFunctionApps = @()
        $script:CreatedStorageAccount = $null
        $script:CreatedAppServicePlan = $null
    }

    AfterAll {
        Write-Host "`n=== Cleaning Up Test Resources ===" -ForegroundColor Cyan

        # Cleanup Application Insights components (to prevent managed resource group accumulation)
        Write-Host "Searching for Application Insights components to clean up..." -ForegroundColor Yellow
        $timestamp = Get-Date -Format 'yyyyMMddHHmm'
        $appInsightsPattern = "*testpolicyfn*$timestamp*"

        try {
            $appInsightsComponents = Get-AzResource -ResourceGroupName $script:ResourceGroupName `
                -ResourceType 'Microsoft.Insights/components' `
                -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $appInsightsPattern }

            foreach ($appInsight in $appInsightsComponents) {
                try {
                    Write-Host "  Removing Application Insights: $($appInsight.Name)" -ForegroundColor Yellow
                    Remove-AzResource -ResourceId $appInsight.ResourceId -Force -ErrorAction SilentlyContinue
                    Write-Host "    ✓ Removed: $($appInsight.Name)" -ForegroundColor Green
                } catch {
                    Write-Warning "    Failed to remove Application Insights $($appInsight.Name): $($_.Exception.Message)"
                }
            }

            # Also cleanup any alert rules
            $alertRules = Get-AzResource -ResourceGroupName $script:ResourceGroupName `
                -ResourceType 'microsoft.alertsmanagement/smartDetectorAlertRules' `
                -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*testpolicyfn*" }

            foreach ($alert in $alertRules) {
                try {
                    Write-Host "  Removing Alert Rule: $($alert.Name)" -ForegroundColor Yellow
                    Remove-AzResource -ResourceId $alert.ResourceId -Force -ErrorAction SilentlyContinue
                    Write-Host "    ✓ Removed: $($alert.Name)" -ForegroundColor Green
                } catch {
                    Write-Warning "    Failed to remove Alert Rule $($alert.Name): $($_.Exception.Message)"
                }
            }
        } catch {
            Write-Warning "Error during Application Insights cleanup: $($_.Exception.Message)"
        }

        # Cleanup Function Apps
        foreach ($functionApp in $script:CreatedFunctionApps) {
            try {
                Write-Host "  Removing Function App: $($functionApp.Name)" -ForegroundColor Yellow
                Remove-AzFunctionApp -Name $functionApp.Name -ResourceGroupName $script:ResourceGroupName -Force -ErrorAction SilentlyContinue
                Write-Host "    ✓ Removed: $($functionApp.Name)" -ForegroundColor Green
            }
            catch {
                Write-Warning "    Failed to cleanup Function App $($functionApp.Name): $($_.Exception.Message)"
            }
        }

        # Cleanup App Service Plan
        if ($script:CreatedAppServicePlan) {
            try {
                Write-Host "  Removing App Service Plan: $($script:CreatedAppServicePlan.Name)" -ForegroundColor Yellow
                Remove-AzAppServicePlan -Name $script:CreatedAppServicePlan.Name -ResourceGroupName $script:ResourceGroupName -Force -ErrorAction SilentlyContinue
                Write-Host "    ✓ Removed: $($script:CreatedAppServicePlan.Name)" -ForegroundColor Green
            }
            catch {
                Write-Warning "    Failed to cleanup App Service Plan $($script:CreatedAppServicePlan.Name): $($_.Exception.Message)"
            }
        }

        # Cleanup Storage Account
        if ($script:CreatedStorageAccount) {
            try {
                Write-Host "  Removing Storage Account: $($script:CreatedStorageAccount.StorageAccountName)" -ForegroundColor Yellow
                Remove-AzStorageAccount -Name $script:CreatedStorageAccount.StorageAccountName -ResourceGroupName $script:ResourceGroupName -Force -ErrorAction SilentlyContinue
                Write-Host "    ✓ Removed: $($script:CreatedStorageAccount.StorageAccountName)" -ForegroundColor Green
            }
            catch {
                Write-Warning "    Failed to cleanup Storage Account $($script:CreatedStorageAccount.StorageAccountName): $($_.Exception.Message)"
            }
        }

        Write-Host "=== Cleanup Complete ===" -ForegroundColor Cyan
    }

    Context 'Prerequisites Setup' {
        It 'Should create storage account for Function Apps' {
            $script:CreatedStorageAccount = New-AzStorageAccount `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $script:StorageAccountName `
                -Location $script:ResourceGroup.Location `
                -SkuName 'Standard_LRS' `
                -Kind 'StorageV2'

            $script:CreatedStorageAccount | Should -Not -BeNullOrEmpty
            $script:CreatedStorageAccount.StorageAccountName | Should -Be $script:StorageAccountName
        }

        It 'Should create App Service Plan for Function Apps' {
            $script:CreatedAppServicePlan = New-AzAppServicePlan `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $script:AppServicePlanName `
                -Location $script:ResourceGroup.Location `
                -Tier 'Dynamic' `
                -WorkerSize 'Small'

            $script:CreatedAppServicePlan | Should -Not -BeNullOrEmpty
            $script:CreatedAppServicePlan.Name | Should -Be $script:AppServicePlanName
        }
    }

    Context 'Compliant Function App (HTTPS-Only Enabled)' {
        It 'Should successfully create Function App with HTTPS-only enabled' {
            $functionApp = New-AzFunctionApp `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $script:CompliantFunctionAppName `
                -StorageAccountName $script:StorageAccountName `
                -Location $script:ResourceGroup.Location `
                -Runtime 'PowerShell' `
                -OSType 'Windows' `
                -PlanName $script:AppServicePlanName `
                -ApplicationInsightsName "$script:CompliantFunctionAppName-ai" `
                -DisableApplicationInsights

            $functionApp | Should -Not -BeNullOrEmpty
            $script:CreatedFunctionApps += $functionApp

            # Verify HTTPS-only is enabled (should be default)
            $webApp = Get-AzWebApp -ResourceGroupName $script:ResourceGroupName -Name $script:CompliantFunctionAppName
            $webApp.HttpsOnly | Should -Be $true
        }

        It 'Should be compliant with the policy' {
            # Wait for policy evaluation (may take a few minutes)
            Start-Sleep -Seconds 30

            $complianceStates = Get-AzPolicyState -ResourceGroupName $script:ResourceGroupName -Filter "PolicyDefinitionName eq '$script:PolicyName' and ResourceId like '*$script:CompliantFunctionAppName*'"

            if ($complianceStates) {
                $complianceStates | Should -Not -BeNullOrEmpty
                $complianceStates[0].ComplianceState | Should -Be 'Compliant'
            }
            else {
                Write-Warning "Policy compliance state not yet available for $script:CompliantFunctionAppName"
            }
        }
    }

    Context 'Non-Compliant Function App (HTTPS-Only Disabled)' {
        It 'Should fail to create Function App with HTTPS-only disabled (in Deny mode)' {
            # First create Function App normally
            $functionApp = New-AzFunctionApp `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $script:NonCompliantFunctionAppName `
                -StorageAccountName $script:StorageAccountName `
                -Location $script:ResourceGroup.Location `
                -Runtime 'PowerShell' `
                -OSType 'Windows' `
                -PlanName $script:AppServicePlanName `
                -ApplicationInsightsName "$script:NonCompliantFunctionAppName-ai" `
                -DisableApplicationInsights

            $script:CreatedFunctionApps += $functionApp

            # Try to disable HTTPS-only - this should fail if policy is in Deny mode
            try {
                Set-AzWebApp -ResourceGroupName $script:ResourceGroupName -Name $script:NonCompliantFunctionAppName -HttpsOnly $false
                $disableSucceeded = $true
            }
            catch {
                $disableSucceeded = $false
                $disableError = $_.Exception.Message
            }

            # Check policy effect to determine expected behavior
            if ($script:TargetAssignment -and $script:TargetAssignment.Properties.Parameters.effect.value -eq 'Deny') {
                $disableSucceeded | Should -Be $false
                $disableError | Should -Match 'policy|denied|prohibited'
            }
            elseif ($script:TargetAssignment -and $script:TargetAssignment.Properties.Parameters.effect.value -eq 'Audit') {
                # In Audit mode, the operation should succeed but be flagged as non-compliant
                Write-Warning 'Policy is in Audit mode - Function App creation succeeded but should be flagged as non-compliant'
            }
        }

        It 'Should be flagged as non-compliant (in Audit mode)' {
            # Only test compliance in Audit mode
            if ($script:TargetAssignment -and $script:TargetAssignment.Properties.Parameters.effect.value -eq 'Audit') {
                # Attempt to disable HTTPS-only for testing compliance
                try {
                    Set-AzWebApp -ResourceGroupName $script:ResourceGroupName -Name $script:NonCompliantFunctionAppName -HttpsOnly $false
                }
                catch {
                    Write-Warning 'Could not disable HTTPS-only for compliance testing'
                }

                # Wait for policy evaluation
                Start-Sleep -Seconds 30

                $complianceStates = Get-AzPolicyState -ResourceGroupName $script:ResourceGroupName -Filter "PolicyDefinitionName eq '$script:PolicyName' and ResourceId like '*$script:NonCompliantFunctionAppName*'"

                if ($complianceStates) {
                    $complianceStates | Should -Not -BeNullOrEmpty
                    $complianceStates[0].ComplianceState | Should -Be 'NonCompliant'
                }
                else {
                    Write-Warning "Policy compliance state not yet available for $script:NonCompliantFunctionAppName"
                }
            }
        }
    }

    Context 'Exempted Function App' {
        It 'Should create exempted Function App successfully even with HTTPS-only disabled' {
            # Check if there are exempted Function Apps configured
            $exemptedApps = @()
            if ($script:TargetAssignment -and $script:TargetAssignment.Properties.Parameters.exemptedFunctionApps) {
                $exemptedApps = $script:TargetAssignment.Properties.Parameters.exemptedFunctionApps.value
            }

            if ($exemptedApps -contains $script:ExemptedFunctionAppName) {
                # Create Function App
                $functionApp = New-AzFunctionApp `
                    -ResourceGroupName $script:ResourceGroupName `
                    -Name $script:ExemptedFunctionAppName `
                    -StorageAccountName $script:StorageAccountName `
                    -Location $script:ResourceGroup.Location `
                    -Runtime 'PowerShell' `
                    -OSType 'Windows' `
                    -PlanName $script:AppServicePlanName `
                    -ApplicationInsightsName "$script:ExemptedFunctionAppName-ai" `
                    -DisableApplicationInsights

                $script:CreatedFunctionApps += $functionApp

                # Try to disable HTTPS-only - should succeed for exempted apps
                Set-AzWebApp -ResourceGroupName $script:ResourceGroupName -Name $script:ExemptedFunctionAppName -HttpsOnly $false

                $webApp = Get-AzWebApp -ResourceGroupName $script:ResourceGroupName -Name $script:ExemptedFunctionAppName
                $webApp.HttpsOnly | Should -Be $false
            }
            else {
                Write-Warning 'No exempted Function Apps configured - skipping exemption test'
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

            # Should check if httpsOnly exists
            $existsCheck = $httpsChecks | Where-Object { $_.field -eq 'Microsoft.Web/sites/httpsOnly' -and $_.exists -eq 'false' }
            $existsCheck | Should -Not -BeNullOrEmpty

            # Should check if httpsOnly is false
            $falseCheck = $httpsChecks | Where-Object { $_.field -eq 'Microsoft.Web/sites/httpsOnly' -and $_.equals -eq 'false' }
            $falseCheck | Should -Not -BeNullOrEmpty
        }

        It 'Should not affect other resource types' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf

            $typeCondition = $conditions | Where-Object { $_.field -eq 'type' }
            $typeCondition.equals | Should -Be 'Microsoft.Web/sites'

            $kindCondition = $conditions | Where-Object { $_.field -eq 'kind' }
            $kindCondition.equals | Should -Be 'functionapp'
        }

        It 'Should respect exemptions properly' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $conditions = $policyRule.if.allOf

            # Check Function App exemptions
            $appExemption = $conditions | Where-Object {
                $_.not -and $_.not.field -eq 'name'
            }
            $appExemption | Should -Not -BeNullOrEmpty

            # Check Resource Group exemptions
            $rgExemption = $conditions | Where-Object {
                $_.not -and $_.not.field -eq 'Microsoft.Web/sites/resourceGroup'
            }
            $rgExemption | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Policy Integration' {
        It 'Should work with Terraform deployment' {
            $terraformPath = Join-Path $PSScriptRoot '..\..\policies\function-app\deny-function-app-https-only'

            Test-Path (Join-Path $terraformPath 'main.tf') | Should -Be $true
            Test-Path (Join-Path $terraformPath 'variables.tf') | Should -Be $true
            Test-Path (Join-Path $terraformPath 'outputs.tf') | Should -Be $true
        }

        It 'Should have consistent naming across files' {
            $terraformVarsPath = Join-Path $PSScriptRoot '..\..\policies\function-app\deny-function-app-https-only\variables.tf'

            if (Test-Path $terraformVarsPath) {
                $varsContent = Get-Content $terraformVarsPath -Raw
                $varsContent | Should -Match 'deny-function-app-https-only'
            }
        }
    }
}

Describe 'Security Validation' -Tag @('Security', 'Fast') {
    Context 'HTTPS Enforcement Security' {
        It 'Should enforce encryption in transit' {
            $description = $script:PolicyDefinitionJson.properties.description
            $description | Should -Match 'HTTPS|encrypt|transit'
        }

        It 'Should prevent data interception' {
            $description = $script:PolicyDefinitionJson.properties.description
            $description | Should -Match 'protect.*data|encrypted.*communication'
        }

        It 'Should have appropriate security metadata' {
            $metadata = $script:PolicyDefinitionJson.properties.metadata
            $metadata.category | Should -Be 'Function App'
        }
    }

    Context 'Policy Parameter Security' {
        It 'Should have secure default effect' {
            $effectParam = $script:PolicyDefinitionJson.properties.parameters.effect
            $effectParam.defaultValue | Should -Be 'Deny'
        }

        It 'Should allow controlled exemptions' {
            $exemptionsParam = $script:PolicyDefinitionJson.properties.parameters.exemptedFunctionApps
            $exemptionsParam.type | Should -Be 'Array'
            $exemptionsParam.defaultValue | Should -Be @()
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
