# Azure Policy: Function Apps Must Disable Public Network Access

## Overview

This Azure Policy enforces that Azure Function Apps must have **public network access disabled** (`publicNetworkAccess = Disabled`). This is a critical security control and a prerequisite for implementing private endpoint connectivity.

## ⚠️ Important Limitation

**Azure Policy Platform Limitation**: The Azure Policy alias for `Microsoft.Web/sites/privateEndpointConnections[*]` does not exist, which means **Azure Policy cannot directly verify the presence of private endpoint connections**.

This policy therefore focuses on what can be enforced:

- ✅ **Public network access must be disabled**
- ❌ **Cannot verify actual private endpoint connections exist** (requires alternative tooling)

### Alternative Approaches for Private Endpoint Verification

To verify actual private endpoint connections, use:

1. **Azure Resource Graph Queries**:

   ```kusto
   Resources
   | where type == "microsoft.web/sites"
   | where kind == "functionapp"
   | extend privateEndpoints = properties.privateEndpointConnections
   | where isnull(privateEndpoints) or array_length(privateEndpoints) == 0
   ```

2. **PowerShell Scripts**: Query `Get-AzWebApp` and check `PrivateEndpointConnections` property

3. **Azure Monitor/Defender**: Set up alerts for Function Apps without private endpoints

## Policy Details

### What This Policy Does

- **Denies** Function Apps where `publicNetworkAccess` is not set to `Disabled`
- **Denies** Function Apps where the `publicNetworkAccess` property is missing/not configured
- **Allows** exemptions for specific Function Apps or Resource Groups

### What This Policy Does NOT Do

- ❌ Does not verify private endpoint connections actually exist
- ❌ Does not check private endpoint configuration or settings
- ❌ Does not validate DNS configuration for private endpoints

> **Note**: The policy name references "private endpoint" because disabling public network access is a prerequisite for private endpoint use, but the policy cannot enforce the actual presence of private endpoints due to Azure Policy platform limitations.

### Resources Targeted

- `Microsoft.Web/sites` with `kind` = `functionapp`

### Key Features

- **Public Network Access Control**: Enforces that Function Apps must have public network access disabled
- **Network Isolation Foundation**: Provides prerequisite configuration for private endpoint implementation
- **Flexible Exemptions**: Exclude specific Function Apps or entire resource groups
- **Security Focused**: Helps meet network isolation and data protection requirements
- **Clear Limitations**: Documented platform constraints and alternative validation approaches

## Policy Logic

The policy evaluates Function Apps with the following simplified conditions:

```json
{
  "allOf": [
    {
      "field": "type",
      "equals": "Microsoft.Web/sites"
    },
    {
      "field": "kind",
      "equals": "functionapp"
    },
    {
      "not": {
        "field": "name",
        "in": "[parameters('exemptedFunctionApps')]"
      }
    },
    {
      "not": {
        "field": "Microsoft.Web/sites/resourceGroup",
        "in": "[parameters('exemptedResourceGroups')]"
      }
    },
    {
      "anyOf": [
        {
          "field": "Microsoft.Web/sites/publicNetworkAccess",
          "notEquals": "Disabled"
        },
        {
          "field": "Microsoft.Web/sites/publicNetworkAccess",
          "exists": "false"
        }
      ]
    }
  ]
}
```

The policy triggers when:

1. A Function App is being created or updated
2. The Function App is not in the exempted list
3. The Function App's resource group is not in the exempted list
4. Public network access is NOT explicitly set to `"Disabled"` OR the property doesn't exist

## Usage

### Basic Deployment

```hcl
module "deny_function_app_no_private_endpoint" {
  source = "./policies/function-app/deny-function-app-no-private-endpoint"

  environment = "production"
  owner       = "Security-Team"
}
```

### Advanced Deployment with Assignment

