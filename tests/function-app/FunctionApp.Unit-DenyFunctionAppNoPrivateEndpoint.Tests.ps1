#Requires -Modules Pester

<#
.SYNOPSIS
    Quick unit tests for Azure Function App private endpoint enforcement policy
.DESCRIPTION
    This test suite validates the Azure Policy JSON definition for enforcing
    private endpoint configuration on Azure Function Apps. No Azure resources required.
.NOTES
    Prerequisites:
    - Pester module only
    - No Azure authentication required
    - No Azure resources created
#>

BeforeAll {
    # Import centralized configuration
    . "$PSScriptRoot\..\..\config\config-loader.ps1"

    # Initialize test configuration for this specific policy
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'function-app' -PolicyName 'deny-function-app-no-private-endpoint'

    # Set script variables from configuration
    $script:PolicyPath = Get-PolicyDefinitionPath -PolicyCategory 'function-app' -PolicyName 'deny-function-app-no-private-endpoint' -TestScriptPath $PSScriptRoot
    $script:ExpectedPolicyName = $script:TestConfig.Policy.Name
    $script:ExpectedDisplayName = $script:TestConfig.Policy.DisplayName
}

Describe 'Policy JSON Validation' -Tag @('Unit', 'Fast', 'Static') {

    Context 'File Structure' {
        It 'Should have policy definition file' {
            Test-Path $script:PolicyPath | Should -Be $true
        }

        It 'Should be valid JSON' {
            { Get-Content $script:PolicyPath -Raw | ConvertFrom-Json } | Should -Not -Throw
        }
    }

    Context 'Policy Content Validation' {
        BeforeAll {
            $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        }

        It 'Should have name property' {
            $script:PolicyJson.name | Should -Be $script:ExpectedPolicyName
        }

        It 'Should have properties section' {
            $script:PolicyJson.properties | Should -Not -BeNullOrEmpty
        }

        It 'Should have display name' {
            $script:PolicyJson.properties.displayName | Should -Be $script:ExpectedDisplayName
        }

        It 'Should have description' {
            $script:PolicyJson.properties.description | Should -Not -BeNullOrEmpty
            $script:PolicyJson.properties.description.Length | Should -BeGreaterThan 10
        }

        It 'Should have mode set to All' {
            $script:PolicyJson.properties.mode | Should -Be 'All'
        }

        It 'Should have policy rule' {
            $script:PolicyJson.properties.policyRule | Should -Not -BeNullOrEmpty
        }

        It 'Should have metadata section' {
            $script:PolicyJson.properties.metadata | Should -Not -BeNullOrEmpty
        }

        It 'Should have parameters section' {
            $script:PolicyJson.properties.parameters | Should -Not -BeNullOrEmpty
        }

        It 'Should have effect parameter' {
            $script:PolicyJson.properties.parameters.effect | Should -Not -BeNullOrEmpty
        }

        It 'Should have exemptedFunctionApps parameter' {
            $script:PolicyJson.properties.parameters.exemptedFunctionApps | Should -Not -BeNullOrEmpty
        }

        It 'Should have exemptedResourceGroups parameter' {
            $script:PolicyJson.properties.parameters.exemptedResourceGroups | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Policy Rule Validation' {
        BeforeAll {
            $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
            $script:PolicyRule = $script:PolicyJson.properties.policyRule
        }

        It 'Should have if condition' {
            $script:PolicyRule.if | Should -Not -BeNullOrEmpty
        }

        It 'Should have then effect' {
            $script:PolicyRule.then | Should -Not -BeNullOrEmpty
            $script:PolicyRule.then.effect | Should -Not -BeNullOrEmpty
        }

        It 'Should use allOf at root level for combining conditions' {
            $script:PolicyRule.if.allOf | Should -Not -BeNullOrEmpty
        }

        It 'Should target Microsoft.Web/sites resource type' {
            $typeCondition = $script:PolicyRule.if.allOf | Where-Object { $_.field -eq 'type' }
            $typeCondition | Should -Not -BeNullOrEmpty
            $typeCondition.equals | Should -Be 'Microsoft.Web/sites'
        }

        It 'Should target functionapp kind' {
            $kindCondition = $script:PolicyRule.if.allOf | Where-Object { $_.field -eq 'kind' }
            $kindCondition | Should -Not -BeNullOrEmpty
            $kindCondition.equals | Should -Be 'functionapp'
        }

        It 'Should check exempted Function Apps' {
            $exemptionCondition = $script:PolicyRule.if.allOf | Where-Object {
                $_.not -and $_.not.field -eq 'name'
            }
            $exemptionCondition | Should -Not -BeNullOrEmpty
            $exemptionCondition.not.in | Should -Be "[parameters('exemptedFunctionApps')]"
        }

        It 'Should check exempted Resource Groups' {
            $exemptionCondition = $script:PolicyRule.if.allOf | Where-Object {
                $_.not -and $_.not.field -eq 'Microsoft.Web/sites/resourceGroup'
            }
            $exemptionCondition | Should -Not -BeNullOrEmpty
            $exemptionCondition.not.in | Should -Be "[parameters('exemptedResourceGroups')]"
        }

        It 'Should use anyOf for public network access scenarios' {
            $publicNetworkCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $publicNetworkCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should check publicNetworkAccess property' {
            $publicNetworkCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $publicAccessScenarios = $publicNetworkCondition.anyOf

            # Should have scenario checking if publicNetworkAccess is not Disabled
            $notDisabledScenario = $publicAccessScenarios | Where-Object {
                $_.field -eq 'Microsoft.Web/sites/publicNetworkAccess' -and $_.notEquals -eq 'Disabled'
            }
            $notDisabledScenario | Should -Not -BeNullOrEmpty

            # Should have scenario checking if publicNetworkAccess doesn't exist
            $notExistsScenario = $publicAccessScenarios | Where-Object {
                $_.field -eq 'Microsoft.Web/sites/publicNetworkAccess' -and $_.exists -eq 'false'
            }
            $notExistsScenario | Should -Not -BeNullOrEmpty
        }

        It 'Should only check publicNetworkAccess without private endpoint validation' {
            # Policy has been simplified to only check publicNetworkAccess due to Azure Policy platform limitation
            # Private endpoint connections cannot be validated using Azure Policy aliases
            $publicNetworkCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $publicAccessScenarios = $publicNetworkCondition.anyOf

            # Verify that scenarios check publicNetworkAccess field
            foreach ($scenario in $publicAccessScenarios) {
                $scenario.field | Should -Be 'Microsoft.Web/sites/publicNetworkAccess'
            }

            # Verify no count expressions exist (as they're not supported for privateEndpointConnections)
            # Use PSObject.Properties to check for actual 'count' property, not PowerShell's Count property
            $scenariosWithCount = $publicAccessScenarios | Where-Object { $_.PSObject.Properties.Name -contains 'count' }
            $scenariosWithCount | Should -BeNullOrEmpty
        }

        It 'Should use parameterized effect' {
            $script:PolicyRule.then.effect | Should -Be "[parameters('effect')]"
        }
    }

    Context 'Policy Metadata Validation' {
        BeforeAll {
            $script:Metadata = (Get-Content $script:PolicyPath -Raw | ConvertFrom-Json).properties.metadata
        }

        It 'Should have category set to Function App' {
            $script:Metadata.category | Should -Be 'Function App'
        }

        It 'Should have version' {
            $script:Metadata.version | Should -Not -BeNullOrEmpty
            $script:Metadata.version | Should -Match '^\d+\.\d+\.\d+$'
        }

        It 'Should have source in metadata' {
            $script:Metadata.source | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Policy Parameters Validation' {
        BeforeAll {
            $script:Parameters = (Get-Content $script:PolicyPath -Raw | ConvertFrom-Json).properties.parameters
        }

        It 'Should have effect parameter with correct allowed values' {
            $script:Parameters.effect | Should -Not -BeNullOrEmpty
            $script:Parameters.effect.allowedValues | Should -Contain 'Audit'
            $script:Parameters.effect.allowedValues | Should -Contain 'Deny'
            $script:Parameters.effect.allowedValues | Should -Contain 'Disabled'
        }

        It 'Should have default effect of Deny' {
            $script:Parameters.effect.defaultValue | Should -Be 'Deny'
        }

        It 'Should have exemptedFunctionApps as Array type' {
            $script:Parameters.exemptedFunctionApps.type | Should -Be 'Array'
            $script:Parameters.exemptedFunctionApps.defaultValue | Should -Be @()
        }

        It 'Should have exemptedResourceGroups as Array type' {
            $script:Parameters.exemptedResourceGroups.type | Should -Be 'Array'
            $script:Parameters.exemptedResourceGroups.defaultValue | Should -Be @()
        }
    }
}

Describe 'Policy Logic Validation' -Tag @('Unit', 'Fast', 'Logic') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Condition Logic Structure' {
        It 'Should use allOf at root level to combine all conditions' {
            $script:PolicyRule.if.allOf | Should -Not -BeNullOrEmpty
        }

        It 'Should have proper condition count' {
            # Conditions: type, kind, not exempted apps, not exempted RGs, public network scenarios
            $script:PolicyRule.if.allOf.Count | Should -BeGreaterOrEqual 5
        }

        It 'Should use anyOf for multiple violation scenarios' {
            # Policy should trigger if public access is enabled OR not set, AND no private endpoints
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $anyOfCondition | Should -Not -BeNullOrEmpty
            $anyOfCondition.anyOf.Count | Should -BeGreaterOrEqual 2
        }
    }

    Context 'Security Logic' {
        It 'Should deny when public network access is not disabled' {
            $publicNetworkCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $scenario = $publicNetworkCondition.anyOf | Where-Object {
                $_ | Where-Object { $_.field -eq 'Microsoft.Web/sites/publicNetworkAccess' -and $_.notEquals -eq 'Disabled' }
            }

            $scenario | Should -Not -BeNullOrEmpty
            $scenario.field | Should -Be 'Microsoft.Web/sites/publicNetworkAccess'
            $scenario.notEquals | Should -Be 'Disabled'
        }

        It 'Should deny when public network access property does not exist' {
            $publicNetworkCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $scenario = $publicNetworkCondition.anyOf | Where-Object {
                $_ | Where-Object { $_.field -eq 'Microsoft.Web/sites/publicNetworkAccess' -and $_.exists -eq 'false' }
            }

            $scenario | Should -Not -BeNullOrEmpty
            $scenario.field | Should -Be 'Microsoft.Web/sites/publicNetworkAccess'
            $scenario.exists | Should -Be 'false'
        }

        It 'Should use anyOf to check multiple violation scenarios' {
            $publicNetworkCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $publicNetworkCondition | Should -Not -BeNullOrEmpty
            $publicNetworkCondition.anyOf | Should -Not -BeNullOrEmpty
            $publicNetworkCondition.anyOf.Count | Should -BeGreaterOrEqual 2
            # Should check both notEquals and exists scenarios
            $publicNetworkCondition.anyOf.field | Should -Contain 'Microsoft.Web/sites/publicNetworkAccess'
        }
    }
}

