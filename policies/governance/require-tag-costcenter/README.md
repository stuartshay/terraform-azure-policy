# Require CostCenter Tag Policy

## Overview

This Azure Policy requires that all resources have a `CostCenter` tag with a valid format. This helps track costs and allocate expenses to appropriate cost centers or departments for better financial management and chargeback.

## Policy Details

- **Name**: require-tag-costcenter
- **Display Name**: Require CostCenter Tag on Resources
- **Category**: Governance
- **Effect**: Audit (default), Deny, or Disabled
- **Mode**: Indexed

## Policy Rule

The policy checks for the following conditions:

1. The resource must have a `CostCenter` tag
2. The tag value must match the specified pattern (default: `CC-####` or `CC-######`)

If either condition is not met, the policy will trigger based on the configured effect.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| effect | String | Audit | The effect of the policy (Audit, Deny, or Disabled) |
| tagName | String | CostCenter | Name of the tag to require |
| tagPattern | String | ^CC-[0-9]{4,6}$ | Regular expression pattern that the CostCenter tag value must match |

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
tag_name = "CostCenter"
tag_pattern = "^CC-[0-9]{4,6}$"
```

## Tag Pattern Examples

The default pattern `^CC-[0-9]{4,6}$` matches:

- ✅ `CC-1234` (4 digits)
- ✅ `CC-12345` (5 digits)
- ✅ `CC-123456` (6 digits)
- ❌ `CC-123` (too short)
- ❌ `CC-1234567` (too long)
- ❌ `1234` (missing prefix)
- ❌ `cc-1234` (lowercase)

### Custom Patterns

You can customize the pattern to match your organization's cost center format:

```hcl
# Allow any alphanumeric cost center code
tag_pattern = "^CC-[A-Z0-9]{4,8}$"

# Allow department-costcenter format
tag_pattern = "^[A-Z]{2,4}-[0-9]{4}$"

# Allow flexible format
tag_pattern = "^[A-Za-z0-9-]{3,20}$"
```

## Effects

- **Audit**: Resources without the required tag will be marked as non-compliant but can still be created
- **Deny**: Resources without the required tag will be blocked from creation
- **Disabled**: The policy is not enforced

## Best Practices

1. Start with **Audit** mode to identify non-compliant resources
2. Document your organization's cost center format
3. Communicate the requirement to your team
4. Remediate existing resources
5. Switch to **Deny** mode to enforce compliance

## Compliance

Resources will be compliant when they have a `CostCenter` tag with a value matching the specified pattern.

### Compliant Examples

```json
{
  "tags": {
    "CostCenter": "CC-1234",
    "Environment": "prod"
  }
}
```

```json
{
  "tags": {
    "CostCenter": "CC-567890",
    "Owner": "finance-team"
  }
}
```

### Non-Compliant Examples

```json
// Missing CostCenter tag
{
  "tags": {
    "Environment": "dev"
  }
}

// Invalid format (lowercase)
{
  "tags": {
    "CostCenter": "cc-1234"
  }
}

// Invalid format (wrong pattern)
{
  "tags": {
    "CostCenter": "1234"
  }
}

// Invalid format (too short)
{
  "tags": {
    "CostCenter": "CC-123"
  }
}
```

## Related Policies

- `require-tag-environment` - Require Environment tag
- `inherit-tag-from-resource-group` - Inherit tags from resource group

## References

- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Azure Tagging Best Practices](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [Cost Management Best Practices](https://docs.microsoft.com/azure/cost-management-billing/costs/cost-mgt-best-practices)

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
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where the policy definition will be created | `string` | `null` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces the policy to require a CostCenter tag on all resources."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Require CostCenter Tag Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"require-tag-costcenter-assignment"` | no |
| <a name="input_policy_effect"></a> [policy\_effect](#input\_policy\_effect) | The effect of the policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_tag_name"></a> [tag\_name](#input\_tag\_name) | The name of the tag to require | `string` | `"CostCenter"` | no |
| <a name="input_tag_pattern"></a> [tag\_pattern](#input\_tag\_pattern) | Regular expression pattern that the CostCenter tag value must match | `string` | `"^CC-[0-9]{4,6}$"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the policy assignment (if created) |
| <a name="output_policy_assignment_identity"></a> [policy\_assignment\_identity](#output\_policy\_assignment\_identity) | The identity of the policy assignment (if created) |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the policy definition |
<!-- END_TF_DOCS -->