```hcl
module "deny_function_app_no_private_endpoint" {
  source = "./policies/function-app/deny-function-app-no-private-endpoint"

  environment = "production"
  owner       = "Security-Team"

  create_assignment = true
  assignment_scope_id = "/subscriptions/your-subscription-id/resourceGroups/rg-production"
  policy_effect = "Deny"

  exempted_function_apps = [
    "legacy-public-function",
    "development-test-function"
  ]

  exempted_resource_groups = [
    "rg-legacy-systems"
  ]
}
```

### Audit Mode Deployment

```hcl
module "deny_function_app_no_private_endpoint" {
  source = "./policies/function-app/deny-function-app-no-private-endpoint"

  environment = "sandbox"
  policy_effect = "Audit"

  create_assignment = true
  assignment_scope_id = "/subscriptions/your-subscription-id"
}
```

### Management Group Deployment

```hcl
module "deny_function_app_no_private_endpoint" {
  source = "./policies/function-app/deny-function-app-no-private-endpoint"

  management_group_id = "/providers/Microsoft.Management/managementGroups/corp"
  environment = "enterprise"

  create_assignment = true
  assignment_scope_id = "/providers/Microsoft.Management/managementGroups/corp"
}
```

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `environment` | `string` | `"sandbox"` | Environment name for tagging |
| `owner` | `string` | `"Policy-Team"` | Owner of the policy for governance |
| `management_group_id` | `string` | `null` | Management group where policy is defined |
| `create_assignment` | `bool` | `true` | Whether to create a policy assignment |
| `assignment_scope_id` | `string` | `null` | Scope for policy assignment |
| `assignment_location` | `string` | `"East US"` | Location for policy assignment identity |
| `policy_assignment_name` | `string` | Auto-generated | Name of the policy assignment |
| `policy_assignment_display_name` | `string` | Auto-generated | Display name for the assignment |
| `policy_assignment_description` | `string` | Auto-generated | Description of the assignment |
| `policy_effect` | `string` | `"Audit"` | Policy effect (Audit, Deny, Disabled) |
| `exempted_function_apps` | `list(string)` | `[]` | Function Apps exempt from policy |
| `exempted_resource_groups` | `list(string)` | `[]` | Resource groups exempt from policy |

## Security Benefits

### Network Isolation

- **Private Connectivity**: Ensures all Function App access is through private virtual network connections
- **Public Internet Protection**: Prevents exposure of Function Apps to the public internet
- **Data Exfiltration Prevention**: Limits data leakage risks through network isolation

### Compliance & Governance

- **Security Standards**: Helps meet organizational network security requirements
- **Zero Trust Architecture**: Supports zero trust network model implementation
- **Risk Reduction**: Minimizes attack surface by eliminating public endpoints

### Threat Mitigation

- **Unauthorized Access Prevention**: Blocks public internet-based attacks
- **DDoS Protection**: Eliminates public endpoints vulnerable to DDoS attacks
- **Network Segmentation**: Enforces proper network segmentation practices

## Private Endpoint Configuration

Function Apps support private endpoints for secure connectivity:

### Private Endpoint Setup

```hcl
resource "azurerm_function_app" "example" {
  name                = "secure-function-app"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  # Disable public network access
  public_network_access_enabled = false
}

# Create private endpoint
resource "azurerm_private_endpoint" "example" {
  name                = "function-app-private-endpoint"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.example.id

  private_service_connection {
    name                           = "function-app-privateserviceconnection"
    private_connection_resource_id = azurerm_function_app.example.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}
```

### Azure CLI Configuration

```bash
# Disable public network access
az functionapp update \
  --name <function-app-name> \
  --resource-group <resource-group> \
  --set publicNetworkAccess=Disabled

# Create private endpoint
az network private-endpoint create \
  --name function-app-pe \
  --resource-group <resource-group> \
  --vnet-name <vnet-name> \
  --subnet <subnet-name> \
  --private-connection-resource-id <function-app-id> \
  --group-id sites \
  --connection-name function-app-connection
```

