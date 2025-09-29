# Deny VNET External DNS - Azure Policy

## Overview

This Azure Policy ensures that Virtual Networks (VNETs) use DNS servers within their address space rather than external DNS servers. This policy implements the security recommendation from Checkov policy `CKV_AZURE_183`.

## Policy Details

- **Policy Name**: `deny-vnet-external-dns`
- **Display Name**: Deny VNET External DNS
- **Category**: Network
- **Policy Type**: Custom
- **Mode**: All
- **Checkov ID**: CKV_AZURE_183

## Description

Using external DNS servers can create security risks and dependencies on external services. This policy ensures that:

- Virtual Networks use DNS servers that are within their configured address space
- DNS servers are not external to the VNET, reducing security risks
- Dependencies on external DNS services are minimized
- Local DNS resolution is preferred for security and performance

## Policy Rule Logic

The policy evaluates Virtual Networks and:

1. **Checks** if custom DNS servers are configured (`dhcpOptions.dnsServers`)
2. **Validates** that all configured DNS servers are within the VNET's address space
3. **Denies/Audits** VNETs that have DNS servers outside their address prefixes
4. **Allows** VNETs with no custom DNS servers (use Azure default) or with local DNS servers

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `effect` | String | `Deny` | Policy effect: `Audit`, `Deny`, or `Disabled` |

## Compliance

### Compliant Resources

- Virtual Networks without custom DNS servers (using Azure default DNS)
- Virtual Networks with DNS servers within their address space
- Virtual Networks with DNS servers in any of their configured address prefixes

### Non-Compliant Resources

- Virtual Networks with DNS servers outside their address space
- Virtual Networks using external DNS servers (e.g., 8.8.8.8, 1.1.1.1)
- Virtual Networks with mixed DNS servers (some internal, some external)

## Examples

### Compliant VNET Configuration

```hcl
resource "azurerm_virtual_network" "compliant" {
  name                = "compliant-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  dns_servers = ["10.0.0.4", "10.0.0.5"]  # DNS servers within address space
}

# Or using Azure default DNS (no dns_servers specified)
resource "azurerm_virtual_network" "compliant_default" {
  name                = "compliant-default-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  # No dns_servers specified - uses Azure default DNS
}
```

### Non-Compliant VNET Configuration

```hcl
resource "azurerm_virtual_network" "non_compliant" {
  name                = "non-compliant-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  dns_servers = ["8.8.8.8", "1.1.1.1"]  # External DNS servers - NOT COMPLIANT
}
```

## Deployment

### Using Terraform

```hcl
module "deny_vnet_external_dns_policy" {
  source = "./policies/network/deny-vnet-external-dns"

  policy_name         = "deny-vnet-external-dns"
  policy_display_name = "Deny VNET External DNS"
  policy_description  = "Ensure Virtual Networks use DNS servers within their address space"
  policy_category     = "Network"
  policy_version      = "1.0.0"
}
```

### Using Azure CLI

```bash
# Create the policy definition
az policy definition create \
  --name "deny-vnet-external-dns" \
  --display-name "Deny VNET External DNS" \
  --description "Ensure Virtual Networks use DNS servers within their address space" \
  --rules rule.json \
  --params parameters.json \
  --mode All

# Assign the policy
az policy assignment create \
  --name "deny-vnet-external-dns-assignment" \
  --display-name "Deny VNET External DNS Assignment" \
  --policy "deny-vnet-external-dns" \
  --scope "/subscriptions/{subscription-id}"
```

## Testing

### Test Cases

1. **VNET with local DNS servers** - Should be compliant
2. **VNET with external DNS servers** - Should be non-compliant
3. **VNET with mixed DNS servers** - Should be non-compliant
4. **VNET without DNS servers** - Should be compliant (uses Azure default)
5. **VNET with multiple address spaces** - DNS servers should be in any address space

### Validation Script

```bash
#!/bin/bash
# Test the policy with different VNET configurations

# Test 1: Compliant VNET with local DNS
echo "Testing compliant VNET with local DNS..."
az deployment group create \
    --resource-group test-rg \
    --template-file test-compliant-vnet.json

# Test 2: Non-compliant VNET with external DNS
echo "Testing non-compliant VNET with external DNS..."
az deployment group create \
    --resource-group test-rg \
    --template-file test-non-compliant-vnet.json
```

## Related Policies

- [Deny Network No NSG](../deny-network-no-nsg/README.md) - CKV2_AZURE_31
- [Deny Network Private IPs](../deny-network-private-ips/README.md) - CKV_AZURE_119

## References

- [Checkov Policy CKV_AZURE_183](https://github.com/bridgecrewio/checkov/blob/main/checkov/terraform/checks/resource/azure/VnetLocalDNS.py)
- [Azure Virtual Network DNS](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-name-resolution-for-vms-and-role-instances)
- [Azure Private DNS Zones](https://docs.microsoft.com/en-us/azure/dns/private-dns-overview)
- [Azure Policy Definition Structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)

## Changelog

### Version 1.0.0

- Initial policy creation
- Implements CKV_AZURE_183 compliance
- Supports Audit, Deny, and Disabled effects
- Validates DNS servers against all VNET address prefixes

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.46.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_policy_definition.deny_vnet_external_dns](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The management group ID where the policy definition will be created | `string` | `null` | no |
| <a name="input_policy_category"></a> [policy\_category](#input\_policy\_category) | The category of the Azure Policy Definition | `string` | `"Network"` | no |
| <a name="input_policy_description"></a> [policy\_description](#input\_policy\_description) | The description of the Azure Policy Definition for denying VNET external DNS | `string` | `"This policy ensures that Virtual Networks use DNS servers within their address space rather than external DNS servers to improve security and reduce dependencies on external services. Corresponds to Checkov policy CKV_AZURE_183."` | no |
| <a name="input_policy_display_name"></a> [policy\_display\_name](#input\_policy\_display\_name) | The display name of the Azure Policy Definition for denying VNET external DNS | `string` | `"Deny VNET External DNS"` | no |
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | The name of the Azure Policy Definition for denying VNET external DNS | `string` | `"deny-vnet-external-dns"` | no |
| <a name="input_policy_version"></a> [policy\_version](#input\_policy\_version) | The version of the Azure Policy Definition | `string` | `"1.0.0"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_checkov_id"></a> [checkov\_id](#output\_checkov\_id) | The Checkov policy ID for security compliance tracking |
| <a name="output_policy_description"></a> [policy\_description](#output\_policy\_description) | The description of the Azure Policy Definition for denying VNET external DNS |
| <a name="output_policy_display_name"></a> [policy\_display\_name](#output\_policy\_display\_name) | The display name of the Azure Policy Definition for denying VNET external DNS |
| <a name="output_policy_id"></a> [policy\_id](#output\_policy\_id) | The ID of the Azure Policy Definition for denying VNET external DNS |
| <a name="output_policy_metadata"></a> [policy\_metadata](#output\_policy\_metadata) | The metadata of the Azure Policy Definition for denying VNET external DNS |
| <a name="output_policy_name"></a> [policy\_name](#output\_policy\_name) | The name of the Azure Policy Definition for denying VNET external DNS |
<!-- END_TF_DOCS -->
