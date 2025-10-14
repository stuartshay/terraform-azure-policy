# Audit Function App Anonymous Access Policy

## Overview

This Azure Policy audits Azure Function Apps that do not have authentication enabled. Function Apps should require authentication to ensure security and protect sensitive code, data, and business logic from unauthorized access. This policy helps maintain a secure-by-default approach for serverless applications by identifying non-compliant resources.

## Policy Details

### What it does

- **Audits** Function Apps without authentication enabled via `AuditIfNotExists` effect
- **Checks** the `siteAuthEnabled` property on the Function App's configuration resource
- **Allows** exemptions for specific Function Apps or resource groups that require anonymous access
- **Evaluates** resources continuously for compliance reporting

### Resources Targeted

- `Microsoft.Web/sites` with `kind` = `functionapp`
- `Microsoft.Web/sites/config` - Configuration resource for authentication settings

### Key Features

- **Authentication Verification**: Checks if Function Apps have authentication enabled via configuration
- **Compliance Reporting**: Provides visibility into authentication status across Function Apps
- **Flexible Exemptions**: Exclude specific Function Apps or entire resource groups
- **Security Focused**: Helps meet security compliance and governance requirements
- **Non-Blocking**: Uses AuditIfNotExists effect to report compliance without blocking deployments

## Policy Logic

### Version 2.0.0 - AuditIfNotExists Pattern

The policy uses Azure's **AuditIfNotExists** effect to check for authentication configuration:

1. **Condition (IF)**: Resource is a Function App
   - `type` = `Microsoft.Web/sites`
   - `kind` contains `functionapp`
   - `kind` does not contain `workflowapp` (excludes Logic Apps)

2. **Evaluation (THEN)**: Check authentication configuration
   - **Effect**: `AuditIfNotExists`
   - **Details**:
     - Checks related resource: `Microsoft.Web/sites/config` (name: `web`)
     - **Existence Condition**: `siteAuthEnabled` equals `true`

3. **Result**:
   - **Compliant**: Function App has `siteAuthEnabled = true` in its configuration
   - **Non-Compliant**: Function App has `siteAuthEnabled = false` or property not set
   - **Exempted**: Function App or resource group is explicitly exempted

### Why siteAuthEnabled?

The policy checks `Microsoft.Web/sites/config/siteAuthEnabled` instead of app settings because:

- **System-Managed Property**: `WEBSITE_AUTH_ENABLED` is a read-only app setting that reflects authentication state
- **Cannot Be Set Manually**: Azure prohibits setting `WEBSITE_AUTH_ENABLED` directly in app settings
- **Correct Approach**: Use the authentication configuration API to enable auth, which sets `siteAuthEnabled = true`
- **Azure Pattern**: Follows the same pattern as Azure's built-in authentication policies

### Policy Structure

```json
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Web/sites"
      },
      {
        "field": "kind",
        "contains": "functionapp"
      },
      {
        "field": "kind",
        "notContains": "workflowapp"
      }
    ]
  },
  "then": {
    "effect": "[parameters('policyEffect')]",
    "details": {
      "type": "Microsoft.Web/sites/config",
      "name": "web",
      "existenceCondition": {
        "field": "Microsoft.Web/sites/config/siteAuthEnabled",
        "equals": "true"
      }
    }
  }
}
```

### Policy Parameters

- **policyEffect**: Controls the policy behavior
  - `AuditIfNotExists` (default): Reports non-compliant resources
  - `Disabled`: Disables the policy

### Exemptions

Exemptions can be created at:

- **Resource Group Level**: Exempt all Function Apps in a resource group
- **Individual Function App**: Exempt specific Function Apps by resource ID

Example exemption scenarios:

- Development/testing environments
- Public-facing APIs requiring anonymous access
- Managed API backends with alternative authentication

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
  policy_effect = "AuditIfNotExists"

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
  policy_effect = "AuditIfNotExists"

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
| `policy_effect` | `string` | `"AuditIfNotExists"` | Policy effect (AuditIfNotExists, Disabled) |
| `exempted_function_apps` | `list(string)` | `[]` | Function Apps exempt from policy |
| `exempted_resource_groups` | `list(string)` | `[]` | Resource groups exempt from policy |

