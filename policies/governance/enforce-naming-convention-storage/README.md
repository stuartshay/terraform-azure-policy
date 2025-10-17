# Enforce Storage Account Naming Convention Policy

## Overview

This Azure Policy enforces naming conventions for Azure Storage Accounts. Storage account names must follow organizational standards for consistency and identification. The default pattern expects lowercase alphanumeric names following the format: `st{env}{app}{instance}` (e.g., stdevweb001).

## Policy Details

- **Name**: enforce-naming-convention-storage
- **Display Name**: Enforce Naming Convention for Storage Accounts
- **Category**: Governance
- **Effect**: Audit (default), Deny, or Disabled
- **Mode**: Indexed

## Policy Rule

The policy checks that storage account names match the specified naming pattern. Storage accounts with names that don't match the pattern will be flagged based on the configured effect.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| effect | String | Audit | The effect of the policy (Audit, Deny, or Disabled) |
| namePattern | String | ^st[dev\|test\|staging\|prod](a-z0-9){3,15}$ | Regular expression pattern that storage account names must match |

## Azure Storage Account Naming Rules

Azure Storage Accounts have strict naming requirements:

- **Length**: 3-24 characters
- **Characters**: Lowercase letters and numbers only
- **Uniqueness**: Must be globally unique across all Azure
- **No special characters**: No hyphens, underscores, or uppercase letters

## Default Naming Pattern

The default pattern `^st(dev|test|staging|prod)[a-z0-9]{3,15}$` enforces:

- **Prefix**: `st` (storage)
- **Environment**: One of dev, test, staging, prod
- **Application/Instance**: 3-15 lowercase alphanumeric characters

### Valid Examples

- ✅ `stdevweb001` - Development web application storage
- ✅ `stproddata002` - Production data storage
- ✅ `stteststorage123` - Test storage
- ✅ `ststagingapi456` - Staging API storage

### Invalid Examples

- ❌ `storage001` - Missing environment indicator
- ❌ `stDevWeb001` - Contains uppercase letters
- ❌ `st-dev-web-001` - Contains hyphens
- ❌ `stdev` - Too short (missing app/instance)
- ❌ `stqaweb001` - Invalid environment (qa not in allowed list)

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
name_pattern = "^st(dev|test|staging|prod)[a-z0-9]{3,15}$"
```

## Custom Naming Patterns

You can customize the pattern to match your organization's naming convention:

### Example 1: Include Organization Prefix

```hcl
# Pattern: contoso{env}{app}{instance}
name_pattern = "^contoso(dev|test|prod)[a-z0-9]{3,12}$"
# Matches: contosodevweb001, contosoproddata02
```

### Example 2: Require 3-digit Instance Number

```hcl
# Pattern: st{env}{app}{3-digits}
name_pattern = "^st(dev|test|staging|prod)[a-z]{3,10}[0-9]{3}$"
# Matches: stdevweb001, stprodapi123
```

### Example 3: Include Region Code

```hcl
# Pattern: st{region}{env}{app}{instance}
name_pattern = "^st(eus|wus|neu)(dev|test|prod)[a-z0-9]{3,10}$"
# Matches: steusdevweb001, stwusproddata02
```

### Example 4: Simple Pattern

```hcl
# Pattern: Any lowercase alphanumeric starting with 'st'
name_pattern = "^st[a-z0-9]{4,22}$"
# Matches: stwebapp, stdata123, etc.
```

## Effects

- **Audit**: Non-compliant storage accounts will be marked as non-compliant but can still be created
- **Deny**: Non-compliant storage accounts will be blocked from creation
- **Disabled**: The policy is not enforced

## Best Practices

1. **Start with Audit**: Begin in Audit mode to identify naming patterns in use
2. **Document Standards**: Create clear documentation of your naming convention
3. **Communicate Changes**: Notify teams before enforcing the policy
4. **Plan Remediation**: Existing storage accounts may need to be recreated if renaming is required
5. **Switch to Deny**: Once teams are aligned, switch to Deny mode for enforcement

## Important Considerations

### Storage Account Renaming

⚠️ **Storage accounts cannot be renamed.** If an existing storage account doesn't meet the naming convention, you must:

1. Create a new storage account with a compliant name
2. Migrate data from the old account to the new account
3. Update applications to use the new storage account
4. Delete the old storage account

### Global Uniqueness

Storage account names must be globally unique across all of Azure. Even if a name matches your pattern, it may be unavailable if another Azure customer is using it.

## Compliance

Storage accounts will be compliant when their names match the specified regex pattern.

### Compliant Example

```json
{
  "type": "Microsoft.Storage/storageAccounts",
  "name": "stdevweb001",
  "location": "eastus",
  "sku": {
    "name": "Standard_LRS"
  }
}
```

### Non-Compliant Examples

```json
// Wrong format - missing environment
{
  "name": "stweb001"
}

// Wrong format - uppercase
{
  "name": "stDevWeb001"
}

// Wrong format - contains hyphens
{
  "name": "st-dev-web-001"
}
```

## Related Policies

- `enforce-naming-convention-func-app` - Enforce naming convention for Function Apps
- `require-tag-environment` - Require Environment tag on resources

## References

- [Azure Storage Account Naming Rules](https://docs.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftstorage)
- [Azure Naming Conventions Best Practices](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)

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
| <a name="input_name_pattern"></a> [name\_pattern](#input\_name\_pattern) | Regular expression pattern that storage account names must match | `string` | `"^st[a-z0-9]{4,22}$"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces naming conventions for Azure Storage Accounts."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Enforce Storage Account Naming Convention Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"enforce-storage-naming-assignment"` | no |
| <a name="input_policy_effect"></a> [policy\_effect](#input\_policy\_effect) | The effect of the policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the policy assignment (if created) |
| <a name="output_policy_assignment_identity"></a> [policy\_assignment\_identity](#output\_policy\_assignment\_identity) | The identity of the policy assignment (if created) |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the policy definition |
<!-- END_TF_DOCS -->
