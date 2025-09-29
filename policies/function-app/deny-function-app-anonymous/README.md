# Deny Function App Anonymous Access Policy

## Overview

This Azure Policy denies the creation of Azure Function Apps that allow anonymous access. Function Apps should require authentication to ensure security and protect sensitive code, data, and business logic from unauthorized access. This policy helps maintain a secure-by-default approach for serverless applications.

## Policy Details

### What it does

- **Denies** creation of Function Apps without authentication enabled
- **Denies** Function Apps with authentication enabled but set to allow anonymous access
- **Allows** exemptions for specific Function Apps or resource groups that require anonymous access
- **Evaluates** resources at creation and update time

### Resources Targeted

- `Microsoft.Web/sites` with `kind` = `functionapp`

### Key Features

- **Authentication Enforcement**: Ensures Function Apps have authentication enabled
- **Anonymous Access Prevention**: Blocks Function Apps configured to allow anonymous access
- **Flexible Exemptions**: Exclude specific Function Apps or entire resource groups
- **Security Focused**: Helps meet security compliance and governance requirements

## Policy Logic

The policy evaluates Function Apps with the following conditions:

```json
{
  "allOf": [
    {
      "equals": "Microsoft.Web/sites",
      "field": "type"
    },
    {
      "equals": "functionapp",
      "field": "kind"
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
          "field": "Microsoft.Web/sites/siteConfig.authSettings.enabled",
          "exists": "false"
        },
        {
          "field": "Microsoft.Web/sites/siteConfig.authSettings.enabled",
          "equals": "false"
        },
        {
          "allOf": [
            {
              "field": "Microsoft.Web/sites/siteConfig.authSettings.enabled",
              "equals": "true"
            },
            {
              "field": "Microsoft.Web/sites/siteConfig.authSettings.unauthenticatedClientAction",
              "equals": "AllowAnonymous"
            }
          ]
        }
      ]
    }
  ]
}
```

The policy triggers when:

1. A Function App is being created or updated
2. The Function App is not in the exempted Function Apps list
3. The Function App's resource group is not in the exempted resource groups list
4. Authentication is not enabled OR authentication is enabled but allows anonymous access

## Usage

### Basic Deployment

```hcl
module "deny_function_app_anonymous" {
  source = "./policies/function-app/deny-function-app-anonymous"

  environment = "production"
  owner       = "Security-Team"
}
```

### Advanced Deployment with Assignment

```hcl
module "deny_function_app_anonymous" {
  source = "./policies/function-app/deny-function-app-anonymous"

  environment = "production"
  owner       = "Security-Team"

  create_assignment = true
  assignment_scope_id = "/subscriptions/your-subscription-id/resourceGroups/rg-production"
  policy_effect = "Deny"

  exempted_function_apps = [
    "public-api-function",
    "webhook-handler"
  ]

  exempted_resource_groups = [
    "rg-public-apis"
  ]
}
```

### Audit Mode Deployment

```hcl
module "deny_function_app_anonymous" {
  source = "./policies/function-app/deny-function-app-anonymous"

  environment = "sandbox"
  policy_effect = "Audit"

  create_assignment = true
  assignment_scope_id = "/subscriptions/your-subscription-id"
}
```

### Management Group Deployment

```hcl
module "deny_function_app_anonymous" {
  source = "./policies/function-app/deny-function-app-anonymous"

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

### Access Control

- **Authentication Required**: Ensures all Function Apps implement authentication
- **Zero Trust Approach**: Blocks anonymous access by default
- **Identity Integration**: Enforces integration with Azure AD or other identity providers

### Compliance & Governance

- **Security Standards**: Helps meet organizational security requirements
- **Audit Trail**: Provides visibility into authentication configurations
- **Risk Reduction**: Minimizes exposure of business logic and data

### Threat Mitigation

- **Unauthorized Access Prevention**: Blocks unauthenticated requests
- **Data Protection**: Protects sensitive data processed by Function Apps
- **Code Security**: Prevents exposure of application logic and secrets

## Authentication Options

Function Apps can use various authentication providers:

### Azure AD

```json
{
  "authSettings": {
    "enabled": true,
    "defaultProvider": "AzureActiveDirectory",
    "unauthenticatedClientAction": "RedirectToLoginPage"
  }
}
```

### Third-Party Providers

- Microsoft Account
- Facebook
- Google
- Twitter
- Custom OIDC providers

### API Key Authentication

For API scenarios where user authentication isn't appropriate:

- Function-level keys
- Host-level keys
- System keys

## Common Use Cases

### 1. Internal Business Functions

```hcl
# Enforce authentication for internal business logic
policy_effect = "Deny"
exempted_function_apps = []  # No exemptions
```

### 2. Mixed Environment

```hcl
# Allow some public APIs while securing others
exempted_function_apps = [
  "public-webhook-handler",
  "health-check-function"
]
exempted_resource_groups = [
  "rg-public-apis"
]
```

### 3. Development Environment

```hcl
# Audit mode for development, enforcement for production
policy_effect = "Audit"  # Or "Deny" for production
```

## Implementation Best Practices

### 1. Phased Rollout

```hcl
# Phase 1: Audit mode to assess impact
policy_effect = "Audit"