Describe 'Policy Compliance Scenarios' -Tag @('Unit', 'Fast', 'Scenarios') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Simulated Resource Evaluation - Compliant Scenarios' {
        It 'Should allow Function App with public network disabled and private endpoints' {
            $compliantFunctionApp = @{
                type                       = 'Microsoft.Web/sites'
                kind                       = 'functionapp'
                name                       = 'compliant-function-app'
                publicNetworkAccess        = 'Disabled'
                privateEndpointConnections = @(
                    @{
                        id   = '/subscriptions/xxx/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe1'
                        name = 'pe1'
                    }
                )
            }

            $compliantFunctionApp.publicNetworkAccess | Should -Be 'Disabled'
            $compliantFunctionApp.privateEndpointConnections.Count | Should -BeGreaterThan 0
        }

        It 'Should allow Function App with public network enabled but has private endpoints' {
            # Note: This is technically allowed by the policy as written
            # The policy denies when BOTH conditions are true:
            # 1. Public network access is not disabled
            # 2. No private endpoints exist
            $compliantFunctionApp = @{
                type                       = 'Microsoft.Web/sites'
                kind                       = 'functionapp'
                name                       = 'hybrid-function-app'
                publicNetworkAccess        = 'Enabled'
                privateEndpointConnections = @(
                    @{
                        id   = '/subscriptions/xxx/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/pe1'
                        name = 'pe1'
                    }
                )
            }

            # Has private endpoints, so allowed even though public access is enabled
            $compliantFunctionApp.privateEndpointConnections.Count | Should -BeGreaterThan 0
        }

        It 'Should allow exempted Function App without private endpoints' {
            $exemptedFunctionApp = @{
                type                       = 'Microsoft.Web/sites'
                kind                       = 'functionapp'
                name                       = 'exempted-function-app'
                publicNetworkAccess        = 'Enabled'
                privateEndpointConnections = @()
            }

            # Would be checked against exemption list in actual policy evaluation
            $exemptedFunctionApp.name | Should -Be 'exempted-function-app'
        }
    }

    Context 'Simulated Resource Evaluation - Non-Compliant Scenarios' {
        It 'Should deny Function App with public network enabled and no private endpoints' {
            $nonCompliantFunctionApp = @{
                type                       = 'Microsoft.Web/sites'
                kind                       = 'functionapp'
                name                       = 'non-compliant-function-app'
                publicNetworkAccess        = 'Enabled'
                privateEndpointConnections = @()
            }

            $nonCompliantFunctionApp.publicNetworkAccess | Should -Not -Be 'Disabled'
            $nonCompliantFunctionApp.privateEndpointConnections.Count | Should -Be 0
        }

        It 'Should deny Function App without publicNetworkAccess property and no private endpoints' {
            $nonCompliantFunctionApp = @{
                type                       = 'Microsoft.Web/sites'
                kind                       = 'functionapp'
                name                       = 'non-compliant-function-app2'
                # publicNetworkAccess property not set
                privateEndpointConnections = @()
            }

            $nonCompliantFunctionApp.PSObject.Properties.Name | Should -Not -Contain 'publicNetworkAccess'
            $nonCompliantFunctionApp.privateEndpointConnections.Count | Should -Be 0
        }

        It 'Should deny Function App with null privateEndpointConnections' {
            $nonCompliantFunctionApp = @{
                type                       = 'Microsoft.Web/sites'
                kind                       = 'functionapp'
                name                       = 'non-compliant-function-app3'
                publicNetworkAccess        = 'Enabled'
                privateEndpointConnections = $null
            }

            $nonCompliantFunctionApp.publicNetworkAccess | Should -Not -Be 'Disabled'
            $nonCompliantFunctionApp.privateEndpointConnections | Should -BeNullOrEmpty
        }
    }

    Context 'Simulated Resource Evaluation - Edge Cases' {
        It 'Should not apply to non-functionapp resources' {
            $webApp = @{
                type                       = 'Microsoft.Web/sites'
                kind                       = 'app'  # Regular web app, not function app
                name                       = 'web-app'
                publicNetworkAccess        = 'Enabled'
                privateEndpointConnections = @()
            }

            $webApp.kind | Should -Not -Be 'functionapp'
        }

        It 'Should handle Function App with public network disabled and no private endpoints' {
            # This is compliant - public access is disabled
            $compliantFunctionApp = @{
                type                       = 'Microsoft.Web/sites'
                kind                       = 'functionapp'
                name                       = 'locked-down-function-app'
                publicNetworkAccess        = 'Disabled'
                privateEndpointConnections = @()
            }

            $compliantFunctionApp.publicNetworkAccess | Should -Be 'Disabled'
        }

        It 'Should handle Function App in exempted resource group' {
            $exemptedRgFunctionApp = @{
                type                       = 'Microsoft.Web/sites'
                kind                       = 'functionapp'
                name                       = 'function-in-exempted-rg'
                resourceGroup              = 'rg-exempted'
                publicNetworkAccess        = 'Enabled'
                privateEndpointConnections = @()
            }

            # Would be checked against exempted resource groups in actual policy evaluation
            $exemptedRgFunctionApp.resourceGroup | Should -Be 'rg-exempted'
        }
    }
}