## Common Use Cases

### 1. Enterprise Production Environment

```hcl
# Strict private endpoint enforcement
policy_effect = "Deny"
exempted_function_apps = []  # No exemptions
```

### 2. Development with Public Access

```hcl
# Allow public access for specific development functions
exempted_function_apps = [
  "dev-testing-function",
  "local-development-function"
]
exempted_resource_groups = [
  "rg-development"
]
```

### 3. Gradual Migration

```hcl
# Audit mode during migration planning
policy_effect = "Audit"  # Switch to "Deny" after migration
```

## Implementation Best Practices

### 1. Phased Rollout

```hcl
# Phase 1: Audit mode to assess impact
policy_effect = "Audit"

# Phase 2: Enable for new Function Apps
policy_effect = "Deny"
```

### 2. Private Endpoint Planning

- Design VNet architecture for private endpoints
- Plan subnet allocation for private endpoints
- Configure private DNS zones for name resolution
- Set up VNet peering for connectivity

### 3. Performance Considerations

- Private endpoints add minimal latency
- Plan for private endpoint scaling
- Monitor connection limits
- Implement proper network routing

### 4. Strategic Exemptions

Consider exempting:

- Development and testing environments
- Legacy systems during migration
- Functions requiring public webhooks
- Integration testing environments

### 5. Monitoring and Compliance

- Set up Azure Policy compliance dashboards
- Configure alerts for policy violations
- Monitor private endpoint health
- Regular review of exempted resources

## Testing

Test files are available in the `tests/` directory:

```bash
# Run unit tests
cd tests/function-app
pwsh -File FunctionApp.Unit-DenyFunctionAppNoPrivateEndpoint.Tests.ps1

# Run integration tests
pwsh -File FunctionApp.Integration-DenyFunctionAppNoPrivateEndpoint.Tests.ps1
```

## Security Considerations

### Network Security

- Use Network Security Groups (NSGs) with private endpoints
- Implement VNet service endpoints where applicable
- Configure Azure Firewall for additional protection
- Monitor network traffic patterns

### Access Control

- Implement Azure RBAC for private endpoint management
- Use Azure Policy for governance
- Regular access reviews
- Least privilege principle for network access

### DNS Configuration

- Configure private DNS zones for name resolution
- Implement DNS forwarding if needed
- Monitor DNS resolution
- Regular DNS configuration audits

## Troubleshooting

### Common Issues

1. **Policy blocks legitimate public Function Apps**
   - Solution: Add the Function App to `exempted_function_apps`
   - Alternative: Move to a dedicated resource group and exempt the group

2. **Private endpoint connection issues**
   - Verify subnet configuration and availability
   - Check NSG rules allow private endpoint traffic
   - Validate private DNS zone configuration
   - Ensure proper VNet peering setup

3. **Performance concerns**
   - Monitor private endpoint latency
   - Check VNet routing configuration
   - Verify ExpressRoute or VPN Gateway performance
   - Review subnet sizing

4. **Migration challenges**
   - Plan migration timeline with stakeholders
   - Use audit mode initially
   - Test private endpoint connectivity
   - Implement gradual rollout

### Debugging Steps

1. **Check Policy Compliance**

   ```bash
   # Azure CLI
   az policy state list --policy-definition-name "deny-function-app-no-private-endpoint"
   ```

2. **Review Function App Configuration**

   ```bash
   # Check public network access settings
   az functionapp show \
     --name <function-app-name> \
     --resource-group <rg-name> \
     --query "publicNetworkAccess"

   # Check private endpoint connections
   az network private-endpoint-connection list \
     --name <function-app-name> \
     --resource-group <rg-name> \
     --type Microsoft.Web/sites
   ```

