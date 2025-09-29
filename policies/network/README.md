# Network Security Policies

This directory contains Azure Policy definitions for network security compliance and best practices.

## Available Policies

### 1. Deny Network No NSG (CKV2_AZURE_31)

- **Path**: `deny-network-no-nsg/`
- **Purpose**: Ensure VNET subnet is configured with a Network Security Group (NSG)
- **Effect**: Deny/Audit subnets without NSG association
- **Resource Type**: `Microsoft.Network/virtualNetworks/subnets`

### 2. Deny Network Private IPs (CKV_AZURE_119)

- **Path**: `deny-network-private-ips/`
- **Purpose**: Ensure that Network Interfaces don't use public IPs
- **Effect**: Deny/Audit network interfaces with public IP addresses
- **Resource Type**: `Microsoft.Network/networkInterfaces`

### 3. Deny VNET External DNS (CKV_AZURE_183)

- **Path**: `deny-vnet-external-dns/`
- **Purpose**: Ensure that VNET uses local DNS addresses
- **Effect**: Deny/Audit VNETs using external DNS servers
- **Resource Type**: `Microsoft.Network/virtualNetworks`

## Policy Categories

All network policies are categorized under:

- **Category**: Network
- **Compliance Framework**: Checkov Security Policies
- **Policy Type**: Custom

## Usage

### Individual Policy Deployment

```hcl
module "network_policy" {
  source = "./policies/network/deny-vnet-external-dns"

  policy_name         = "my-vnet-dns-policy"
  policy_display_name = "My VNET DNS Policy"
  policy_category     = "Network"
}
```

### Initiative-based Deployment

```hcl
module "network_initiative" {
  source = "./initiatives/network"

  initiative_name         = "network-security-initiative"
  initiative_display_name = "Network Security Initiative"
  initiative_description  = "Comprehensive network security policies"
}
```

## Compliance Mapping

| Policy | Checkov ID | Resource Type | Security Domain |
|--------|------------|---------------|-----------------|
| deny-network-no-nsg | CKV2_AZURE_31 | Subnet | Network Segmentation |
| deny-network-private-ips | CKV_AZURE_119 | Network Interface | Public Access Control |
| deny-vnet-external-dns | CKV_AZURE_183 | Virtual Network | DNS Security |

## Best Practices

1. **Network Segmentation**: Use NSGs on all subnets to control traffic flow
2. **Minimize Public Exposure**: Avoid public IP addresses on network interfaces unless required
3. **DNS Security**: Use local DNS servers within VNET address space to reduce external dependencies
4. **Policy Effects**:

   - Use `Audit` for monitoring and compliance reporting
   - Use `Deny` for active enforcement in production environments
   - Use `Disabled` for temporary policy suspension during maintenance

## Related Documentation

- [Azure Network Security Groups](https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Azure Virtual Network DNS](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-name-resolution-for-vms-and-role-instances)
- [Azure Policy for Network Resources](https://docs.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies#network)
