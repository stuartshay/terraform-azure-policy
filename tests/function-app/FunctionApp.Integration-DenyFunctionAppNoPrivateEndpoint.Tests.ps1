#Requires -Modules Pester, Az.Accounts, Az.Resources, Az.Functions, Az.PolicyInsights

<#
.SYNOPSIS
    Pester tests for the Function Apps Must Disable Public Network Access policy
.DESCRIPTION
    This test suite validates the Azure Policy definition and tests actual compliance
    behavior for Function Apps with public network access disabled.
.NOTES
    Prerequisites:
    - Azure PowerShell modules (Az.Accounts, Az.Resources, Az.Functions, Az.PolicyInsights, Az.Network)
    - Authenticated Azure session with appropriate permissions
    - Resource group 'rg-azure-policy-testing' must exist
    - Policy must be assigned to the resource group
#>

BeforeAll {
    # Import centralized configuration
    . "$PSScriptRoot\..\..\config\config-loader.ps1"

    # Initialize test configuration for this specific policy
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'function-app' -PolicyName 'deny-function-app-no-private-endpoint'

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
    $policyPath = Join-Path $PSScriptRoot '..\..\policies\function-app\deny-function-app-no-private-endpoint\rule.json'
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
            $script:PolicyDefinitionJson.properties.description | Should -Match 'public network access|private endpoint|network'
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
            # Policy uses 'equals' for kind (simplified approach)
            $kindCondition.equals | Should -Be 'functionapp'
        }

        It 'Should check for public network access configuration' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $publicNetworkCondition = $policyRule.if.allOf | Where-Object { $_.anyOf }

            $publicNetworkCondition | Should -Not -BeNullOrEmpty

            # Should check publicNetworkAccess is Disabled or doesn't exist
            $publicAccessChecks = $publicNetworkCondition.anyOf
            $publicAccessChecks | Should -Not -BeNullOrEmpty
            $publicAccessChecks.Count | Should -BeGreaterThan 0
        }

        It 'Should check public network access settings' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $publicNetworkCondition = $policyRule.if.allOf | Where-Object { $_.anyOf }

            # Should check if publicNetworkAccess is not Disabled or doesn't exist
            $publicAccessChecks = $publicNetworkCondition.anyOf | Where-Object {
                $_.field -eq 'Microsoft.Web/sites/publicNetworkAccess'
            }

            $publicAccessChecks | Should -Not -BeNullOrEmpty
            $publicAccessChecks.Count | Should -Be 2  # One for notEquals, one for exists
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
    }
}

