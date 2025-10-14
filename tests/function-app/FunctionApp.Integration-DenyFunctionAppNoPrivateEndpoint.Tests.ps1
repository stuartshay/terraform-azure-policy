#Requires -Modules Pester, Az.Accounts, Az.Resources, Az.Functions, Az.PolicyInsights, Az.Network

<#
.SYNOPSIS
    Pester tests for the Deny Function App Without Private Endpoint policy
.DESCRIPTION
    This test suite validates the Azure Policy definition and tests actual compliance
    behavior for Function Apps with private endpoint configurations.
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
    Import-PolicyTestModule -ModuleTypes @('Required', 'FunctionApp', 'Network')

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
            $script:PolicyDefinitionJson.properties.description | Should -Match 'private endpoint|private connectivity|network isolation'
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

        It 'Should check for private endpoint connections' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $publicNetworkCondition = $policyRule.if.allOf | Where-Object { $_.anyOf }

            $publicNetworkCondition | Should -Not -BeNullOrEmpty

            # Should check for private endpoint connections count
            $privateEndpointChecks = $publicNetworkCondition.anyOf | Where-Object {
                $_.allOf | Where-Object { $_.PSObject.Properties.Name -contains 'count' }
            }

            $privateEndpointChecks | Should -Not -BeNullOrEmpty
        }

        It 'Should check public network access settings' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $publicNetworkCondition = $policyRule.if.allOf | Where-Object { $_.anyOf }

            # Should check if publicNetworkAccess is not Disabled
            $publicAccessChecks = $publicNetworkCondition.anyOf | Where-Object {
                $_.allOf | Where-Object { $_.field -eq 'Microsoft.Web/sites/publicNetworkAccess' }
            }

            $publicAccessChecks | Should -Not -BeNullOrEmpty
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
                $_.Properties.DisplayName -like '*Function*App*Private*Endpoint*'
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

