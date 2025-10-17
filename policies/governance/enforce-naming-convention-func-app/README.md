# Enforce Function App Naming Convention Policy

## Overview

This Azure Policy enforces naming conventions for Azure Function Apps. Function App names must follow organizational standards for consistency and identification. The default pattern expects names following the format: `func-{env}-{app}-{instance}` (e.g., func-dev-api-001). Function App names must be globally unique as they are used in the default azurewebsites.net domain.

## Policy Details

- **Name**: enforce-naming-convention-func-app
- **Display Name**: Enforce Naming Convention for Function Apps
- **Category**: Governance
- **Effect**: Audit (default), Deny, or Disabled
- **Mode**: Indexed

## Policy Rule

The policy checks that Function App names match the specified naming pattern. Function Apps with names that don't match the pattern will be flagged based on the configured effect.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| effect | String | Audit | The effect of the policy (Audit, Deny, or Disabled) |
| namePattern | String | ^func-(dev\|test\|staging\|prod)-[a-z0-9-]{3,40}$ | Regular expression pattern that Function App names must match |

## Azure Function App Naming Rules

Azure Function Apps have specific naming requirements:

- **Length**: 2-60 characters
- **Characters**: Alphanumeric characters and hyphens
- **Uniqueness**: Must be globally unique across all Azure (used in *.azurewebsites.net domain)
- **Start/End**: Must start and end with alphanumeric character (no leading/trailing hyphens)

## Default Naming Pattern

The default pattern `^func-(dev|test|staging|prod)-[a-z0-9-]{3,40}$` enforces:

- **Prefix**: `func-` (function app identifier)
- **Environment**: One of dev, test, staging, prod
- **Application/Instance**: 3-40 lowercase alphanumeric characters and hyphens

### Valid Examples

- ✅ `func-dev-api-001` - Development API function app
- ✅ `func-prod-payment-002` - Production payment function app
- ✅ `func-test-notification-123` - Test notification function app
- ✅ `func-staging-webhook-service` - Staging webhook service

### Invalid Examples

- ❌ `myfunction` - Missing environment indicator
- ❌ `func-Dev-Api-001` - Contains uppercase letters
- ❌ `funcdevapi001` - Missing hyphens separating components
- ❌ `func-qa-api-001` - Invalid environment (qa not in allowed list)
- ❌ `func-dev-a` - Too short (application/instance part)

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
name_pattern = "^func-(dev|test|staging|prod)-[a-z0-9-]{3,40}$"
```

## Custom Naming Patterns

You can customize the pattern to match your organization's naming convention:

### Example 1: Include Organization Prefix

```hcl
# Pattern: contoso-func-{env}-{app}
name_pattern = "^contoso-func-(dev|test|prod)-[a-z0-9-]{3,35}$"
# Matches: contoso-func-dev-api, contoso-func-prod-payment
```

### Example 2: Include Region Code

```hcl
# Pattern: func-{region}-{env}-{app}
name_pattern = "^func-(eus|wus|neu)-(dev|test|prod)-[a-z0-9-]{3,30}$"
# Matches: func-eus-dev-api, func-wus-prod-payment
```

### Example 3: Require Instance Numbers

```hcl
# Pattern: func-{env}-{app}-{3-digits}
name_pattern = "^func-(dev|test|staging|prod)-[a-z]{3,30}-[0-9]{3}$"
# Matches: func-dev-api-001, func-prod-payment-123
```

### Example 4: Include Application Type

```hcl
# Pattern: func-{type}-{env}-{app}
name_pattern = "^func-(http|timer|queue)-(dev|test|prod)-[a-z0-9-]{3,30}$"
# Matches: func-http-dev-api, func-timer-prod-cleanup
```

## Effects

- **Audit**: Non-compliant Function Apps will be marked as non-compliant but can still be created
- **Deny**: Non-compliant Function Apps will be blocked from creation
- **Disabled**: The policy is not enforced

## Best Practices

1. **Start with Audit**: Begin in Audit mode to identify naming patterns in use
2. **Document Standards**: Create clear documentation of your naming convention
3. **Communicate Changes**: Notify teams before enforcing the policy
4. **Plan Remediation**: Existing Function Apps may need to be recreated if renaming is required
5. **Switch to Deny**: Once teams are aligned, switch to Deny mode for enforcement

## Important Considerations

### Function App Renaming

⚠️ **Function Apps cannot be renamed.** If an existing Function App doesn't meet the naming convention, you must:

1. Create a new Function App with a compliant name
2. Migrate function code and configuration to the new app
3. Update any clients/integrations to use the new URL
4. Test thoroughly before switching traffic
5. Delete the old Function App

### Global Uniqueness

Function App names must be globally unique across all of Azure because they're used in the default `*.azurewebsites.net` hostname. Even if a name matches your pattern, it may be unavailable if another Azure customer is using it.

### Custom Domains

If you use custom domains for your Function Apps, the Function App name is still important for:

- Internal identification and organization
- Default hostname (still accessible even with custom domain)
- Azure Portal navigation and management
- API Management and other Azure service integrations

## Compliance

Function Apps will be compliant when their names match the specified regex pattern.

### Compliant Example

```json
{
  "type": "Microsoft.Web/sites",
  "name": "func-dev-api-001",
  "kind": "functionapp",
  "location": "eastus",
  "properties": {
    "serverFarmId": "/subscriptions/.../serverfarms/my-plan"
  }
}
```

### Non-Compliant Examples

```json
// Wrong format - missing environment
{
  "name": "func-api-001",
  "kind": "functionapp"
}

// Wrong format - uppercase
{
  "name": "Func-Dev-Api-001",
  "kind": "functionapp"
}

// Wrong format - no hyphens
{
  "name": "funcdevapi001",
  "kind": "functionapp"
}

// Wrong format - invalid environment
{
  "name": "func-qa-api-001",
  "kind": "functionapp"
}
```

## Related Policies

- `enforce-naming-convention-storage` - Enforce naming convention for Storage Accounts
- `require-tag-environment` - Require Environment tag on resources

## References

- [Azure Function App Naming Rules](https://docs.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftweb)
- [Azure Naming Conventions Best Practices](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [Azure Functions Documentation](https://docs.microsoft.com/azure/azure-functions/)
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
| <a name="input_name_pattern"></a> [name\_pattern](#input\_name\_pattern) | Regular expression pattern that Function App names must match | `string` | `"^func-[a-z0-9-]{7,55}$"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces naming conventions for Azure Function Apps."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Enforce Function App Naming Convention Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"enforce-funcapp-naming-assignment"` | no |
| <a name="input_policy_effect"></a> [policy\_effect](#input\_policy\_effect) | The effect of the policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the policy assignment (if created) |
| <a name="output_policy_assignment_identity"></a> [policy\_assignment\_identity](#output\_policy\_assignment\_identity) | The identity of the policy assignment (if created) |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the policy definition |
<!-- END_TF_DOCS -->