## Security Benefits

### Access Control

- **Authentication Required**: Identifies Function Apps without authentication
- **Compliance Reporting**: Provides visibility into authentication configurations
- **Identity Integration**: Encourages integration with Azure AD or other identity providers

### Compliance & Governance

- **Security Standards**: Helps meet organizational security requirements
- **Audit Trail**: Provides visibility into authentication configurations
- **Risk Reduction**: Minimizes exposure of business logic and data

### Threat Mitigation

- **Unauthorized Access Detection**: Identifies unauthenticated Function Apps
- **Data Protection**: Highlights Function Apps that may expose sensitive data
- **Code Security**: Reports Function Apps with potential security gaps

## Authentication Configuration

Function Apps can be configured with authentication to become compliant:

### Azure CLI - Enable Authentication

The simplest way to enable authentication and make a Function App compliant:

```bash
# Enable authentication (sets siteAuthEnabled = true)
az webapp auth update \
  --resource-group <resource-group-name> \
  --name <function-app-name> \
  --enabled true
```

**Important**: The `--enabled true` parameter sets `siteAuthEnabled = true` in the Function App's configuration resource. This is what the policy checks for compliance.

### Azure CLI - With Azure AD Provider

```bash
# Enable authentication with Azure AD
az webapp auth update \
  --resource-group <resource-group-name> \
  --name <function-app-name> \
  --enabled true \
  --aad-client-id <your-aad-client-id>
```

### Terraform - Using auth_settings Block

```hcl
resource "azurerm_linux_function_app" "example" {
  name                = "example-function-app"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  service_plan_id            = azurerm_service_plan.example.id

  # Authentication configuration (sets siteAuthEnabled = true)
  auth_settings {
    enabled = true  # This is what makes the Function App compliant

    # Optional: Configure authentication provider
    active_directory {
      client_id = var.aad_client_id
    }
  }

  site_config {
    # Other site configuration
  }
}
```

### Why Not WEBSITE_AUTH_ENABLED?

**Important Note**: Do NOT try to set `WEBSITE_AUTH_ENABLED` as an app setting:

- ❌ `WEBSITE_AUTH_ENABLED` is a **system-managed** app setting
- ❌ Azure **prohibits** manually setting this value
- ❌ Attempts to set it will result in: `"AppSetting with name 'WEBSITE_AUTH_ENABLED' is not allowed"`
- ✅ Use `az webapp auth update --enabled true` instead
- ✅ In Terraform, use the `auth_settings { enabled = true }` block

The `WEBSITE_AUTH_ENABLED` app setting is automatically set by Azure when you configure authentication via the proper APIs. It reflects the state of `siteAuthEnabled` in the Function App's configuration resource.

## Common Use Cases

### 1. Internal Business Functions

```hcl
# Report on authentication status for internal business logic
policy_effect = "AuditIfNotExists"
exempted_function_apps = []  # No exemptions
```

### 2. Mixed Environment

```hcl
# Monitor all Function Apps, exempt known public APIs
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
# Same monitoring approach for all environments
policy_effect = "AuditIfNotExists"
```

## Implementation Best Practices

### 1. Phased Rollout

```hcl
# Phase 1: Audit mode to assess impact
policy_effect = "AuditIfNotExists"

# Phase 2: Continue monitoring
policy_effect = "AuditIfNotExists"
```

**Note**: This policy uses `AuditIfNotExists` effect, which reports compliance but does not block deployments. Use remediation or manual fixes to address non-compliant resources.

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
./FunctionApp.Integration-DenyFunctionAppAnonymous.Tests.ps1
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

1. **Non-compliant Function Apps reported**
   - **Solution**: Enable authentication using `az webapp auth update --enabled true`
   - **Check**: Verify `siteAuthEnabled = true` in the Function App's configuration

