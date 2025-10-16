# Require Environment Tag Policy

## Overview

This Azure Policy requires that all resources have an `Environment` tag with an allowed value. This helps categorize resources by their deployment environment for better organization, cost tracking, and management.

## Policy Details

- **Name**: require-tag-environment
- **Display Name**: Require Environment Tag on Resources
- **Category**: Governance
- **Effect**: Audit (default), Deny, or Disabled
- **Mode**: Indexed

## Policy Rule

The policy checks for the following conditions:

1. The resource must have an `Environment` tag
2. The tag value must be one of the allowed values (dev, test, staging, prod by default)

If either condition is not met, the policy will trigger based on the configured effect.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| effect | String | Audit | The effect of the policy (Audit, Deny, or Disabled) |
| tagName | String | Environment | Name of the tag to require |
| allowedValues | Array | ["dev", "test", "staging", "prod"] | Allowed values for the Environment tag |

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
tag_name = "Environment"
allowed_values = ["dev", "test", "staging", "prod"]
```

## Effects

- **Audit**: Resources without the required tag will be marked as non-compliant but can still be created
- **Deny**: Resources without the required tag will be blocked from creation
- **Disabled**: The policy is not enforced

## Best Practices

1. Start with **Audit** mode to identify non-compliant resources
2. Communicate the requirement to your team
3. Remediate existing resources
4. Switch to **Deny** mode to enforce compliance

## Compliance

Resources will be compliant when they have an `Environment` tag with one of the allowed values.

### Compliant Examples

```json
{
  "tags": {
    "Environment": "dev",
    "Owner": "team-a"
  }
}
```

### Non-Compliant Examples

```json
// Missing Environment tag
{
  "tags": {
    "Owner": "team-a"
  }
}

// Invalid value
{
  "tags": {
    "Environment": "development"
  }
}
```

## Related Policies

- `require-tag-costcenter` - Require CostCenter tag
- `inherit-tag-from-resource-group` - Inherit tags from resource group

## References

- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Azure Tagging Best Practices](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)

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
| <a name="input_allowed_values"></a> [allowed\_values](#input\_allowed\_values) | Allowed values for the Environment tag | `list(string)` | <pre>[<br/>  "dev",<br/>  "test",<br/>  "staging",<br/>  "prod"<br/>]</pre> | no |
| <a name="input_assignment_location"></a> [assignment\_location](#input\_assignment\_location) | Location for the policy assignment (required for system-assigned identity) | `string` | `"East US"` | no |
| <a name="input_assignment_scope_id"></a> [assignment\_scope\_id](#input\_assignment\_scope\_id) | The scope ID for policy assignment (resource group ID) | `string` | `null` | no |
| <a name="input_create_assignment"></a> [create\_assignment](#input\_create\_assignment) | Whether to create a policy assignment | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, test, prod) | `string` | `"sandbox"` | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where the policy definition will be created | `string` | `null` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces the policy to require an Environment tag on all resources."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Require Environment Tag Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"require-tag-env-assignment"` | no |
| <a name="input_policy_effect"></a> [policy\_effect](#input\_policy\_effect) | The effect of the policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_tag_name"></a> [tag\_name](#input\_tag\_name) | The name of the tag to require | `string` | `"Environment"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the policy assignment (if created) |
| <a name="output_policy_assignment_identity"></a> [policy\_assignment\_identity](#output\_policy\_assignment\_identity) | The identity of the policy assignment (if created) |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the policy definition |
<!-- END_TF_DOCS -->