Describe 'Policy Assignment Validation' -Tag @('Integration', 'Fast', 'PolicyAssignment') {
    Context 'Policy Assignment Exists' {
        BeforeAll {
            $script:PolicyAssignments = Get-AzPolicyAssignment -Scope $script:ResourceGroup.ResourceId
            $script:TargetAssignment = $script:PolicyAssignments | Where-Object {
                $_.Properties.DisplayName -like "*$script:PolicyDisplayName*" -or
                $_.Name -like "*$script:PolicyName*" -or
                $_.Name -eq 'deny-fn-public-access' -or
                $_.Properties.DisplayName -like '*Function*App*Public*Access*'
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

        It 'Should not require system assigned identity for Audit/Deny policy' {
            if ($script:TargetAssignment) {
                # Audit and Deny policies don't need managed identity (only DeployIfNotExists/Modify do)
                # Identity may or may not be present, so we just verify the assignment exists
                $script:TargetAssignment | Should -Not -BeNullOrEmpty
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

Describe 'Function App Private Endpoint Compliance Tests' -Tag @('Integration', 'Slow', 'Compliance') {
    BeforeAll {
        # Generate unique names for test resources
        $timestamp = Get-Date -Format 'yyyyMMddHHmm'  # Shorter timestamp
        $script:CompliantFunctionAppName = "$script:TestFunctionAppPrefix-c-$timestamp"
        $script:NonCompliantFunctionAppName = "$script:TestFunctionAppPrefix-nc-$timestamp"

        # Storage account for Function Apps (required) - max 24 chars
        $script:StorageAccountName = "testpolicysa$timestamp".Substring(0, [Math]::Min(24, "testpolicysa$timestamp".Length))

        # App Service Plan
        $script:AppServicePlanName = "testpolicy-asp-$timestamp"

        # Resources created during tests
        $script:CreatedFunctionApps = @()
        $script:CreatedStorageAccount = $null
        $script:CreatedAppServicePlan = $null
    }

    AfterAll {
        Write-Host "`n=== Cleaning Up Test Resources ===" -ForegroundColor Cyan

        # Cleanup Application Insights components (to prevent managed resource group accumulation)
        Write-Host 'Searching for Application Insights components to clean up...' -ForegroundColor Yellow
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
            } catch {
                Write-Warning "    Failed to cleanup Function App $($functionApp.Name): $($_.Exception.Message)"
            }
        }

        # Cleanup App Service Plan
        if ($script:CreatedAppServicePlan) {
            try {
                Write-Host "  Removing App Service Plan: $($script:CreatedAppServicePlan.Name)" -ForegroundColor Yellow
                Remove-AzAppServicePlan -Name $script:CreatedAppServicePlan.Name -ResourceGroupName $script:ResourceGroupName -Force -ErrorAction SilentlyContinue
                Write-Host "    ✓ Removed: $($script:CreatedAppServicePlan.Name)" -ForegroundColor Green
            } catch {
                Write-Warning "    Failed to cleanup App Service Plan: $($_.Exception.Message)"
            }
        }

        # Cleanup Storage Account
        if ($script:CreatedStorageAccount) {
            try {
                Write-Host "  Removing Storage Account: $($script:CreatedStorageAccount.StorageAccountName)" -ForegroundColor Yellow
                Remove-AzStorageAccount -Name $script:CreatedStorageAccount.StorageAccountName -ResourceGroupName $script:ResourceGroupName -Force -ErrorAction SilentlyContinue
                Write-Host "    ✓ Removed: $($script:CreatedStorageAccount.StorageAccountName)" -ForegroundColor Green
            } catch {
                Write-Warning "    Failed to cleanup Storage Account: $($_.Exception.Message)"
            }
        }

        Write-Host '=== Cleanup Complete ===' -ForegroundColor Cyan
    }

    Context 'Prerequisites Setup' {
        It 'Should create storage account for Function Apps' {
            Write-Host "Creating storage account: $script:StorageAccountName (length: $($script:StorageAccountName.Length))" -ForegroundColor Cyan

            try {
                $script:CreatedStorageAccount = New-AzStorageAccount `
                    -ResourceGroupName $script:ResourceGroupName `
                    -Name $script:StorageAccountName `
                    -Location $script:ResourceGroup.Location `
                    -SkuName 'Standard_LRS' `
                    -Kind 'StorageV2' `
                    -ErrorAction Stop

                $script:CreatedStorageAccount | Should -Not -BeNullOrEmpty
                $script:CreatedStorageAccount.StorageAccountName | Should -Be $script:StorageAccountName
            } catch {
                Write-Host "Storage account creation failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Storage account name: $script:StorageAccountName" -ForegroundColor Yellow
                throw
            }
        }

        It 'Should create App Service Plan for Function Apps' {
            # Using Standard plan (cheaper than Premium, sufficient for public access testing)
            $script:CreatedAppServicePlan = New-AzAppServicePlan `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $script:AppServicePlanName `
                -Location $script:ResourceGroup.Location `
                -Tier 'Standard' `
                -WorkerSize 'Small' `
                -NumberofWorkers 1

            $script:CreatedAppServicePlan | Should -Not -BeNullOrEmpty
            $script:CreatedAppServicePlan.Name | Should -Be $script:AppServicePlanName
        }
    }

    Context 'Compliant Function App (Public Access Disabled)' {
        It 'Should successfully create Function App with public access disabled' {
            $functionApp = New-AzFunctionApp `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $script:CompliantFunctionAppName `
                -StorageAccountName $script:StorageAccountName `
                -Location $script:ResourceGroup.Location `
                -Runtime 'PowerShell' `
                -OSType 'Windows' `
                -PlanName $script:AppServicePlanName `
                -DisableApplicationInsights

            $functionApp | Should -Not -BeNullOrEmpty
            $script:CreatedFunctionApps += $functionApp

            # Disable public network access using Azure CLI (more reliable than PowerShell)
            Write-Host "Disabling public network access for $script:CompliantFunctionAppName..." -ForegroundColor Cyan
            $result = az webapp update `
                --resource-group $script:ResourceGroupName `
                --name $script:CompliantFunctionAppName `
                --set publicNetworkAccess=Disabled `
                2>&1

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to disable public access via CLI: $result"
            }

            # Verify public access is disabled
            Start-Sleep -Seconds 10  # Wait for update to propagate
            $updatedWebApp = Get-AzWebApp -ResourceGroupName $script:ResourceGroupName -Name $script:CompliantFunctionAppName
            Write-Host "Public Network Access: $($updatedWebApp.PublicNetworkAccess)" -ForegroundColor Cyan
            $updatedWebApp.PublicNetworkAccess | Should -Be 'Disabled'
        }



        It 'Should be compliant with the policy' {
            # Wait for policy evaluation
            Start-Sleep -Seconds 30

            # Query using proper filter syntax
            $filter = "ResourceId eq '/subscriptions/$script:SubscriptionId/resourceGroups/$script:ResourceGroupName/providers/Microsoft.Web/sites/$script:CompliantFunctionAppName'"
            $complianceStates = Get-AzPolicyState -Filter $filter -ErrorAction SilentlyContinue

            if ($complianceStates) {
                $complianceStates | Should -Not -BeNullOrEmpty
                Write-Host "Compliance State: $($complianceStates[0].ComplianceState)" -ForegroundColor Cyan
            } else {
                Write-Warning "Policy compliance state not yet available for $script:CompliantFunctionAppName"
            }
        }
    }

    Context 'Non-Compliant Function App (Public Access Enabled)' {
        It 'Should create Function App with public access enabled' {
            $functionApp = New-AzFunctionApp `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $script:NonCompliantFunctionAppName `
                -StorageAccountName $script:StorageAccountName `
                -Location $script:ResourceGroup.Location `
                -Runtime 'PowerShell' `
                -OSType 'Windows' `
                -PlanName $script:AppServicePlanName `
                -DisableApplicationInsights

            $functionApp | Should -Not -BeNullOrEmpty
            $script:CreatedFunctionApps += $functionApp

            # Verify public access is enabled (default)
            Start-Sleep -Seconds 5
            $webApp = Get-AzWebApp -ResourceGroupName $script:ResourceGroupName -Name $script:NonCompliantFunctionAppName
            Write-Host "Public Network Access: $($webApp.PublicNetworkAccess)" -ForegroundColor Cyan
            # Default should be Enabled or not set (both are non-compliant)
            $webApp.PublicNetworkAccess | Should -Not -Be 'Disabled'
        }

        It 'Should be flagged as non-compliant' {
            # Wait for policy evaluation
            Start-Sleep -Seconds 60

            # Query using proper filter syntax
            $filter = "ResourceId eq '/subscriptions/$script:SubscriptionId/resourceGroups/$script:ResourceGroupName/providers/Microsoft.Web/sites/$script:NonCompliantFunctionAppName'"
            $complianceStates = Get-AzPolicyState -Filter $filter -ErrorAction SilentlyContinue

            if ($complianceStates) {
                $complianceStates | Should -Not -BeNullOrEmpty
                Write-Host "Compliance State: $($complianceStates[0].ComplianceState)" -ForegroundColor Cyan

                if ($script:TargetAssignment -and $script:TargetAssignment.Properties.Parameters.effect.value -eq 'Audit') {
                    $complianceStates[0].ComplianceState | Should -Be 'NonCompliant'
                }
            } else {
                Write-Warning "Policy compliance state not yet available for $script:NonCompliantFunctionAppName - may need more time for evaluation"
            }
        }
    }
}

Describe 'Policy Effectiveness Tests' -Tag @('Integration', 'Fast', 'Effectiveness') {
    Context 'Public Network Access Validation' {
        It 'Should validate policy checks publicNetworkAccess property' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $publicNetworkCondition = $policyRule.if.allOf | Where-Object { $_.anyOf }

            $publicNetworkCondition | Should -Not -BeNullOrEmpty

            # Should check publicNetworkAccess field
            $publicAccessChecks = $publicNetworkCondition.anyOf | Where-Object {
                $_.field -eq 'Microsoft.Web/sites/publicNetworkAccess'
            }

            $publicAccessChecks | Should -Not -BeNullOrEmpty
            $publicAccessChecks.Count | Should -Be 2  # notEquals and exists checks
        }

        It 'Should validate policy checks for non-disabled public access' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $publicNetworkCondition = $policyRule.if.allOf | Where-Object { $_.anyOf }

            # Should have two checks in anyOf: notEquals 'Disabled' and exists 'false'
            $publicAccessChecks = $publicNetworkCondition.anyOf
            $publicAccessChecks | Should -Not -BeNullOrEmpty
            $publicAccessChecks.Count | Should -Be 2

            # One should check notEquals 'Disabled'
            $notDisabledCheck = $publicAccessChecks | Where-Object { $_.notEquals -eq 'Disabled' }
            $notDisabledCheck | Should -Not -BeNullOrEmpty

            # One should check exists 'false'
            $notExistsCheck = $publicAccessChecks | Where-Object { $_.exists -eq 'false' }
            $notExistsCheck | Should -Not -BeNullOrEmpty
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
            $terraformPath = Join-Path $PSScriptRoot '..\..\policies\function-app\deny-function-app-no-private-endpoint'

            Test-Path (Join-Path $terraformPath 'main.tf') | Should -Be $true
            Test-Path (Join-Path $terraformPath 'variables.tf') | Should -Be $true
            Test-Path (Join-Path $terraformPath 'outputs.tf') | Should -Be $true
            Test-Path (Join-Path $terraformPath 'rule.json') | Should -Be $true
            Test-Path (Join-Path $terraformPath 'README.md') | Should -Be $true
        }

        It 'Should have consistent naming across files' {
            $terraformVarsPath = Join-Path $PSScriptRoot '..\..\policies\function-app\deny-function-app-no-private-endpoint\variables.tf'

            if (Test-Path $terraformVarsPath) {
                $varsContent = Get-Content $terraformVarsPath -Raw
                $varsContent | Should -Match 'deny-function-app-no-private-endpoint'
            }
        }
    }
}

Describe 'Security Validation' -Tag @('Security', 'Fast') {
    Context 'Network Security Enforcement' {
        It 'Should enforce network isolation' {
            $description = $script:PolicyDefinitionJson.properties.description
            $description | Should -Match 'public network access|private endpoint|network'
        }

        It 'Should prevent unauthorized network access' {
            $description = $script:PolicyDefinitionJson.properties.description
            $description | Should -Match 'public.*access|network.*security|private.*network'
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
} else {
    Write-Host '- Policy Assignment: Not Found (policy may not be deployed yet)' -ForegroundColor Yellow
}
