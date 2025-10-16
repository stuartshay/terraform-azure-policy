# Deny App Service Plan Without Zone Redundancy

This Azure Policy ensures that App Service Plans are configured with zone redundancy enabled for high availability and resiliency.

## Overview

**Policy Name**: deny-app-service-plan-not-zone-redundant  
**Resource Type**: Microsoft.Web/serverfarms (App Service Plans)  
**Policy Effect**: Deny (configurable: Audit, Deny, Disabled)  
**Checkov Rule**: CKV_AZURE_225  

## Description

This policy denies the creation of Azure App Service Plans that do not have zone redundancy enabled. Zone redundancy distributes App Service Plan instances across multiple availability zones within an Azure region, ensuring your applications remain available even if one availability zone experiences an outage.

## Checkov Alignment

This Azure Policy aligns with and enforces the Checkov security check:

- **Checkov ID**: CKV_AZURE_225
- **Check**: "Ensure the App Service Plan is zone redundant"
- **Resource**: azurerm_service_plan
- **Framework**: Terraform

### Checkov vs Azure Policy Comparison

| Aspect | Checkov (Static Analysis) | Azure Policy (Runtime Enforcement) |
|--------|---------------------------|-------------------------------------|
| **Scope** | Pre-deployment scanning | Runtime creation prevention |
| **Enforcement** | CI/CD pipeline gates | Azure Resource Manager |
| **Coverage** | Terraform configurations | All Azure deployments |
| **Remediation** | Fix code before deployment | Prevent non-compliant resources |

## Security Benefits

- **High Availability**: Ensures applications remain available during datacenter-level failures
- **Business Continuity**: Reduces downtime and service disruptions
- **Compliance**: Meets enterprise requirements for disaster recovery
- **Auto-Scaling**: Zone-redundant plans can scale across multiple zones automatically

## Supported SKU Tiers

Zone redundancy is supported for the following App Service Plan tiers:

- **PremiumV2**: Premium tier with zone redundancy support
- **PremiumV3**: Latest premium tier with enhanced performance
- **PremiumV4**: Newest premium tier with optimal performance
- **IsolatedV2**: Dedicated compute environments with zone redundancy

> **Note**: Basic, Standard, and Free tiers do not support zone redundancy.

## Requirements for Zone Redundancy

1. **SKU Tier**: Must use PremiumV2, PremiumV3, PremiumV4, or IsolatedV2
2. **Instance Count**: Minimum of 2 instances required
3. **Region Support**: Must deploy in a region that supports availability zones
4. **Scale Unit**: Must be on infrastructure that supports availability zones

## Policy Logic

The policy evaluates App Service Plans and denies creation if:

1. Resource type is `Microsoft.Web/serverfarms`
2. SKU tier is in the supported list (PremiumV2, PremiumV3, PremiumV4, IsolatedV2)
3. App Service Plan name is not in the exemption list
4. The `zoneRedundant` property is missing or set to `false`

## Configuration Parameters

### Effect

- **Type**: String
- **Allowed Values**: Audit, Deny, Disabled
- **Default**: Deny
- **Description**: Determines the policy behavior

### Required SKU Tiers

- **Type**: Array
- **Default**: ["PremiumV2", "PremiumV3", "PremiumV4", "IsolatedV2"]
- **Description**: SKU tiers that support zone redundancy

### Exempted App Service Plans

- **Type**: Array
- **Default**: []
- **Description**: App Service Plan names exempt from this policy

### Minimum Instance Count

- **Type**: Integer
- **Default**: 2
- **Description**: Minimum instances required for zone redundancy

## Usage Examples

### Basic Deployment

```hcl
module "app_service_zone_redundancy_policy" {
  source = "./policies/app-service/deny-app-service-plan-not-zone-redundant"

  environment   = "production"
  policy_effect = "Deny"

  assignment_scope_id = "/subscriptions/your-subscription-id/resourceGroups/rg-web-apps"
  assignment_location = "East US"
}
```

### With Exemptions

```hcl
module "app_service_zone_redundancy_policy" {
  source = "./policies/app-service/deny-app-service-plan-not-zone-redundant"

  environment   = "production"
  policy_effect = "Audit"

  exempted_app_service_plans = [
    "legacy-asp-dev",
    "temporary-testing-asp"
  ]

  assignment_scope_id = "/subscriptions/your-subscription-id/resourceGroups/rg-web-apps"
}
```

### Management Group Deployment

```hcl
module "app_service_zone_redundancy_policy" {
  source = "./policies/app-service/deny-app-service-plan-not-zone-redundant"

  management_group_id = "/providers/Microsoft.Management/managementGroups/corp"
  policy_effect      = "Deny"
  environment        = "enterprise"
}
```

## Compliant App Service Plan Examples

### Terraform (Compliant)

```hcl
resource "azurerm_service_plan" "compliant" {
  name                = "asp-web-prod-eus-001"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location

  sku_name         = "P1v3"
  zone_balancing   = true    # Enables zone redundancy
  worker_count     = 3       # Minimum 2 instances required
}
```

