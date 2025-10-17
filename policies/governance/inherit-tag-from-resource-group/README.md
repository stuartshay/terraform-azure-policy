# Inherit Tags from Resource Group Policy

## Overview

This Azure Policy automatically inherits specified tags from the parent resource group to child resources. This ensures consistent tagging across resources within a resource group and simplifies tag management. The policy uses the **Modify** effect to add or update tags on resources automatically.

## Policy Details

- **Name**: inherit-tag-from-resource-group
- **Display Name**: Inherit Tags from Resource Group
- **Category**: Governance
- **Effect**: Modify (automatic remediation)
- **Mode**: Indexed

## Policy Rule

The policy automatically adds the specified tag to resources when:

1. The resource doesn't have the specified tag
2. The parent resource group has the tag with a non-empty value

When these conditions are met, the policy will automatically add the tag to the resource with the value from the resource group.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| tagName | String | Environment | Name of the tag to inherit from resource group |

## How It Works

The Modify effect is different from Audit and Deny:

- **Audit/Deny**: Only report or block non-compliant resources
- **Modify**: Automatically changes resources to make them compliant

### Automatic Tag Inheritance

When a resource is created or updated:

1. The policy checks if the resource has the specified tag
2. If not, it checks if the resource group has the tag
3. If the resource group has the tag, it automatically copies it to the resource
4. The tag is added/updated without user intervention

### Remediation

For existing resources, you can create a remediation task to:

1. Scan all existing resources
2. Add the tag to resources that don't have it
3. Update the tag value to match the resource group

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
tag_name = "Environment"
```

## Important Considerations

### Required Permissions

The Modify effect requires elevated permissions. When you assign this policy:

- A **system-assigned managed identity** is automatically created
- The identity is granted the **Contributor** role (or minimum required permissions)
- This allows the policy to modify resource tags

### Multiple Tags

To inherit multiple tags, you need to create multiple policy assignments:

```hcl
# Assignment 1: Inherit Environment tag
tag_name = "Environment"

# Assignment 2: Inherit CostCenter tag (separate assignment)
tag_name = "CostCenter"

# Assignment 3: Inherit Owner tag (separate assignment)
tag_name = "Owner"
```

### Tag Precedence

- If a resource already has the tag, the policy will NOT overwrite it
- Only resources without the tag will have it added
- To update existing tags, delete them first or use a remediation task

## Benefits

1. **Automatic Compliance**: No manual tagging required
2. **Consistency**: All resources in a resource group have the same tags
3. **Simplified Management**: Tag at the resource group level only
4. **Reduced Errors**: Eliminates manual tagging mistakes

## Use Cases

### Use Case 1: Environment Tagging

Tag the resource group with `Environment: prod`, and all resources automatically inherit it:

```json
// Resource Group
{
  "name": "rg-production",
  "tags": {
    "Environment": "prod"
  }
}

// Resources automatically get:
{
  "tags": {
    "Environment": "prod"
  }
}
```

### Use Case 2: Cost Center Tracking

Tag resource groups with cost centers, and all resources automatically inherit for billing:

```json
// Resource Group
{
  "name": "rg-marketing",
  "tags": {
    "CostCenter": "CC-1234"
  }
}

// All resources in this RG automatically get:
{
  "tags": {
    "CostCenter": "CC-1234"
  }
}
```

### Use Case 3: Owner Identification

Track ownership at the resource group level:

```json
// Resource Group
{
  "name": "rg-team-a",
  "tags": {
    "Owner": "team-a@company.com"
  }
}

// All resources automatically tagged with:
{
  "tags": {
    "Owner": "team-a@company.com"
  }
}
```

## Compliance

### Compliant Scenario

**Resource Group:**

```json
{
  "name": "rg-production",
  "tags": {
    "Environment": "prod"
  }
}
```

**New Resource (Before Policy):**

```json
{
  "name": "storage-account",
  "tags": {}
}
```

**New Resource (After Policy - Automatically Modified):**

```json
{
  "name": "storage-account",
  "tags": {
    "Environment": "prod"  // ← Automatically added by policy
  }
}
```

### Non-Compliant Scenario That Gets Remediated

**Resource Group:**

```json
{
  "name": "rg-dev",
  "tags": {
    "Environment": "dev"
  }
}
```

**Existing Resource (Non-Compliant):**

```json
{
  "name": "vm-instance",
  "tags": {
    "Application": "web-server"
  }
}
```

**After Remediation Task:**

```json
{
  "name": "vm-instance",
  "tags": {
    "Application": "web-server",
    "Environment": "dev"  // ← Added by remediation
  }
}
```

## Best Practices

1. **Start with Important Tags**: Begin with Environment, CostCenter, Owner
2. **Tag Resource Groups First**: Ensure resource groups have the required tags
3. **Test in Non-Prod**: Test the policy in dev/test environments first
4. **Create Remediation Tasks**: Remediate existing resources after assignment
5. **Document Standards**: Document which tags should be inherited

## Policy Remediation Guide

### Creating a Remediation Task

After assigning the policy, create a remediation task to fix existing resources:

1. Go to Azure Policy in the portal
2. Select the policy assignment
3. Click "Create Remediation Task"
4. Select the resources to remediate
5. Review and create the task

### Terraform Remediation

```hcl
resource "azurerm_policy_remediation" "inherit_tags" {
  name                 = "remediate-inherit-tags"
  scope                = var.assignment_scope_id
  policy_assignment_id = azurerm_resource_group_policy_assignment.this[0].id
}
```

## Limitations

1. **Resource Group Scope**: Only inherits from the immediate parent resource group
2. **Single Tag Per Assignment**: Each assignment can only inherit one tag
3. **Existing Tags**: Won't overwrite existing tags on resources
4. **Regional Resources**: Only applies to resources that support tags

## Related Policies

- `require-tag-environment` - Require Environment tag (complementary)
- `require-tag-costcenter` - Require CostCenter tag (complementary)

## References

- [Azure Policy Modify Effect](https://docs.microsoft.com/azure/governance/policy/concepts/effects#modify)
- [Azure Policy Remediation](https://docs.microsoft.com/azure/governance/policy/how-to/remediate-resources)
- [Azure Tagging Best Practices](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
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
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment automatically inherits tags from resource groups to child resources."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Inherit Tags from Resource Group Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"inherit-tags-assignment"` | no |
| <a name="input_tag_name"></a> [tag\_name](#input\_tag\_name) | The name of the tag to inherit from resource group | `string` | `"Environment"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the policy assignment (if created) |
| <a name="output_policy_assignment_identity"></a> [policy\_assignment\_identity](#output\_policy\_assignment\_identity) | The identity of the policy assignment (if created) |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the policy definition |
<!-- END_TF_DOCS -->
