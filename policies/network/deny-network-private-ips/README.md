# Deny Network Resources with Public IP Addresses Policy

## Overview

This Azure Policy denies the creation of network resources that use public IP addresses. It enforces the use of private IP addresses only, ensuring that all network resources remain within the private network boundaries for enhanced security and compliance.

## Policy Details

### What it does

- **Denies** creation of public IP address resources (with exemptions)
- **Denies** network interfaces with public IP associations
- **Denies** virtual machines with public IP configurations
- **Denies** load balancers with public frontend IP configurations
- **Denies** application gateways with public frontend IP configurations
- **Allows** exempted resources for specific Azure services

### Resources Targeted

- `Microsoft.Network/publicIPAddresses`
- `Microsoft.Network/networkInterfaces`
- `Microsoft.Compute/virtualMachines`
- `Microsoft.Network/loadBalancers`
- `Microsoft.Network/applicationGateways`

### Default Exemptions

The following resource names are exempted by default as they are required for specific Azure services:

- `AzureFirewallManagementPublicIP` - Required for Azure Firewall management
- `GatewayPublicIP` - Required for VPN Gateway and ExpressRoute Gateway
- `BastionPublicIP` - Required for Azure Bastion service

## Policy Logic

### For Public IP Addresses

```json
{
  "allOf": [
    {
      "field": "type",
      "equals": "Microsoft.Network/publicIPAddresses"
    },
    {
      "not": {
        "field": "name",
        "in": "[parameters('exemptedResourceNames')]"
      }
    }
  ]
}
```

### For Network Interfaces

```json
{
  "allOf": [
    {
      "field": "type",
      "equals": "Microsoft.Network/networkInterfaces"
    },
    {
      "count": {
        "field": "Microsoft.Network/networkInterfaces/ipConfigurations[*]",
        "where": {
          "field": "Microsoft.Network/networkInterfaces/ipConfigurations[*].publicIPAddress.id",
          "exists": "true"
        }
      },
      "greater": 0
    }
  ]
}
```

### For Virtual Machines

```json
{
  "allOf": [
    {
      "field": "type",
      "equals": "Microsoft.Compute/virtualMachines"
    },
    {
      "count": {
        "field": "Microsoft.Compute/virtualMachines/networkProfile.networkInterfaces[*]",
        "where": {
          "anyOf": [
            {
              "field": "Microsoft.Compute/virtualMachines/networkProfile.networkInterfaces[*].properties.ipConfigurations[*].publicIPAddress",
              "exists": "true"
            },
            {
              "field": "Microsoft.Compute/virtualMachines/networkProfile.networkInterfaces[*].properties.enableIPForwarding",
              "equals": "true"
            }
          ]
        }
      },
      "greater": 0
    }
  ]
}
```

## Usage

### Basic Deployment

```hcl
module "deny_network_private_ips" {
  source = "./policies/network/deny-network-private-ips"
}
```

### Advanced Deployment with Assignment

```hcl
module "deny_network_private_ips" {
  source = "./policies/network/deny-network-private-ips"

  create_assignment              = true
  assignment_scope_id            = "/subscriptions/your-subscription-id/resourceGroups/rg-azure-policy-testing"
  policy_assignment_name         = "deny-public-ips-assignment"
  policy_assignment_display_name = "Enforce Private IP Addresses Only"
  policy_assignment_description  = "Custom policy to enforce private IP usage"

  policy_effect = "Deny"  # Enforce the policy

  exempted_resource_names = [
    "AzureFirewallManagementPublicIP",
    "GatewayPublicIP",
    "BastionPublicIP",
    "MyCustomExemptedResource"
  ]
}
```

### Custom Exemptions

```hcl
module "deny_network_private_ips" {
  source = "./policies/network/deny-network-private-ips"

  exempted_resource_names = [
    "AzureFirewallManagementPublicIP",
    "GatewayPublicIP",
    "BastionPublicIP",
    "DMZLoadBalancerPublicIP",
    "WebAppGatewayPublicIP"
  ]
}
```

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `management_group_id` | `string` | `null` | Management group ID for policy definition |
| `create_assignment` | `bool` | `true` | Whether to create a policy assignment |
| `assignment_scope_id` | `string` | `null` | Scope for policy assignment |
| `policy_assignment_name` | `string` | `"deny-network-private-ips-assignment"` | Name for policy assignment |
| `policy_assignment_display_name` | `string` | Auto-generated | Display name for assignment |
| `policy_assignment_description` | `string` | Auto-generated | Description for assignment |
| `assignment_location` | `string` | `"East US"` | Location for policy assignment |
| `policy_effect` | `string` | `"Audit"` | Policy effect (Audit, Deny, Disabled) |
| `exempted_resource_names` | `list(string)` | Azure service resources | List of exempted resource names |
| `environment` | `string` | `"sandbox"` | Environment name |
| `owner` | `string` | `"Policy-Team"` | Owner of the policy |

