# Deny Function App Outdated HTTP Version Policy

## Overview

This Azure Policy ensures that Azure Function Apps use the latest HTTP version (HTTP/2) to optimize performance and security. HTTP/2 provides significant improvements over HTTP/1.1 including:

- **Multiplexing**: Multiple requests over a single connection
- **Server Push**: Proactive resource delivery
- **Header Compression**: Reduced overhead
- **Binary Protocol**: More efficient parsing
- **Enhanced Security**: Better encryption and security features

## Policy Details

- **Policy Name**: deny-function-app-http-version
- **Display Name**: Deny Function App Outdated HTTP Version
- **Category**: Function App
- **Effect**: Deny (configurable)
- **Checkov ID**: CKV_AZURE_67

## Policy Rule

This policy evaluates Function Apps and:

1. **Targets**: Microsoft.Web/sites resources with kind containing "functionapp"
2. **Validates**: The `siteConfig.http20Enabled` property is set to `true`
3. **Action**: Denies creation/update if HTTP/2 is not enabled
4. **Exemptions**: Supports exempting specific Function Apps or Resource Groups

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `effect` | String | "Deny" | Policy effect: Audit, Deny, or Disabled |
| `exemptedFunctionApps` | Array | [] | List of Function App names exempt from policy |
| `exemptedResourceGroups` | Array | [] | List of Resource Group names exempt from policy |

## Usage Example

```hcl
module "deny_function_app_http_version" {
  source = "./policies/function-app/deny-function-app-http-version"

  # Assignment Configuration
  create_assignment              = true
  assignment_scope_id            = "/subscriptions/12345678-1234-1234-1234-123456789012"
  policy_assignment_name         = "deny-function-app-http-version"
  policy_assignment_display_name = "Deny Function App Outdated HTTP Version"

  # Policy Configuration
  policy_effect = "Deny"

  # Exemptions (optional)
  exempted_function_apps = [
    "legacy-function-app-name"
  ]

  exempted_resource_groups = [
    "rg-legacy-applications"
  ]

  # Environment
  environment = "production"
  owner       = "security-team"
}
```

## Compliance

This policy helps ensure compliance with:

- **Security Best Practices**: Using modern HTTP protocols
- **Performance Optimization**: Leveraging HTTP/2 efficiency gains
- **Checkov Security**: CKV_AZURE_67 compliance
- **Azure Well-Architected Framework**: Performance efficiency pillar

## Testing

### Compliant Resource

```json
{
  "type": "Microsoft.Web/sites",
  "kind": "functionapp",
  "properties": {
    "siteConfig": {
      "http20Enabled": true
    }
  }
}
```

### Non-Compliant Resource

```json
{
  "type": "Microsoft.Web/sites",
  "kind": "functionapp",
  "properties": {
    "siteConfig": {
      "http20Enabled": false
    }
  }
}
```

## Related Policies

- `deny-function-app-anonymous`: Ensures authentication is enabled
- `deny-function-app-https-only`: Enforces HTTPS-only connections

## References

- [Azure Function Apps HTTP/2 Configuration](https://docs.microsoft.com/en-us/azure/azure-functions/functions-app-settings)
- [HTTP/2 Benefits and Features](https://developers.google.com/web/fundamentals/performance/http2)
- [Checkov Policy CKV_AZURE_67](https://www.checkov.io/5.Policy%20Index/azure.html)

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
| <a name="input_assignment_location"></a> [assignment\_location](#input\_assignment\_location) | The location for policy assignment (required for managed identity) | `string` | `null` | no |
| <a name="input_assignment_scope_id"></a> [assignment\_scope\_id](#input\_assignment\_scope\_id) | The scope ID for policy assignment | `string` | `null` | no |
| <a name="input_create_assignment"></a> [create\_assignment](#input\_create\_assignment) | Whether to create a policy assignment | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name for tagging | `string` | `"dev"` | no |
| <a name="input_exempted_function_apps"></a> [exempted\_function\_apps](#input\_exempted\_function\_apps) | List of Function App names that are exempt from this policy | `list(string)` | `[]` | no |
| <a name="input_exempted_resource_groups"></a> [exempted\_resource\_groups](#input\_exempted\_resource\_groups) | List of resource group names that are exempt from this policy | `list(string)` | `[]` | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The management group ID for policy definition scope | `string` | `null` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner name for tagging | `string` | `"platform-team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | The description of the policy assignment | `string` | `"This policy assignment denies Function Apps that do not use HTTP/2 to ensure optimal performance and security."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | The display name of the policy assignment | `string` | `"Deny Function App Outdated HTTP Version"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | The name of the policy assignment | `string` | `"deny-function-app-http-version"` | no |
| <a name="input_policy_effect"></a> [policy\_effect](#input\_policy\_effect) | The effect of the policy (Audit, Deny, or Disabled) | `string` | `"Deny"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the policy assignment (if created) |
| <a name="output_policy_assignment_name"></a> [policy\_assignment\_name](#output\_policy\_assignment\_name) | The name of the policy assignment (if created) |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the policy definition |
<!-- END_TF_DOCS -->
