# Enforce Allowed Locations Policy

## Overview

This Azure Policy restricts resource deployment to approved Azure regions. This ensures resources are only deployed in compliant geographic locations for data residency, compliance, and cost optimization purposes.

## Policy Details

- **Name**: enforce-allowed-locations
- **Display Name**: Enforce Allowed Locations for Resources
- **Category**: Governance
- **Effect**: Deny (default), Audit, or Disabled
- **Mode**: Indexed

## Policy Rule

The policy checks that resources are deployed only in allowed Azure regions. Resources deployed to regions not in the allowed list will be flagged based on the configured effect.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| effect | String | Deny | The effect of the policy (Audit, Deny, or Disabled) |
| allowedLocations | Array | ["eastus", "eastus2", "westus2", "centralus", "northeurope", "westeurope"] | List of allowed Azure regions |

## Default Allowed Locations

The default configuration allows resources in the following regions:

- **US East**: eastus, eastus2
- **US West**: westus2
- **US Central**: centralus
- **Europe**: northeurope, westeurope

## Usage

### Terraform Deployment

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Update the variables with your values
3. Run Terraform commands:

```bash
terraform init
terraform plan
terraform apply
```

### Example Configuration

```hcl
# terraform.tfvars
create_assignment = true
assignment_scope_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-resource-group"
policy_effect = "Deny"
allowed_locations = ["eastus", "westus2", "northeurope"]
```

## Common Azure Regions

### United States

- `eastus` - East US (Virginia)
- `eastus2` - East US 2 (Virginia)
- `centralus` - Central US (Iowa)
- `northcentralus` - North Central US (Illinois)
- `southcentralus` - South Central US (Texas)
- `westcentralus` - West Central US (Wyoming)
- `westus` - West US (California)
- `westus2` - West US 2 (Washington)
- `westus3` - West US 3 (Arizona)

### Europe

- `northeurope` - North Europe (Ireland)
- `westeurope` - West Europe (Netherlands)
- `uksouth` - UK South (London)
- `ukwest` - UK West (Cardiff)
- `francecentral` - France Central (Paris)
- `germanywestcentral` - Germany West Central (Frankfurt)
- `norwayeast` - Norway East (Oslo)
- `swedencentral` - Sweden Central (Gävle)

### Asia Pacific

- `eastasia` - East Asia (Hong Kong)
- `southeastasia` - Southeast Asia (Singapore)
- `australiaeast` - Australia East (Sydney)
- `australiasoutheast` - Australia Southeast (Melbourne)
- `japaneast` - Japan East (Tokyo)
- `japanwest` - Japan West (Osaka)
- `koreacentral` - Korea Central (Seoul)
- `koreasouth` - Korea South (Busan)
- `centralindia` - Central India (Pune)
- `southindia` - South India (Chennai)

### Other Regions

- `brazilsouth` - Brazil South (São Paulo)
- `canadacentral` - Canada Central (Toronto)
- `canadaeast` - Canada East (Quebec)
- `southafricanorth` - South Africa North (Johannesburg)
- `uaenorth` - UAE North (Dubai)

## Effects

- **Audit**: Resources deployed to non-allowed regions will be marked as non-compliant but can still be created
- **Deny**: Resources deployed to non-allowed regions will be blocked from creation
- **Disabled**: The policy is not enforced

## Best Practices

1. **Start with Audit**: Begin in Audit mode to identify where resources are currently deployed
2. **Document Compliance Requirements**: Understand data residency and regulatory requirements
3. **Consider Costs**: Some regions have different pricing; balance cost with compliance
4. **Plan Migration**: Existing resources in non-compliant regions may need migration
5. **Coordinate Teams**: Ensure all teams know which regions are approved
6. **Environment-Specific**: Consider different allowed regions for dev vs prod

## Use Cases

### Use Case 1: Data Residency Compliance

Restrict resources to specific regions for GDPR or other data residency requirements:

```hcl
# EU-only deployment
allowed_locations = [
  "northeurope",
  "westeurope",
  "uksouth",
  "francecentral"
]
```

### Use Case 2: Cost Optimization

Limit deployment to cost-effective regions:

```hcl
# Cost-optimized US regions
allowed_locations = [
  "centralus",    # Lower cost
  "southcentralus" # Lower cost
]
```

### Use Case 3: Multi-Region High Availability

Allow specific regions for disaster recovery:

```hcl
# Primary and DR regions
allowed_locations = [
  "eastus2",      # Primary
  "westus2"       # DR
]
```