2. **Authentication enabled but still non-compliant**
   - **Cause**: Azure Policy evaluation may take up to 30 minutes
   - **Solution**: Wait for policy evaluation cycle or trigger manual scan
   - **Check**: Run `az policy state trigger-scan` to force evaluation

3. **Cannot set WEBSITE_AUTH_ENABLED app setting**
   - **Cause**: This is a system-managed setting that cannot be set manually
   - **Solution**: Use `az webapp auth update --enabled true` instead
   - **Terraform**: Use `auth_settings { enabled = true }` block, not app_settings

4. **Policy doesn't apply to existing Function Apps**
   - **Behavior**: AuditIfNotExists policies evaluate all resources continuously
   - **Check**: Review Azure Policy compliance dashboard
   - **Solution**: Fix non-compliant resources using remediation or manual updates

5. **Exemption not working**
   - **Check**: Verify exemption scope matches the Function App's resource group
   - **Solution**: Add Function App name to `exempted_function_apps` parameter
   - **Alternative**: Add resource group to `exempted_resource_groups`

### Debugging Steps

1. **Check Policy Compliance**

   ```bash
   # Azure CLI - View compliance state
   az policy state list \
     --policy-definition-name "deny-function-app-anonymous" \
     --resource-group <resource-group-name>
   ```

2. **Review Function App Configuration**

   ```bash
   # Check if siteAuthEnabled is true
   az webapp config show \
     --name <function-app-name> \
     --resource-group <rg-name> \
     --query "siteAuthEnabled"

   # View full authentication configuration
   az webapp auth show \
     --name <function-app-name> \
     --resource-group <rg-name>
   ```

3. **Enable Authentication on Non-Compliant Function App**

   ```bash
   # Fix non-compliance by enabling authentication
   az webapp auth update \
     --resource-group <rg-name> \
     --name <function-app-name> \
     --enabled true

   # Wait for policy evaluation (up to 30 minutes)
   # Or trigger manual evaluation scan
   az policy state trigger-scan --no-wait
   ```

4. **Validate Configuration**

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
resource "azurerm_linux_function_app" "example" {
  name                = "secure-function-app"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  service_plan_id     = azurerm_service_plan.example.id

  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key

  # Enable authentication (sets siteAuthEnabled = true)
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

- **v2.0.0** (2025-01-14): Policy redesigned with AuditIfNotExists pattern
  - **Breaking Change**: Effect changed from Audit/Deny to AuditIfNotExists
  - **Improved**: Now checks `siteAuthEnabled` on config resource instead of app settings
  - **Reason**: `WEBSITE_AUTH_ENABLED` is system-managed and cannot be set manually
  - **Pattern**: Based on Azure built-in policy c75248c1-ea1d-4a9c-8fc9-29a6aabd5da8
  - **Benefit**: Policy now checks the correct authentication configuration
  - **Migration**: Existing assignments should be updated to use `AuditIfNotExists` effect

- **v1.0.0**: Initial policy creation with authentication enforcement
  - Support for Function App authentication settings
  - Exemption mechanism for Function Apps and resource groups
  - Comprehensive parameter validation
  - Full Terraform module integration
  - **Deprecated**: App settings approach (WEBSITE_AUTH_ENABLED cannot be set)

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
| <a name="input_policy_effect"></a> [policy\_effect](#input\_policy\_effect) | The effect of the policy (AuditIfNotExists or Disabled) | `string` | `"AuditIfNotExists"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the created policy assignment |
| <a name="output_policy_assignment_identity"></a> [policy\_assignment\_identity](#output\_policy\_assignment\_identity) | The identity of the created policy assignment |
| <a name="output_policy_assignment_name"></a> [policy\_assignment\_name](#output\_policy\_assignment\_name) | The name of the created policy assignment |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the created policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the created policy definition |
<!-- END_TF_DOCS -->