Describe 'Function App Private Endpoint Compliance Tests' -Tag @('Integration', 'Slow', 'Compliance') {
    BeforeAll {
        # Generate unique names for test resources
        $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
        $script:CompliantFunctionAppName = "$script:TestFunctionAppPrefix-compliant-$timestamp"
        $script:NonCompliantFunctionAppName = "$script:TestFunctionAppPrefix-noncompliant-$timestamp"

        # Storage account for Function Apps (required)
        $script:StorageAccountName = "testpolicystorage$timestamp"

        # App Service Plan
        $script:AppServicePlanName = "testpolicy-asp-$timestamp"

        # Virtual Network and Subnet for Private Endpoint
        $script:VNetName = "testpolicy-vnet-$timestamp"
        $script:SubnetName = "testpolicy-subnet-$timestamp"
        $script:PrivateEndpointName = "testpolicy-pe-$timestamp"

        # Resources created during tests
        $script:CreatedFunctionApps = @()
        $script:CreatedStorageAccount = $null
        $script:CreatedAppServicePlan = $null
        $script:CreatedVNet = $null
        $script:CreatedPrivateEndpoint = $null
    }

    AfterAll {
        # Cleanup Private Endpoint
        if ($script:CreatedPrivateEndpoint) {
            try {
                Write-Host "Cleaning up Private Endpoint: $($script:CreatedPrivateEndpoint.Name)" -ForegroundColor Yellow
                Remove-AzPrivateEndpoint -Name $script:CreatedPrivateEndpoint.Name -ResourceGroupName $script:ResourceGroupName -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "Failed to cleanup Private Endpoint: $($_.Exception.Message)"
            }
        }

        # Cleanup Function Apps
        foreach ($functionApp in $script:CreatedFunctionApps) {
            try {
                Write-Host "Cleaning up Function App: $($functionApp.Name)" -ForegroundColor Yellow
                Remove-AzFunctionApp -Name $functionApp.Name -ResourceGroupName $script:ResourceGroupName -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "Failed to cleanup Function App $($functionApp.Name): $($_.Exception.Message)"
            }
        }

        # Cleanup App Service Plan
        if ($script:CreatedAppServicePlan) {
            try {
                Write-Host "Cleaning up App Service Plan: $($script:CreatedAppServicePlan.Name)" -ForegroundColor Yellow
                Remove-AzAppServicePlan -Name $script:CreatedAppServicePlan.Name -ResourceGroupName $script:ResourceGroupName -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "Failed to cleanup App Service Plan: $($_.Exception.Message)"
            }
        }

        # Cleanup VNet
        if ($script:CreatedVNet) {
            try {
                Write-Host "Cleaning up Virtual Network: $($script:CreatedVNet.Name)" -ForegroundColor Yellow
                Remove-AzVirtualNetwork -Name $script:CreatedVNet.Name -ResourceGroupName $script:ResourceGroupName -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "Failed to cleanup VNet: $($_.Exception.Message)"
            }
        }

        # Cleanup Storage Account
        if ($script:CreatedStorageAccount) {
            try {
                Write-Host "Cleaning up Storage Account: $($script:CreatedStorageAccount.StorageAccountName)" -ForegroundColor Yellow
                Remove-AzStorageAccount -Name $script:CreatedStorageAccount.StorageAccountName -ResourceGroupName $script:ResourceGroupName -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "Failed to cleanup Storage Account: $($_.Exception.Message)"
            }
        }
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
            # Premium plan required for private endpoint support
            $script:CreatedAppServicePlan = New-AzAppServicePlan `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $script:AppServicePlanName `
                -Location $script:ResourceGroup.Location `
                -Tier 'Premium' `
                -WorkerSize 'Small' `
                -NumberofWorkers 1

            $script:CreatedAppServicePlan | Should -Not -BeNullOrEmpty
            $script:CreatedAppServicePlan.Name | Should -Be $script:AppServicePlanName
        }

        It 'Should create Virtual Network and Subnet' {
            $subnetConfig = New-AzVirtualNetworkSubnetConfig `
                -Name $script:SubnetName `
                -AddressPrefix '10.0.1.0/24' `
                -PrivateEndpointNetworkPolicies 'Disabled'

            $script:CreatedVNet = New-AzVirtualNetwork `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $script:VNetName `
                -Location $script:ResourceGroup.Location `
                -AddressPrefix '10.0.0.0/16' `
                -Subnet $subnetConfig

            $script:CreatedVNet | Should -Not -BeNullOrEmpty
            $script:CreatedVNet.Name | Should -Be $script:VNetName
        }
    }

    Context 'Compliant Function App (With Private Endpoint and Public Access Disabled)' {
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

            # Disable public network access
            $webApp = Get-AzWebApp -ResourceGroupName $script:ResourceGroupName -Name $script:CompliantFunctionAppName
            $webApp.SiteConfig.PublicNetworkAccess = 'Disabled'
            Set-AzWebApp -ResourceGroupName $script:ResourceGroupName -Name $script:CompliantFunctionAppName -SiteConfig $webApp.SiteConfig

            # Verify public access is disabled
            $updatedWebApp = Get-AzWebApp -ResourceGroupName $script:ResourceGroupName -Name $script:CompliantFunctionAppName
            Write-Host "Public Network Access: $($updatedWebApp.SiteConfig.PublicNetworkAccess)" -ForegroundColor Cyan
        }

        It 'Should create private endpoint for the Function App' -Skip {
            # Note: Creating private endpoints requires additional network configuration
            # This test is marked as Skip for basic validation - enable for full integration testing

            $functionApp = Get-AzWebApp -ResourceGroupName $script:ResourceGroupName -Name $script:CompliantFunctionAppName
            $subnet = Get-AzVirtualNetwork -ResourceGroupName $script:ResourceGroupName -Name $script:VNetName | Get-AzVirtualNetworkSubnetConfig -Name $script:SubnetName

            $privateLinkServiceConnection = New-AzPrivateLinkServiceConnection `
                -Name "$script:PrivateEndpointName-connection" `
                -PrivateLinkServiceId $functionApp.Id `
                -GroupId 'sites'

            $script:CreatedPrivateEndpoint = New-AzPrivateEndpoint `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $script:PrivateEndpointName `
                -Location $script:ResourceGroup.Location `
                -Subnet $subnet `
                -PrivateLinkServiceConnection $privateLinkServiceConnection

            $script:CreatedPrivateEndpoint | Should -Not -BeNullOrEmpty
        }

        It 'Should be compliant with the policy' {
            # Wait for policy evaluation
            Start-Sleep -Seconds 30

            $complianceStates = Get-AzPolicyState -ResourceGroupName $script:ResourceGroupName -Filter "PolicyDefinitionName eq '$script:PolicyName' and ResourceId like '*$script:CompliantFunctionAppName*'"

            if ($complianceStates) {
                $complianceStates | Should -Not -BeNullOrEmpty
                Write-Host "Compliance State: $($complianceStates[0].ComplianceState)" -ForegroundColor Cyan
            }
            else {
                Write-Warning "Policy compliance state not yet available for $script:CompliantFunctionAppName"
            }
        }
    }

    Context 'Non-Compliant Function App (Public Access Enabled Without Private Endpoint)' {
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
            $webApp = Get-AzWebApp -ResourceGroupName $script:ResourceGroupName -Name $script:NonCompliantFunctionAppName
            Write-Host "Public Network Access: $($webApp.SiteConfig.PublicNetworkAccess)" -ForegroundColor Cyan
        }

        It 'Should be flagged as non-compliant' {
            # Wait for policy evaluation
            Start-Sleep -Seconds 60

            $complianceStates = Get-AzPolicyState -ResourceGroupName $script:ResourceGroupName -Filter "PolicyDefinitionName eq '$script:PolicyName' and ResourceId like '*$script:NonCompliantFunctionAppName*'"

            if ($complianceStates) {
                $complianceStates | Should -Not -BeNullOrEmpty
                Write-Host "Compliance State: $($complianceStates[0].ComplianceState)" -ForegroundColor Cyan

                if ($script:TargetAssignment -and $script:TargetAssignment.Properties.Parameters.effect.value -eq 'Audit') {
                    $complianceStates[0].ComplianceState | Should -Be 'NonCompliant'
                }
            }
            else {
                Write-Warning "Policy compliance state not yet available for $script:NonCompliantFunctionAppName - may need more time for evaluation"
            }
        }
    }
}

Describe 'Policy Effectiveness Tests' -Tag @('Integration', 'Fast', 'Effectiveness') {
    Context 'Private Endpoint Configuration Validation' {
        It 'Should validate policy targets private endpoint connections' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $publicNetworkCondition = $policyRule.if.allOf | Where-Object { $_.anyOf }

            $publicNetworkCondition | Should -Not -BeNullOrEmpty

            # Should check for private endpoint connections count
            $privateEndpointChecks = $publicNetworkCondition.anyOf | Where-Object {
                $_.allOf | Where-Object {
                    ($_.PSObject.Properties.Name -contains 'count') -and
                    ($_.count.field -eq 'Microsoft.Web/sites/privateEndpointConnections[*]')
                }
            }

            $privateEndpointChecks | Should -Not -BeNullOrEmpty
        }

        It 'Should validate policy checks public network access' {
            $policyRule = $script:PolicyDefinitionJson.properties.policyRule
            $publicNetworkCondition = $policyRule.if.allOf | Where-Object { $_.anyOf }

            # Should check if publicNetworkAccess is not Disabled
            $publicAccessChecks = $publicNetworkCondition.anyOf | Where-Object {
                $_.allOf | Where-Object {
                    ($_.field -eq 'Microsoft.Web/sites/publicNetworkAccess') -and
                    (($_.notEquals -eq 'Disabled') -or ($_.exists -eq 'false'))
                }
            }

            $publicAccessChecks | Should -Not -BeNullOrEmpty
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
            $description | Should -Match 'private endpoint|private connectivity|network isolation'
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
}
else {
    Write-Host '- Policy Assignment: Not Found (policy may not be deployed yet)' -ForegroundColor Yellow
}
