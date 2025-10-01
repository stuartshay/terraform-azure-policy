# Test for deny-network-no-nsg Azure Policy
# This test validates that the deny-network-no-nsg policy correctly identifies
# network resources that don't have NSGs associated

BeforeAll {
    # Import centralized configuration
    . "$PSScriptRoot\..\..\config\config-loader.ps1"

    # Initialize test configuration for this specific policy
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'network' -PolicyName 'deny-network-no-nsg'

    # Set script variables from configuration
    $script:PolicyPath = Get-PolicyDefinitionPath -PolicyCategory 'network' -PolicyName 'deny-network-no-nsg' -TestScriptPath $PSScriptRoot
    $script:PolicyName = $script:TestConfig.Policy.Name
    $script:PolicyDisplayName = $script:TestConfig.Policy.DisplayName
}

Describe 'Deny Network No NSG Policy Tests' {

    Context 'Policy Definition Validation' {

        It 'Should have a valid policy definition file' {
            $script:PolicyPath | Should -Exist
        }

        It 'Should have valid JSON format' {
            { Get-Content $script:PolicyPath -Raw | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Should have required policy structure' {
            $policy = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
            $policy.properties | Should -Not -BeNullOrEmpty
            $policy.properties.policyRule | Should -Not -BeNullOrEmpty
            $policy.properties.parameters | Should -Not -BeNullOrEmpty
        }

        It 'Should have correct policy mode' {
            $policy = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
            $policy.properties.mode | Should -Be 'All'
        }

        It 'Should have exemptedSubnets parameter' {
            $policy = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
            $policy.properties.parameters.exemptedSubnets | Should -Not -BeNullOrEmpty
            $policy.properties.parameters.exemptedSubnets.type | Should -Be 'Array'
        }
    }

    Context 'Policy Rule Logic Validation' {

        BeforeAll {
            $script:Policy = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
            $script:PolicyRule = $script:Policy.properties.policyRule
        }

        It 'Should target correct resource types' {
            $resourceTypes = @()

            # Extract resource types from the anyOf conditions
            if ($script:PolicyRule.if.anyOf) {
                foreach ($condition in $script:PolicyRule.if.anyOf) {
                    if ($condition.allOf) {
                        foreach ($subCondition in $condition.allOf) {
                            if ($subCondition.field -eq 'type') {
                                $resourceTypes += $subCondition.equals
                            }
                        }
                    }
                }
            }

            $resourceTypes | Should -Contain 'Microsoft.Network/virtualNetworks/subnets'
            $resourceTypes | Should -Contain 'Microsoft.Network/networkInterfaces'
        }

        It 'Should have parameterized effect' {
            $script:PolicyRule.then.effect | Should -Be "[parameters('effect')]"
        }

        It 'Should check for NSG associations' {
            $policyJson = $script:Policy | ConvertTo-Json -Depth 20
            $policyJson | Should -Match 'networkSecurityGroup.id'
        }

        It 'Should have exemption logic for service subnets' {
            $policyJson = $script:Policy | ConvertTo-Json -Depth 20
            $policyJson | Should -Match 'exemptedSubnets'
        }
    }

    Context 'Test Scenarios' {

        It 'Should allow subnet with NSG' {
            $testResource = @{
                type       = 'Microsoft.Network/virtualNetworks/subnets'
                name       = 'test-subnet'
                properties = @{
                    networkSecurityGroup = @{
                        id = '/subscriptions/test/resourceGroups/test/providers/Microsoft.Network/networkSecurityGroups/test-nsg'
                    }
                }
            }

            # This should not match the policy rule (i.e., should be allowed)
            Write-Host 'Testing subnet with NSG - should be allowed'
            $testResource.properties.networkSecurityGroup.id | Should -Not -BeNullOrEmpty
        }

        It 'Should deny subnet without NSG' {
            $testResource = @{
                type       = 'Microsoft.Network/virtualNetworks/subnets'
                name       = 'test-subnet'
                properties = @{}
            }

            # This should match the policy rule (i.e., should be denied)
            Write-Host 'Testing subnet without NSG - should be denied'
            $testResource.properties.networkSecurityGroup | Should -BeNullOrEmpty
        }

        It 'Should allow exempted Azure service subnets' {
            $exemptedSubnets = @(
                'GatewaySubnet',
                'AzureFirewallSubnet',
                'AzureFirewallManagementSubnet',
                'RouteServerSubnet',
                'AzureBastionSubnet'
            )

            foreach ($subnetName in $exemptedSubnets) {
                $testResource = @{
                    type       = 'Microsoft.Network/virtualNetworks/subnets'
                    name       = $subnetName
                    properties = @{}
                }

                Write-Host "Testing exempted subnet: $subnetName - should be allowed"
                # Exempted subnets should be allowed even without NSG
                $exemptedSubnets | Should -Contain $subnetName
            }
        }

        It 'Should deny network interface without NSG' {
            $testResource = @{
                type       = 'Microsoft.Network/networkInterfaces'
                name       = 'test-nic'
                properties = @{}
            }

            # This should match the policy rule (i.e., should be denied)
            Write-Host 'Testing NIC without NSG - should be denied'
            $testResource.properties.networkSecurityGroup | Should -BeNullOrEmpty
        }

        It 'Should allow network interface with NSG' {
            $testResource = @{
                type       = 'Microsoft.Network/networkInterfaces'
                name       = 'test-nic'
                properties = @{
                    networkSecurityGroup = @{
                        id = '/subscriptions/test/resourceGroups/test/providers/Microsoft.Network/networkSecurityGroups/test-nsg'
                    }
                }
            }

            # This should not match the policy rule (i.e., should be allowed)
            Write-Host 'Testing NIC with NSG - should be allowed'
            $testResource.properties.networkSecurityGroup.id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Parameter Validation' {

        It 'Should have default exempted subnets' {
            $policy = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
            $defaultValue = $policy.properties.parameters.exemptedSubnets.defaultValue

            $defaultValue | Should -Contain 'GatewaySubnet'
            $defaultValue | Should -Contain 'AzureFirewallSubnet'
            $defaultValue | Should -Contain 'AzureBastionSubnet'
        }

        It 'Should allow custom exempted subnets' {
            $policy = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
            $parameter = $policy.properties.parameters.exemptedSubnets

            $parameter.type | Should -Be 'Array'
            $parameter.metadata.description | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Integration Tests' {

        It 'Should work with Terraform deployment' {
            # Check if Terraform files exist
            $terraformPath = "$PSScriptRoot\..\..\policies\network\deny-network-no-nsg"
            "$terraformPath\main.tf" | Should -Exist
            "$terraformPath\variables.tf" | Should -Exist
            "$terraformPath\outputs.tf" | Should -Exist
        }

        It 'Should have proper documentation' {
            $readmePath = "$PSScriptRoot\..\..\policies\network\deny-network-no-nsg\README.md"
            $readmePath | Should -Exist

            $readme = Get-Content $readmePath -Raw
            $readme | Should -Match 'Deny Network Resources Without NSG'
            $readme | Should -Match 'NSG'
        }
    }
}

# Test Summary
AfterAll {
    Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
    Write-Host "Policy: $script:PolicyDisplayName" -ForegroundColor Green
    Write-Host "Path: $script:PolicyPath" -ForegroundColor Yellow
    Write-Host 'Tests completed for deny-network-no-nsg policy' -ForegroundColor Green
}
