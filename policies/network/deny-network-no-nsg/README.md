# Deny Network Resources Without NSG Policy

## Overview

This Azure Policy denies the creation of network resources (subnets and network interfaces) that do not have an associated Network Security Group (NSG). The policy ensures that all network resources have appropriate security controls in place while providing exemptions for Azure service subnets that don't require NSGs.

## Policy Details

### What it does

- **Denies** creation of subnets without NSG associations
- **Denies** creation of network interfaces without NSG associations
- **Allows** exempted Azure service subnets (GatewaySubnet, AzureFirewallSubnet, etc.)
- **Evaluates** resources at creation and update time

### Resources Targeted

- `Microsoft.Network/virtualNetworks/subnets`
- `Microsoft.Network/networkInterfaces`

### Default Exemptions

The following subnet names are exempted by default as they are Azure service subnets that don't support NSGs:

- `GatewaySubnet` - Used by VPN Gateway and ExpressRoute Gateway
- `AzureFirewallSubnet` - Used by Azure Firewall
- `AzureFirewallManagementSubnet` - Used by Azure Firewall management
- `RouteServerSubnet` - Used by Azure Route Server  
- `AzureBastionSubnet` - Used by Azure Bastion

## Policy Logic

### For Subnets

```json
{
  "allOf": [
    {
      "field": "type",
      "equals": "Microsoft.Network/virtualNetworks/subnets"
    },
    {
      "not": {
        "field": "name",
        "in": "[parameters('exemptedResourceNames')]"
      }
    },
    {
      "anyOf": [
        {
          "field": "Microsoft.Network/virtualNetworks/subnets/networkSecurityGroup.id",
          "exists": "false"
        },
        {
          "field": "Microsoft.Network/virtualNetworks/subnets/networkSecurityGroup.id",
          "equals": ""
        }
      ]
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
      "anyOf": [
        {
          "field": "Microsoft.Network/networkInterfaces/networkSecurityGroup.id",
          "exists": "false"
        },
        {
          "field": "Microsoft.Network/networkInterfaces/networkSecurityGroup.id",
          "equals": ""
        }
      ]
    }
  ]
}
```

## Usage

### Basic Deployment

```hcl
module "deny_network_no_nsg" {
  source = "./policies/network/deny-network-no-nsg"
  
  policy_name = "deny-network-no-nsg"
}
```

### Advanced Deployment with Assignment

```hcl
module "deny_network_no_nsg" {
  source = "./policies/network/deny-network-no-nsg"
  
  policy_name         = "deny-network-no-nsg"
  policy_display_name = "Require NSG on Network Resources"
  policy_description  = "Custom policy to enforce NSG requirements"
  
  create_assignment = true
  assignment_scope  = "/subscriptions/your-subscription-id/resourceGroups/rg-azure-policy-testing"
  
  assignment_parameters = {
    exemptedResourceNames = [
      "GatewaySubnet",
      "AzureFirewallSubnet",
      "CustomExemptedSubnet"
    ]
  }
}
```

### Custom Exemptions

```hcl
module "deny_network_no_nsg" {
  source = "./policies/network/deny-network-no-nsg"
  
  policy_name = "deny-network-no-nsg"
  
  exempted_resource_names = [
    "GatewaySubnet",
    "AzureFirewallSubnet",
    "MySpecialSubnet"
  ]
}
```

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `policy_name` | `string` | **Required** | Name of the policy definition |
| `policy_display_name` | `string` | `"Deny Network Resources Without NSG"` | Display name for the policy |
| `policy_description` | `string` | Auto-generated | Description of the policy |
| `exempted_resource_names` | `list(string)` | Azure service subnets | List of subnet names to exempt |
| `create_assignment` | `bool` | `false` | Whether to create a policy assignment |
| `assignment_scope` | `string` | `null` | Scope for policy assignment |
| `assignment_parameters` | `map(any)` | `{}` | Parameters for policy assignment |

## Outputs

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
./Test-DenyNetworkNoNSG.ps1
```

## Security Considerations

- **Network Segmentation**: Ensures all network resources have security controls
- **Defense in Depth**: Adds a layer of security at the Azure Policy level
- **Service Compatibility**: Exempts Azure service subnets that don't support NSGs
- **Compliance**: Helps meet security compliance requirements

## Troubleshooting

### Common Issues

1. **Policy blocks legitimate Azure services**
   - Solution: Add the service subnet name to `exempted_resource_names`

2. **Policy doesn't apply to existing resources**
   - This policy only evaluates at creation/update time
   - Use Azure Policy compliance scans to evaluate existing resources

3. **Assignment fails with permissions error**
   - Ensure the principal has `Resource Policy Contributor` role
   - Check that the assignment scope is valid

### Debugging

Enable detailed logging in Terraform:

```bash
export TF_LOG=DEBUG
terraform apply
```

Check Azure Activity Log for policy evaluation details in the Azure Portal.

## Related Policies

- **Storage Policies**: `deny-storage-account-public-access`, `deny-storage-softdelete`
- **Network Policies**: Additional network security policies in development

## Version History

- **v1.0**: Initial policy creation with subnet and network interface support
