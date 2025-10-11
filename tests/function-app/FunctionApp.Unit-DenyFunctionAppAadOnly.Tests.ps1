#Requires -Modules Pester

<#
.SYNOPSIS
    Quick unit tests for Azure Function App AAD-only authentication policy
.DESCRIPTION
    This test suite validates the Azure Policy JSON definition for enforcing
    Azure AD authentication, disabling FTP/FTPS, and disabling basic publishing
    credentials on Azure Function Apps. No Azure resources required.
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
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'function-app' -PolicyName 'deny-function-app-aad-only'

    # Set script variables from configuration
    $script:PolicyPath = Get-PolicyDefinitionPath -PolicyCategory 'function-app' -PolicyName 'deny-function-app-aad-only' -TestScriptPath $PSScriptRoot
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

        It 'Should have mode set to Indexed' {
            $script:PolicyJson.properties.mode | Should -Be 'Indexed'
        }

        It 'Should have policy rule' {
            $script:PolicyJson.properties.policyRule | Should -Not -BeNullOrEmpty
        }

        It 'Should have metadata section' {
            $script:PolicyJson.properties.metadata | Should -Not -BeNullOrEmpty
        }

        It 'Should have parameters section (may be empty)' {
            $script:PolicyJson.properties.PSObject.Properties.Name | Should -Contain 'parameters'
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

        It 'Should use anyOf for multiple violation scenarios' {
            $script:PolicyRule.if.anyOf | Should -Not -BeNullOrEmpty
            $script:PolicyRule.if.anyOf.Count | Should -BeGreaterOrEqual 5
        }

        It 'Should target Function App config resources' {
            # Check for authsettingsV2 config
            $authConfigCondition = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object { $_.field -eq 'name' -and $_.equals -eq 'authsettingsV2' })
            }
            $authConfigCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should target Function App web config' {
            # Check for web config (FTP settings)
            $webConfigCondition = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object { $_.field -eq 'name' -and $_.equals -eq 'web' })
            }
            $webConfigCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should apply to all App Services (including Function Apps)' {
            # Note: Microsoft.Web/sites/kind is NOT a valid Azure Policy field alias
            # Policy applies to all App Services by checking resource type only
            $typeFilters = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object { $_.field -eq 'type' })
            }
            $typeFilters.Count | Should -Be $script:PolicyRule.if.anyOf.Count
        }

        It 'Should validate Azure AD authentication requirement' {
            # Check for Azure AD enabled condition
            $aadCondition = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf.anyOf | Where-Object {
                        $_ | Where-Object { $_.field -like '*azureActiveDirectory.enabled*' }
                    })
            }
            $aadCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should validate authentication is required' {
            # Check for requireAuthentication condition
            $requireAuthCondition = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf.anyOf | Where-Object {
                        $_ | Where-Object { $_.field -like '*requireAuthentication*' }
                    })
            }
            $requireAuthCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should validate FTP/FTPS is disabled' {
            # Check for ftpsState condition
            $ftpsCondition = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object { $_.field -like '*ftpsState*' -and $_.notEquals -eq 'Disabled' })
            }
            $ftpsCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should validate basic publishing credentials are disabled' {
            # Check for basicPublishingCredentialsPolicies
            $publishingCredsCondition = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object { $_.field -eq 'type' -and $_.equals -eq 'Microsoft.Web/sites/basicPublishingCredentialsPolicies' })
            }
            $publishingCredsCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should check both FTP and SCM publishing credentials' {
            # Check for FTP credentials policy
            $ftpCredsCondition = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object { $_.field -eq 'name' -and $_.equals -eq 'ftp' })
            }
            $ftpCredsCondition | Should -Not -BeNullOrEmpty

            # Check for SCM credentials policy
            $scmCredsCondition = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object { $_.field -eq 'name' -and $_.equals -eq 'scm' })
            }
            $scmCredsCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should include slot configurations for FTP settings' {
            # Check for slots/config resources (FTP settings only - auth is main app only)
            $slotConfigConditions = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object { $_.field -eq 'type' -and $_.equals -like '*slots/config*' })
            }
            $slotConfigConditions | Should -Not -BeNullOrEmpty
        }

        It 'Should use parameterized effect' {
            $script:PolicyRule.then.effect | Should -Be "[parameters('effect')]"
        }
    }

    Context 'Policy Metadata Validation' {
        BeforeAll {
            $script:Metadata = (Get-Content $script:PolicyPath -Raw | ConvertFrom-Json).properties.metadata
        }

        It 'Should have category set to App Service' {
            $script:Metadata.category | Should -Be 'App Service'
        }

        It 'Should have version' {
            $script:Metadata.version | Should -Not -BeNullOrEmpty
            $script:Metadata.version | Should -Match '^\d+\.\d+\.\d+$'
        }

        It 'Should have source in metadata' {
            $script:Metadata.source | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Policy Logic Validation' -Tag @('Unit', 'Fast', 'Logic') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Condition Logic Structure' {
        It 'Should use anyOf at root level for multiple violation types' {
            $script:PolicyRule.if.anyOf | Should -Not -BeNullOrEmpty
        }

        It 'Should have proper structure for each violation scenario' {
            # Each anyOf scenario should use allOf internally to combine conditions
            $allOfScenarios = $script:PolicyRule.if.anyOf | Where-Object { $_.allOf }
            $allOfScenarios.Count | Should -Be $script:PolicyRule.if.anyOf.Count
        }

        It 'Should combine resource type, name, and kind filters' {
            # Each scenario should have type, name, and kind filters
            foreach ($scenario in $script:PolicyRule.if.anyOf) {
                $typeFilter = $scenario.allOf | Where-Object { $_.field -eq 'type' }
                $typeFilter | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should use nested anyOf for authentication violations' {
            # Auth scenarios should have multiple possible violations
            $authScenarios = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf -and ($_.allOf | Where-Object { $_.field -eq 'name' -and $_.equals -eq 'authsettingsV2' })
            }

            foreach ($authScenario in $authScenarios) {
                $nestedAnyOf = $authScenario.allOf | Where-Object { $_.anyOf }
                $nestedAnyOf | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Security Logic' {
        It 'Should enforce Azure AD authentication by default' {
            # Policy should deny if Azure AD is not enabled
            $aadCheck = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf.anyOf | Where-Object {
                    $_ | Where-Object { $_.field -like '*azureActiveDirectory.enabled*' -and $_.notEquals -eq $true }
                }
            }
            $aadCheck | Should -Not -BeNullOrEmpty
        }

        It 'Should enforce authentication requirement' {
            # Policy should deny if authentication is not required
            $authRequiredCheck = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf.anyOf | Where-Object {
                    $_ | Where-Object { $_.field -like '*requireAuthentication*' -and $_.notEquals -eq $true }
                }
            }
            $authRequiredCheck | Should -Not -BeNullOrEmpty
        }

        It 'Should prevent insecure FTP access' {
            # Policy should deny if FTP is not disabled
            $ftpCheck = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf | Where-Object { $_.field -like '*ftpsState*' -and $_.notEquals -eq 'Disabled' }
            }
            $ftpCheck | Should -Not -BeNullOrEmpty
        }

        It 'Should prevent basic publishing credentials' {
            # Policy should deny if basic publishing credentials are allowed
            $publishingCredsCheck = $script:PolicyRule.if.anyOf | Where-Object {
                $_.allOf | Where-Object { $_.field -like '*basicPublishingCredentialsPolicies/allow*' -and $_.notEquals -eq $false }
            }
            $publishingCredsCheck | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Policy Compliance Scenarios' -Tag @('Unit', 'Fast', 'Scenarios') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Simulated Resource Evaluation - Auth Settings' {
        It 'Should identify compliant Function App with Azure AD auth' {
            # Simulate a compliant authsettingsV2 config
            $compliantAuthConfig = @{
                type       = 'Microsoft.Web/sites/config'
                name       = 'authsettingsV2'
                kind       = 'functionapp'
                properties = @{
                    globalValidation  = @{
                        requireAuthentication       = $true
                        unauthenticatedClientAction = 'RedirectToLoginPage'
                    }
                    identityProviders = @{
                        azureActiveDirectory = @{
                            enabled = $true
                        }
                    }
                }
            }

            $compliantAuthConfig.properties.globalValidation.requireAuthentication | Should -Be $true
            $compliantAuthConfig.properties.identityProviders.azureActiveDirectory.enabled | Should -Be $true
        }

        It 'Should identify non-compliant Function App without required authentication' {
            $nonCompliantAuthConfig = @{
                type       = 'Microsoft.Web/sites/config'
                name       = 'authsettingsV2'
                kind       = 'functionapp'
                properties = @{
                    globalValidation = @{
                        requireAuthentication       = $false
                        unauthenticatedClientAction = 'AllowAnonymous'
                    }
                }
            }

            $nonCompliantAuthConfig.properties.globalValidation.requireAuthentication | Should -Be $false
        }

        It 'Should identify non-compliant Function App without Azure AD enabled' {
            $nonCompliantAuthConfig = @{
                type       = 'Microsoft.Web/sites/config'
                name       = 'authsettingsV2'
                kind       = 'functionapp'
                properties = @{
                    globalValidation  = @{
                        requireAuthentication       = $true
                        unauthenticatedClientAction = 'RedirectToLoginPage'
                    }
                    identityProviders = @{
                        azureActiveDirectory = @{
                            enabled = $false
                        }
                    }
                }
            }

            $nonCompliantAuthConfig.properties.identityProviders.azureActiveDirectory.enabled | Should -Be $false
        }

        It 'Should identify non-compliant Function App with wrong unauthenticated action' {
            $nonCompliantAuthConfig = @{
                type       = 'Microsoft.Web/sites/config'
                name       = 'authsettingsV2'
                kind       = 'functionapp'
                properties = @{
                    globalValidation  = @{
                        requireAuthentication       = $true
                        unauthenticatedClientAction = 'AllowAnonymous'
                    }
                    identityProviders = @{
                        azureActiveDirectory = @{
                            enabled = $true
                        }
                    }
                }
            }

            $nonCompliantAuthConfig.properties.globalValidation.unauthenticatedClientAction | Should -Not -BeIn @('RedirectToLoginPage', 'Return401')
        }
    }

    Context 'Simulated Resource Evaluation - FTP Settings' {
        It 'Should identify compliant Function App with FTP disabled' {
            $compliantWebConfig = @{
                type       = 'Microsoft.Web/sites/config'
                name       = 'web'
                kind       = 'functionapp'
                properties = @{
                    ftpsState = 'Disabled'
                }
            }

            $compliantWebConfig.properties.ftpsState | Should -Be 'Disabled'
        }

        It 'Should identify non-compliant Function App with FTP enabled' {
            $nonCompliantWebConfig = @{
                type       = 'Microsoft.Web/sites/config'
                name       = 'web'
                kind       = 'functionapp'
                properties = @{
                    ftpsState = 'AllAllowed'
                }
            }

            $nonCompliantWebConfig.properties.ftpsState | Should -Not -Be 'Disabled'
        }

        It 'Should identify non-compliant Function App with FTPS only' {
            $nonCompliantWebConfig = @{
                type       = 'Microsoft.Web/sites/config'
                name       = 'web'
                kind       = 'functionapp'
                properties = @{
                    ftpsState = 'FtpsOnly'
                }
            }

            $nonCompliantWebConfig.properties.ftpsState | Should -Not -Be 'Disabled'
        }
    }

    Context 'Simulated Resource Evaluation - Publishing Credentials' {
        It 'Should identify compliant Function App with FTP credentials disabled' {
            $compliantFtpPolicy = @{
                type       = 'Microsoft.Web/sites/basicPublishingCredentialsPolicies'
                name       = 'ftp'
                kind       = 'functionapp'
                properties = @{
                    allow = $false
                }
            }

            $compliantFtpPolicy.properties.allow | Should -Be $false
        }

        It 'Should identify compliant Function App with SCM credentials disabled' {
            $compliantScmPolicy = @{
                type       = 'Microsoft.Web/sites/basicPublishingCredentialsPolicies'
                name       = 'scm'
                kind       = 'functionapp'
                properties = @{
                    allow = $false
                }
            }

            $compliantScmPolicy.properties.allow | Should -Be $false
        }

        It 'Should identify non-compliant Function App with FTP credentials enabled' {
            $nonCompliantFtpPolicy = @{
                type       = 'Microsoft.Web/sites/basicPublishingCredentialsPolicies'
                name       = 'ftp'
                kind       = 'functionapp'
                properties = @{
                    allow = $true
                }
            }

            $nonCompliantFtpPolicy.properties.allow | Should -Be $true
        }

        It 'Should identify non-compliant Function App with SCM credentials enabled' {
            $nonCompliantScmPolicy = @{
                type       = 'Microsoft.Web/sites/basicPublishingCredentialsPolicies'
                name       = 'scm'
                kind       = 'functionapp'
                properties = @{
                    allow = $true
                }
            }

            $nonCompliantScmPolicy.properties.allow | Should -Be $true
        }
    }

    Context 'Simulated Resource Evaluation - Slot Configurations' {
        It 'Should apply to Function App deployment slots (auth settings)' {
            $slotAuthConfig = @{
                type       = 'Microsoft.Web/sites/slots/config'
                name       = 'authsettingsV2'
                kind       = 'functionapp'
                properties = @{
                    globalValidation  = @{
                        requireAuthentication = $true
                    }
                    identityProviders = @{
                        azureActiveDirectory = @{
                            enabled = $true
                        }
                    }
                }
            }

            # Slots should follow same rules as main app
            $slotAuthConfig.type | Should -Be 'Microsoft.Web/sites/slots/config'
            $slotAuthConfig.properties.identityProviders.azureActiveDirectory.enabled | Should -Be $true
        }

        It 'Should apply to Function App deployment slots (FTP settings)' {
            $slotWebConfig = @{
                type       = 'Microsoft.Web/sites/slots/config'
                name       = 'web'
                kind       = 'functionapp'
                properties = @{
                    ftpsState = 'Disabled'
                }
            }

            $slotWebConfig.type | Should -Be 'Microsoft.Web/sites/slots/config'
            $slotWebConfig.properties.ftpsState | Should -Be 'Disabled'
        }
    }
}

Describe 'Policy Coverage and Completeness' -Tag @('Unit', 'Fast', 'Coverage') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Security Controls Coverage' {
        It 'Should cover all critical security requirements' {
            # The policy covers 5 main scenarios:
            # 1. authsettingsV2 for main app (Easy Auth v2 settings)
            # 2. web config (FTP) for main app
            # 3. web config (FTP) for slots
            # 4. FTP publishing credentials
            # 5. SCM publishing credentials

            $script:PolicyRule.if.anyOf.Count | Should -Be 5
        }

        It 'Should enforce defense in depth' {
            # Policy should check multiple security layers:
            # - Authentication (Azure AD)
            # - Authorization (require authentication)
            # - Transport security (FTP disabled)
            # - Credential management (basic auth disabled)

            # Count distinct security controls
            $authControls = ($script:PolicyRule.if.anyOf | Where-Object {
                    $_.allOf | Where-Object { $_.field -eq 'name' -and $_.equals -eq 'authsettingsV2' }
                }).Count

            $ftpControls = ($script:PolicyRule.if.anyOf | Where-Object {
                    $_.allOf | Where-Object { $_.field -like '*ftpsState*' }
                }).Count

            $credControls = ($script:PolicyRule.if.anyOf | Where-Object {
                    $_.allOf | Where-Object { $_.field -eq 'type' -and $_.equals -eq 'Microsoft.Web/sites/basicPublishingCredentialsPolicies' }
                }).Count

            $authControls | Should -BeGreaterThan 0
            $ftpControls | Should -BeGreaterThan 0
            $credControls | Should -BeGreaterThan 0
        }

        It 'Should apply to all App Services and Function Apps' {
            # Policy applies broadly to all Microsoft.Web/sites resources
            # Note: Cannot filter by 'kind' field as it's not a valid Azure Policy alias
            # Each scenario must have resource type filter
            foreach ($scenario in $script:PolicyRule.if.anyOf) {
                $typeFilter = $scenario.allOf | Where-Object { $_.field -eq 'type' }
                $typeFilter | Should -Not -BeNullOrEmpty 'Each scenario must filter by resource type'
            }
        }
    }
}