### Use Case 4: Environment-Based Restrictions

**Production (Strict):**

```hcl
allowed_locations = [
  "eastus2",
  "westus2"
]
policy_effect = "Deny"
```

**Development (Relaxed):**

```hcl
allowed_locations = [
  "eastus",
  "eastus2",
  "centralus",
  "westus2"
]
policy_effect = "Audit"
```

## Important Considerations

### Resource Migration

⚠️ **Most Azure resources cannot be moved between regions.** If existing resources are in non-compliant regions:

1. Create new resources in compliant regions
2. Migrate data and configuration
3. Update DNS/networking
4. Test thoroughly
5. Decommission old resources

### Global Services

Some Azure services are global and don't have a specific location:

- Azure Active Directory
- Azure Front Door
- Azure Traffic Manager
- Azure DNS

The policy applies to regional resources only.

### Paired Regions

Consider Azure's paired regions for disaster recovery:

- East US ↔ West US
- East US 2 ↔ Central US
- North Europe ↔ West Europe
- Southeast Asia ↔ East Asia

### Availability Zones

Not all regions support Availability Zones. Consider this when choosing allowed regions for high availability requirements.

## Compliance

Resources will be compliant when deployed to allowed regions.

### Compliant Examples

**Allowed Locations: ["eastus", "westus2"]**

```json
// Compliant - deployed to eastus
{
  "type": "Microsoft.Storage/storageAccounts",
  "name": "stproddata001",
  "location": "eastus"
}

// Compliant - deployed to westus2
{
  "type": "Microsoft.Compute/virtualMachines",
  "name": "vm-prod-web-01",
  "location": "westus2"
}
```

### Non-Compliant Examples

**Allowed Locations: ["eastus", "westus2"]**

```json
// Non-compliant - centralus not in allowed list
{
  "type": "Microsoft.Storage/storageAccounts",
  "name": "stdevdata001",
  "location": "centralus"
}

// Non-compliant - westeurope not in allowed list
{
  "type": "Microsoft.Compute/virtualMachines",
  "name": "vm-test-web-01",
  "location": "westeurope"
}
```

## Monitoring and Reporting

### Compliance Dashboard

Use Azure Policy compliance dashboard to:

- View overall compliance percentage
- Identify non-compliant resources
- Track compliance trends over time
- Generate compliance reports

### Query Non-Compliant Resources

```kusto
// Azure Resource Graph query
resources
| where location !in ("eastus", "westus2")
| project name, type, location, resourceGroup
```

## Related Policies

- `require-tag-environment` - Require Environment tag
- `enforce-naming-convention-storage` - Enforce naming conventions
- `enforce-naming-convention-func-app` - Enforce Function App naming

## References

- [Azure Regions](https://azure.microsoft.com/global-infrastructure/geographies/)
- [Azure Paired Regions](https://docs.microsoft.com/azure/reliability/cross-region-replication-azure)
- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Data Residency in Azure](https://azure.microsoft.com/explore/global-infrastructure/data-residency/)

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
| <a name="input_allowed_locations"></a> [allowed\_locations](#input\_allowed\_locations) | List of allowed Azure regions for resource deployment | `list(string)` | <pre>[<br/>  "eastus",<br/>  "eastus2",<br/>  "westus2",<br/>  "centralus",<br/>  "northeurope",<br/>  "westeurope"<br/>]</pre> | no |
| <a name="input_assignment_location"></a> [assignment\_location](#input\_assignment\_location) | Location for the policy assignment (required for system-assigned identity) | `string` | `"East US"` | no |
| <a name="input_assignment_scope_id"></a> [assignment\_scope\_id](#input\_assignment\_scope\_id) | The scope ID for policy assignment (resource group ID) | `string` | `null` | no |
| <a name="input_create_assignment"></a> [create\_assignment](#input\_create\_assignment) | Whether to create a policy assignment | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, test, prod) | `string` | `"sandbox"` | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where the policy definition will be created | `string` | `null` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment restricts resource deployment to approved Azure regions."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Enforce Allowed Locations Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"enforce-allowed-locations-assignment"` | no |
| <a name="input_policy_effect"></a> [policy\_effect](#input\_policy\_effect) | The effect of the policy (Audit, Deny, or Disabled) | `string` | `"Deny"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the policy assignment (if created) |
| <a name="output_policy_assignment_identity"></a> [policy\_assignment\_identity](#output\_policy\_assignment\_identity) | The identity of the policy assignment (if created) |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the policy definition |
<!-- END_TF_DOCS -->