### Module Outputs

| Name | Description |
|------|-------------|
| `policy_definition_id` | The ID of the created policy definition |
| `policy_definition_name` | The name of the created policy definition |
| `policy_definition_display_name` | The display name of the created policy definition |
| `policy_assignment_id` | The ID of the policy assignment (if created) |
| `policy_assignment_name` | The name of the policy assignment (if created) |
| `policy_assignment_principal_id` | The principal ID of the system assigned identity |

## Testing

Test files are available in the `tests/` directory:

```bash
# Run policy tests
cd tests
./Network.Test-DenyNetworkPrivateIPs.Tests.ps1
```

## Security Considerations

- **Network Isolation**: Ensures all resources use private IP addresses
- **Attack Surface Reduction**: Eliminates direct internet exposure
- **Compliance**: Helps meet regulatory requirements for network security
- **Service Compatibility**: Exempts necessary Azure service resources
- **Zero Trust**: Supports zero trust network architecture principles

## Troubleshooting

### Common Issues

1. **Policy blocks legitimate Azure services**
   - Solution: Add the service resource name to `exempted_resource_names`

2. **Application Gateway or Load Balancer deployment fails**
   - Check if the resource requires public IP for internet-facing scenarios
   - Consider using internal load balancers or application gateways

3. **VPN Gateway deployment fails**
   - Ensure "GatewayPublicIP" is in the exempted resources list
   - VPN Gateways require public IPs for external connectivity

### Debugging

Enable detailed logging in Terraform:

```bash
export TF_LOG=DEBUG
terraform apply
```

Check Azure Activity Log for policy evaluation details in the Azure Portal.

## Use Cases

### Private Network Environments

- **On-premises connectivity**: Ensure all Azure resources use private IPs for hybrid scenarios
- **Internal applications**: Force internal-only applications to use private addressing
- **Development environments**: Prevent accidental exposure of development resources

### Compliance Requirements

- **Regulatory compliance**: Meet requirements that prohibit direct internet exposure
- **Corporate policies**: Enforce organizational network security policies
- **Industry standards**: Align with security frameworks requiring private networks

### Security Hardening

- **Reduced attack surface**: Eliminate direct internet accessibility
- **Network segmentation**: Ensure proper network isolation
- **Defense in depth**: Add policy-level network security controls

## Related Policies

- **Network Security Policies**: `deny-network-no-nsg` (NSG requirements)
- **Storage Policies**: `deny-storage-account-public-access`, `deny-storage-softdelete`
- **Compute Policies**: VM security and configuration policies

## Version History

- **v1.0**: Initial policy creation with comprehensive network resource coverage

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_policy"></a> [policy](#module\_policy) | ../../../modules/azure-policy | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assignment_location"></a> [assignment\_location](#input\_assignment\_location) | Location for the policy assignment (required for system-assigned identity) | `string` | `"East US"` | no |
| <a name="input_assignment_scope_id"></a> [assignment\_scope\_id](#input\_assignment\_scope\_id) | The scope ID for policy assignment (resource group ID) | `string` | `null` | no |
| <a name="input_create_assignment"></a> [create\_assignment](#input\_create\_assignment) | Whether to create a policy assignment | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, test, prod) | `string` | `"sandbox"` | no |
| <a name="input_exempted_resource_names"></a> [exempted\_resource\_names](#input\_exempted\_resource\_names) | List of resource names that are exempt from this policy | `list(string)` | <pre>[<br/>  "AzureFirewallManagementPublicIP",<br/>  "GatewayPublicIP",<br/>  "BastionPublicIP"<br/>]</pre> | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where the policy definition will be created | `string` | `null` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces the policy to deny network resources that use public IP addresses."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Deny Network Resources with Public IP Addresses Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"deny-network-private-ips-assignment"` | no |
| <a name="input_policy_effect"></a> [policy\_effect](#input\_policy\_effect) | The effect of the policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the created policy assignment |
| <a name="output_policy_assignment_identity"></a> [policy\_assignment\_identity](#output\_policy\_assignment\_identity) | The identity of the created policy assignment |
| <a name="output_policy_assignment_name"></a> [policy\_assignment\_name](#output\_policy\_assignment\_name) | The name of the created policy assignment |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the created policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the created policy definition |
<!-- END_TF_DOCS -->