3. **Test Private Endpoint Connectivity**

   ```bash
   # Test DNS resolution
   nslookup <function-app-name>.azurewebsites.net

   # Test connectivity from VM in VNet
   curl https://<function-app-name>.azurewebsites.net/api/function
   ```

4. **Validate Configuration**

   ```bash
   # Terraform validation
   terraform validate policies/function-app/deny-function-app-no-private-endpoint/
   terraform plan
   ```

## Integration Examples

### With CI/CD Pipelines

```yaml
# Azure DevOps Pipeline
stages:
  - stage: PolicyValidation
    jobs:
      - job: ValidateFunctionAppPrivateEndpointPolicy
        steps:
          - script: |
              terraform validate policies/function-app/deny-function-app-no-private-endpoint/
              echo "Function App private endpoint policy validated"
```

### With Secure Function App Deployment

```hcl
# Function App with private endpoint
resource "azurerm_function_app" "example" {
  name                = "secure-function-app"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  public_network_access_enabled = false

  site_config {
    vnet_route_all_enabled = true
  }
}

# Private endpoint
resource "azurerm_private_endpoint" "example" {
  name                = "function-pe"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.example.id

  private_service_connection {
    name                           = "function-privateconnection"
    private_connection_resource_id = azurerm_function_app.example.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

# Private DNS zone
resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "function-dns-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
}
```

### With Monitoring

```hcl
# Monitor private endpoint policy compliance
resource "azurerm_monitor_activity_log_alert" "function_app_pe_violation" {
  name                = "function-app-pe-policy-violation"
  resource_group_name = var.resource_group_name
  scopes              = [var.subscription_id]
  description         = "Alert when Function App private endpoint policy is violated"

  criteria {
    operation_name = "Microsoft.Authorization/policies/audit/action"
    category       = "Policy"
  }

  action {
    action_group_id = azurerm_monitor_action_group.policy_alerts.id
  }
}
```

## Related Policies

- **Storage Account Private Endpoint Policies**: Similar enforcement for storage
- **Web App Private Endpoint Policies**: Private endpoint enforcement for Web Apps
- **VNet Integration Policies**: VNet integration requirements
- **Network Security Policies**: Comprehensive network security controls

## Version History

- **v1.0**: Initial policy creation with private endpoint enforcement
  - Support for Function App private endpoint validation
  - Public network access control
  - Exemption mechanism for Function Apps and resource groups
  - Comprehensive parameter validation
  - Full Terraform module integration

## Compliance Frameworks

This policy helps meet requirements for:

- **SOC 2**: Network security and access controls
- **ISO 27001**: Information security management
- **NIST**: Network security and segmentation standards
- **PCI DSS**: Network segmentation requirements
- **HIPAA**: Network isolation and data protection
- **GDPR**: Data protection and privacy requirements
- **CIS Controls**: Secure network configuration standards
- **Zero Trust**: Zero trust network architecture principles

## References

- [Azure Functions Private Endpoints](https://learn.microsoft.com/en-us/azure/azure-functions/functions-networking-options)
- [Azure Private Link Documentation](https://learn.microsoft.com/en-us/azure/private-link/)
- [Azure Policy for App Service](https://learn.microsoft.com/en-us/azure/app-service/policy-reference)
- [Function App Public Network Access](https://learn.microsoft.com/en-us/azure/app-service/overview-access-restrictions)

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
| <a name="input_exempted_function_apps"></a> [exempted\_function\_apps](#input\_exempted\_function\_apps) | List of Function App names that are exempt from this policy | `list(string)` | `[]` | no |
| <a name="input_exempted_resource_groups"></a> [exempted\_resource\_groups](#input\_exempted\_resource\_groups) | List of resource group names that are exempt from this policy | `list(string)` | `[]` | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where the policy definition will be created | `string` | `null` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces the policy to deny Function Apps that do not have private endpoints configured."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Deny Function App Without Private Endpoint Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"deny-function-app-no-private-endpoint-assignment"` | no |
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