# Phase 2: Enable for new Function Apps
policy_effect = "Deny"
```

### 2. Strategic Exemptions

Consider exempting:

- Public webhooks that require anonymous access
- Health check endpoints
- Public APIs with API key authentication
- Integration endpoints for external systems

### 3. Authentication Strategy

- **Internal Functions**: Use Azure AD authentication
- **Public APIs**: Implement API key authentication
- **Webhooks**: Consider IP restrictions with authentication
- **Integration**: Use managed identities where possible

### 4. Monitoring and Compliance

- Set up Azure Policy compliance dashboards
- Configure alerts for policy violations
- Regular review of exempted resources
- Monitor authentication logs in Application Insights

## Testing

Test files are available in the `tests/` directory:

```bash
# Run policy tests
cd tests/function-app
./FunctionApp.Test-DenyFunctionAppAnonymous.Tests.ps1
```

## Security Considerations

### Authentication vs Authorization

- This policy enforces **authentication** (who you are)
- Additional policies may be needed for **authorization** (what you can do)
- Consider implementing role-based access control (RBAC)

### API Key Management

- API keys should be rotated regularly
- Use Azure Key Vault for key storage
- Implement key expiration policies
- Monitor key usage patterns

### Network Security

- Combine with network-level restrictions
- Consider VNet integration for internal functions
- Implement IP restrictions where appropriate
- Use private endpoints for sensitive functions

## Troubleshooting

### Common Issues

1. **Policy blocks legitimate public APIs**
   - Solution: Add the Function App to `exempted_function_apps`
   - Alternative: Move to a dedicated resource group and exempt the group

2. **Legacy Function Apps fail deployment**
   - Check current authentication configuration
   - Plan migration to authenticated access
   - Use temporary exemptions during transition

3. **Policy doesn't apply to existing Function Apps**
   - This policy evaluates at creation/update time
   - Use remediation tasks for existing resources
   - Manual updates may be required

4. **Authentication setup complexity**
   - Review Azure AD integration documentation
   - Consider using managed identities
   - Test authentication flows thoroughly

### Debugging Steps

1. **Check Policy Compliance**

   ```bash
   # Azure CLI
   az policy state list --policy-definition-name "deny-function-app-anonymous"
   ```

2. **Review Function App Configuration**

   ```bash
   # Check authentication settings
   az functionapp auth show --name <function-app-name> --resource-group <rg-name>
   ```

3. **Validate Configuration**

   ```bash
   # Terraform validation
   terraform validate
   terraform plan
   ```

## Integration Examples

### With CI/CD Pipelines

```yaml
# Azure DevOps Pipeline
stages:
  - stage: PolicyValidation
    jobs:
      - job: ValidateFunctionAppPolicy
        steps:
          - script: |
              terraform validate policies/function-app/deny-function-app-anonymous/
              echo "Function App anonymous policy validated"
```

### With Authentication Setup

```hcl
# Function App with Azure AD authentication
resource "azurerm_function_app" "example" {
  name                = "secure-function-app"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  auth_settings {
    enabled = true
    default_provider = "AzureActiveDirectory"
    unauthenticated_client_action = "RedirectToLoginPage"

    active_directory {
      client_id = var.azure_ad_client_id
    }
  }
}
```

### With Monitoring

```hcl
# Monitor policy compliance
resource "azurerm_monitor_activity_log_alert" "function_app_violation" {
  name                = "function-app-anonymous-policy-violation"
  resource_group_name = var.resource_group_name
  scopes              = [var.subscription_id]
  description         = "Alert when Function App anonymous policy is violated"

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

- **Web App Policies**: Similar authentication enforcement for Web Apps
- **API Management Policies**: API-level authentication and authorization
- **Network Security Policies**: VNet integration and private endpoints
- **Key Vault Policies**: Secure key and secret management

## Version History

- **v1.0**: Initial policy creation with authentication enforcement
  - Support for Function App authentication settings
  - Exemption mechanism for Function Apps and resource groups
  - Comprehensive parameter validation
  - Full Terraform module integration

## Compliance Frameworks

This policy helps meet requirements for:

- **SOC 2**: Access control and authentication requirements
- **ISO 27001**: Information security management
- **PCI DSS**: Authentication and access control standards
- **NIST**: Identity and access management guidelines
- **CIS Controls**: Secure configuration standards

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
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces the policy to deny Function Apps that allow anonymous access."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Deny Function App Anonymous Access Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"deny-function-app-anonymous-assignment"` | no |
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
