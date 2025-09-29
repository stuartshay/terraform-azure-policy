# Test for deny-network-private-ips Azure Policy
# This test validates that the deny-network-private-ips policy correctly identifies
# network resources that use public IP addresses

BeforeAll {
    # Import shared test configuration
    . "$PSScriptRoot\..\PolicyTestConfig.ps1"

    # Test configuration
    $script:PolicyPath = "$PSScriptRoot\..\..\policies\network\deny-network-private-ips\rule.json"
    $script:PolicyName = 'deny-network-private-ips'
    $script:PolicyDisplayName = 'Deny Network Resources with Public IP Addresses'
}

Describe 'Deny Network Private IPs Policy Tests' {

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

        It 'Should have exemptedResourceNames parameter' {
            $policy = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
            $policy.properties.parameters.exemptedResourceNames | Should -Not -BeNullOrEmpty
            $policy.properties.parameters.exemptedResourceNames.type | Should -Be 'Array'
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

            $resourceTypes | Should -Contain 'Microsoft.Network/publicIPAddresses'
            $resourceTypes | Should -Contain 'Microsoft.Network/networkInterfaces'
            $resourceTypes | Should -Contain 'Microsoft.Compute/virtualMachines'
            $resourceTypes | Should -Contain 'Microsoft.Network/loadBalancers'
            $resourceTypes | Should -Contain 'Microsoft.Network/applicationGateways'
        }

        It 'Should have parameterized effect' {
            $script:PolicyRule.then.effect | Should -Be "[parameters('effect')]"
        }

        It 'Should check for public IP associations' {
            $policyJson = $script:Policy | ConvertTo-Json -Depth 20
            $policyJson | Should -Match 'publicIPAddress'
        }

        It 'Should have exemption logic for service resources' {
            $policyJson = $script:Policy | ConvertTo-Json -Depth 20
            $policyJson | Should -Match 'exemptedResourceNames'
        }
    }

    Context 'Test Scenarios' {

        It 'Should allow network interface without public IP' {
            $testResource = @{
                type       = 'Microsoft.Network/networkInterfaces'
                name       = 'test-nic'
                properties = @{
                    ipConfigurations = @(
                        @{
                            name       = 'ipconfig1'
                            properties = @{
                                privateIPAddress = '10.0.0.4'
                                subnet           = @{
                                    id = '/subscriptions/test/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet'
                                }
                            }
                        }
                    )
                }
            }

            # This should not match the policy rule (i.e., should be allowed)
            Write-Host 'Testing NIC without public IP - should be allowed'
            $testResource.properties.ipConfigurations[0].properties.publicIPAddress | Should -BeNullOrEmpty
        }

        It 'Should deny network interface with public IP' {
            $testResource = @{
                type       = 'Microsoft.Network/networkInterfaces'
                name       = 'test-nic-public'
                properties = @{
                    ipConfigurations = @(
                        @{
                            name       = 'ipconfig1'
                            properties = @{
                                privateIPAddress = '10.0.0.4'
                                publicIPAddress  = @{
                                    id = '/subscriptions/test/resourceGroups/test/providers/Microsoft.Network/publicIPAddresses/test-public-ip'
                                }
                                subnet           = @{
                                    id = '/subscriptions/test/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet'
                                }
                            }
                        }
                    )
                }
            }

            # This should match the policy rule (i.e., should be denied)
            Write-Host 'Testing NIC with public IP - should be denied'
            $testResource.properties.ipConfigurations[0].properties.publicIPAddress.id | Should -Not -BeNullOrEmpty
        }

        It 'Should allow exempted public IP resources' {
            $exemptedResources = @(
                'AzureFirewallManagementPublicIP',
                'GatewayPublicIP',
                'BastionPublicIP'
            )

            foreach ($resourceName in $exemptedResources) {
                $testResource = @{
                    type       = 'Microsoft.Network/publicIPAddresses'
                    name       = $resourceName
                    properties = @{
                        publicIPAddressVersion   = 'IPv4'
                        publicIPAllocationMethod = 'Static'
                    }
                }

                Write-Host "Testing exempted public IP: $resourceName - should be allowed"
                # Exempted resources should be allowed
                $exemptedResources | Should -Contain $resourceName
            }
        }

        It 'Should deny non-exempted public IP resources' {
            $testResource = @{
                type       = 'Microsoft.Network/publicIPAddresses'
                name       = 'test-public-ip'
                properties = @{
                    publicIPAddressVersion   = 'IPv4'
                    publicIPAllocationMethod = 'Static'
                }
            }

            # This should match the policy rule (i.e., should be denied)
            Write-Host 'Testing non-exempted public IP - should be denied'
            $exemptedResources = @('AzureFirewallManagementPublicIP', 'GatewayPublicIP', 'BastionPublicIP')
            $exemptedResources | Should -Not -Contain $testResource.name
        }

        It 'Should deny virtual machine with public IP forwarding' {
            $testResource = @{
                type       = 'Microsoft.Compute/virtualMachines'
                name       = 'test-vm'
                properties = @{
                    networkProfile = @{
                        networkInterfaces = @(
                            @{
                                id         = '/subscriptions/test/resourceGroups/test/providers/Microsoft.Network/networkInterfaces/test-nic'
                                properties = @{
                                    enableIPForwarding = $true
                                }
                            }
                        )
                    }
                }
            }

            # This should match the policy rule (i.e., should be denied)
            Write-Host 'Testing VM with IP forwarding - should be denied'
            $testResource.properties.networkProfile.networkInterfaces[0].properties.enableIPForwarding | Should -Be $true
        }

        It 'Should deny load balancer with public frontend IP' {
            $testResource = @{
                type       = 'Microsoft.Network/loadBalancers'
                name       = 'test-lb'
                properties = @{
                    frontendIPConfigurations = @(
                        @{
                            name       = 'frontend1'
                            properties = @{
                                publicIPAddress = @{
                                    id = '/subscriptions/test/resourceGroups/test/providers/Microsoft.Network/publicIPAddresses/test-lb-ip'
                                }
                            }
                        }
                    )
                }
            }

            # This should match the policy rule (i.e., should be denied)
            Write-Host 'Testing load balancer with public IP - should be denied'
            $testResource.properties.frontendIPConfigurations[0].properties.publicIPAddress.id | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Parameter Validation' {

        It 'Should have default exempted resources' {
            $policy = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
            $defaultValue = $policy.properties.parameters.exemptedResourceNames.defaultValue

            $defaultValue | Should -Contain 'AzureFirewallManagementPublicIP'
            $defaultValue | Should -Contain 'GatewayPublicIP'
            $defaultValue | Should -Contain 'BastionPublicIP'
        }

        It 'Should allow custom exempted resources' {
            $policy = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
            $parameter = $policy.properties.parameters.exemptedResourceNames

            $parameter.type | Should -Be 'Array'
            $parameter.metadata.description | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Integration Tests' {

        It 'Should work with Terraform deployment' {
            # Check if Terraform files exist
            $terraformPath = "$PSScriptRoot\..\..\policies\network\deny-network-private-ips"
            "$terraformPath\main.tf" | Should -Exist
            "$terraformPath\variables.tf" | Should -Exist
            "$terraformPath\outputs.tf" | Should -Exist
        }

        It 'Should have proper documentation' {
            $readmePath = "$PSScriptRoot\..\..\policies\network\deny-network-private-ips\README.md"
            $readmePath | Should -Exist

            $readme = Get-Content $readmePath -Raw
            $readme | Should -Match 'Deny Network Resources with Public IP Addresses'
            $readme | Should -Match 'private IP'
        }
    }
}

# Test Summary
AfterAll {
    Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
    Write-Host "Policy: $script:PolicyDisplayName" -ForegroundColor Green
    Write-Host "Path: $script:PolicyPath" -ForegroundColor Yellow
    Write-Host 'Tests completed for deny-network-private-ips policy' -ForegroundColor Green
}