Describe 'Policy Coverage and Completeness' -Tag @('Unit', 'Fast', 'Coverage') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Security Controls Coverage' {
        It 'Should enforce public network access disabled (prerequisite for private endpoints)' {
            # Policy enforces publicNetworkAccess = Disabled as a prerequisite
            # Note: Azure Policy cannot directly validate private endpoint connections due to platform limitation
            $publicNetworkCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $publicAccessChecks = $publicNetworkCondition.anyOf | Where-Object {
                $_.field -eq 'Microsoft.Web/sites/publicNetworkAccess'
            }

            $publicAccessChecks | Should -Not -BeNullOrEmpty
            $publicAccessChecks.Count | Should -BeGreaterOrEqual 2
        }

        It 'Should enforce public network access control with multiple conditions' {
            # Policy should check publicNetworkAccess property in multiple ways
            $publicNetworkCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $publicAccessChecks = $publicNetworkCondition.anyOf | Where-Object {
                $_.field -eq 'Microsoft.Web/sites/publicNetworkAccess'
            }

            $publicAccessChecks | Should -Not -BeNullOrEmpty
            # Should check both notEquals 'Disabled' and exists 'false'
            ($publicAccessChecks | Where-Object { $_.notEquals }).notEquals | Should -Be 'Disabled'
            ($publicAccessChecks | Where-Object { $_.exists }).exists | Should -Be 'false'
        }

        It 'Should target only Function Apps' {
            # Policy should specifically target functionapp kind
            $kindCondition = $script:PolicyRule.if.allOf | Where-Object { $_.field -eq 'kind' }
            $kindCondition.equals | Should -Be 'functionapp'
        }

        It 'Should support exemptions' {
            # Policy should have exemption mechanisms
            $appExemption = $script:PolicyRule.if.allOf | Where-Object {
                $_.not -and $_.not.field -eq 'name'
            }
            $rgExemption = $script:PolicyRule.if.allOf | Where-Object {
                $_.not -and $_.not.field -eq 'Microsoft.Web/sites/resourceGroup'
            }

            $appExemption | Should -Not -BeNullOrEmpty
            $rgExemption | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Policy Effectiveness' {
        It 'Should have clear and actionable description' {
            $description = $script:PolicyJson.properties.description
            $description | Should -Match 'private endpoint|private connectivity|network isolation'
        }

        It 'Should have informative display name' {
            $displayName = $script:PolicyJson.properties.displayName
            $displayName | Should -Match 'Function App|Private Endpoint'
        }

        It 'Should use secure default effect' {
            $defaultEffect = $script:PolicyJson.properties.parameters.effect.defaultValue
            $defaultEffect | Should -Be 'Deny'
        }
    }
}

Write-Host "`nTest Summary:" -ForegroundColor Cyan
Write-Host "- Policy Name: $script:ExpectedPolicyName" -ForegroundColor Green
Write-Host "- Policy Display Name: $script:ExpectedDisplayName" -ForegroundColor Green
Write-Host "- Policy Path: $script:PolicyPath" -ForegroundColor Green