### Bicep (Compliant)

```bicep
resource appServicePlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: 'asp-web-prod-eus-001'
  location: location
  sku: {
    name: 'P1v3'
    capacity: 3
  }
  properties: {
    zoneRedundant: true
  }
}
```

## Non-Compliant Examples

### Missing Zone Redundancy

```hcl
resource "azurerm_service_plan" "non_compliant" {
  name                = "asp-web-prod-eus-001"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location

  sku_name     = "P1v3"
  worker_count = 2
  # Missing: zone_balancing = true
}
```

### Explicitly Disabled

```hcl
resource "azurerm_service_plan" "non_compliant" {
  name                = "asp-web-prod-eus-001"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location

  sku_name       = "P1v3"
  zone_balancing = false  # Explicitly disabled
  worker_count   = 2
}
```

## Testing and Validation

### Test Policy Compliance

```bash
# Test with compliant configuration
az appservice plan create \
  --name asp-test-compliant \
  --resource-group rg-test \
  --sku P1v3 \
  --zone-redundant \
  --number-of-workers 2

# Test with non-compliant configuration (should be denied)
az appservice plan create \
  --name asp-test-non-compliant \
  --resource-group rg-test \
  --sku P1v3 \
  --number-of-workers 2
  # Missing --zone-redundant flag
```

### Check Existing Plans

```bash
# Check if existing plan supports zone redundancy
az appservice plan show \
  --name your-app-service-plan \
  --resource-group your-resource-group \
  --query properties.maximumNumberOfZones
```

## Troubleshooting

### Common Issues

1. **SKU Not Supported**
   - Error: Plan creation denied for Basic/Standard tier
   - Solution: Use PremiumV2, PremiumV3, PremiumV4, or IsolatedV2 tier

2. **Region Limitations**
   - Error: Zone redundancy not available in region
   - Solution: Deploy to a region that supports availability zones

3. **Insufficient Instances**
   - Error: Zone redundancy requires minimum 2 instances
   - Solution: Set worker_count to 2 or more

4. **Scale Unit Constraints**
   - Error: Scale unit doesn't support availability zones
   - Solution: Create App Service Plan in a new resource group

### Checking Zone Redundancy Support

```bash
# Check maximum zones supported
az appservice plan show \
  --name your-plan \
  --resource-group your-rg \
  --query properties.maximumNumberOfZones

# Output interpretation:
# > 1: Zone redundancy supported
# = 1: Zone redundancy not supported
```

## Files in this Module

- `rule.json` - Azure Policy definition with zone redundancy validation logic
- `main.tf` - Terraform module configuration for policy deployment
- `variables.tf` - Input variables for policy parameters
- `outputs.tf` - Output values including policy and assignment IDs
- `version.tf` - Terraform version constraints
- `terraform.tfvars.example` - Example configuration file
- `README.md` - This documentation file

## Related Resources

- [Azure App Service Zone Redundancy Documentation](https://learn.microsoft.com/en-us/azure/app-service/configure-zone-redundancy)
- [Azure Policy for App Service Plans](https://learn.microsoft.com/en-us/azure/app-service/policy-reference)
- [Checkov CKV_AZURE_225](https://www.checkov.io/5.Policy%20Index/azure.html)
- [Azure Availability Zones](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Contributing

When modifying this policy:

1. Update the `rule.json` file for policy logic changes
2. Modify variables in `variables.tf` for new parameters
3. Update documentation in this README
4. Test policy with both compliant and non-compliant resources
5. Validate Terraform configuration with `terraform validate`

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.48.0 |

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
| <a name="input_exempted_app_service_plans"></a> [exempted\_app\_service\_plans](#input\_exempted\_app\_service\_plans) | List of App Service Plan names that are exempt from this policy | `list(string)` | `[]` | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where the policy definition will be created | `string` | `null` | no |
| <a name="input_minimum_instance_count"></a> [minimum\_instance\_count](#input\_minimum\_instance\_count) | Minimum number of instances required for zone redundancy (must be 2 or more) | `number` | `2` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces the policy to deny App Service Plans that do not have zone redundancy enabled."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Deny App Service Plan Without Zone Redundancy Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"deny-app-service-plan-not-zone-redundant-assignment"` | no |
| <a name="input_policy_effect"></a> [policy\_effect](#input\_policy\_effect) | The effect of the policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_required_sku_tiers"></a> [required\_sku\_tiers](#input\_required\_sku\_tiers) | List of App Service Plan SKU tiers that support and require zone redundancy | `list(string)` | <pre>[<br/>  "PremiumV2",<br/>  "PremiumV3",<br/>  "PremiumV4",<br/>  "IsolatedV2"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the created policy assignment |
| <a name="output_policy_assignment_identity"></a> [policy\_assignment\_identity](#output\_policy\_assignment\_identity) | The identity of the created policy assignment |
| <a name="output_policy_assignment_name"></a> [policy\_assignment\_name](#output\_policy\_assignment\_name) | The name of the created policy assignment |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the created policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the created policy definition |
<!-- END_TF_DOCS -->
