# Deny Function App Non-HTTPS Access Policy

## Overview

This Azure Policy denies the creation or update of Azure Function Apps that do not require HTTPS-only connections. Function Apps should enforce HTTPS to ensure encrypted communication and protect data in transit from interception and manipulation. This policy helps maintain secure communication standards and protects sensitive data transmitted to and from serverless applications.

## Policy Details

### What it does

- **Denies** creation of Function Apps without HTTPS-only enforcement
- **Denies** Function Apps configured to allow HTTP connections
- **Allows** exemptions for specific Function Apps or resource groups that require HTTP access
- **Evaluates** resources at creation and update time

### Resources Targeted

- `Microsoft.Web/sites` with `kind` = `functionapp`

### Key Features

- **HTTPS Enforcement**: Ensures Function Apps require encrypted connections
- **Data Protection**: Prevents data transmission over unencrypted HTTP
- **Flexible Exemptions**: Exclude specific Function Apps or entire resource groups
- **Security Focused**: Helps meet data protection and compliance requirements

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
          "field": "Microsoft.Web/sites/httpsOnly",
          "exists": "false"
        },
        {
          "field": "Microsoft.Web/sites/httpsOnly",
          "equals": "false"
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
4. HTTPS-only is not configured OR explicitly set to false

## Usage

### Basic Deployment

```hcl
module "deny_function_app_https_only" {
  source = "./policies/function-app/deny-function-app-https-only"

  environment = "production"
  owner       = "Security-Team"
}
```

### Advanced Deployment with Assignment

```hcl
module "deny_function_app_https_only" {
  source = "./policies/function-app/deny-function-app-https-only"

  environment = "production"
  owner       = "Security-Team"

  create_assignment = true
  assignment_scope_id = "/subscriptions/your-subscription-id/resourceGroups/rg-production"
  policy_effect = "Deny"

  exempted_function_apps = [
    "legacy-http-function",
    "development-test-function"
  ]

  exempted_resource_groups = [
    "rg-legacy-systems"
  ]
}
```

### Audit Mode Deployment

```hcl
module "deny_function_app_https_only" {
  source = "./policies/function-app/deny-function-app-https-only"

  environment = "sandbox"
  policy_effect = "Audit"

  create_assignment = true
  assignment_scope_id = "/subscriptions/your-subscription-id"
}
```

### Management Group Deployment

```hcl
module "deny_function_app_https_only" {
  source = "./policies/function-app/deny-function-app-https-only"

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

### Data Protection

- **Encryption in Transit**: Ensures all data is encrypted during transmission
- **Man-in-the-Middle Protection**: Prevents interception of sensitive data
- **Certificate Validation**: Enforces SSL/TLS certificate verification

### Compliance & Governance

- **Security Standards**: Helps meet organizational security requirements
- **Data Privacy**: Supports GDPR, HIPAA, and other privacy regulations
- **Risk Reduction**: Minimizes exposure of sensitive data in transit

### Threat Mitigation

- **Eavesdropping Prevention**: Blocks interception of unencrypted communications
- **Data Tampering Protection**: Prevents modification of data in transit
- **Session Hijacking Prevention**: Protects against session-based attacks

## HTTPS Configuration

Function Apps support various HTTPS enforcement methods:

### Automatic HTTPS Redirection

```json
{
  "httpsOnly": true,
  "properties": {
    "httpsOnly": true
  }
}
```

### Custom Domain with SSL

```hcl
resource "azurerm_function_app" "example" {
  name                = "secure-function-app"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  https_only = true

  site_config {
    ftps_state = "FtpsOnly"
  }
}
```

### SSL Certificate Management

- Use Azure-managed certificates for built-in domains
- Custom certificates for custom domains
- Key Vault integration for certificate storage
- Automatic certificate renewal

## Common Use Cases

### 1. Enterprise Production Environment

```hcl
# Strict HTTPS enforcement
policy_effect = "Deny"
exempted_function_apps = []  # No exemptions
```

### 2. Development with Legacy Systems

```hcl
# Allow HTTP for specific legacy integrations
exempted_function_apps = [
  "legacy-system-integration",
  "local-development-function"
]
exempted_resource_groups = [
  "rg-legacy-systems"
]
```

### 3. Gradual Migration

```hcl
# Audit mode during migration planning
policy_effect = "Audit"  # Switch to "Deny" after migration
```

## Implementation Best Practices

### 1. Phased Rollout

```hcl
# Phase 1: Audit mode to assess impact
policy_effect = "Audit"

# Phase 2: Enable for new Function Apps
policy_effect = "Deny"
```

### 2. Certificate Management

- Use Azure-managed certificates when possible
- Implement automated certificate renewal
- Monitor certificate expiration
- Use Key Vault for custom certificates

### 3. Performance Considerations

- HTTPS adds minimal overhead
- Use HTTP/2 for improved performance
- Implement proper caching strategies
- Monitor SSL handshake performance

### 4. Strategic Exemptions

Consider exempting:

- Internal development environments
- Legacy systems during migration
- Functions with existing HTTP-only integrations
- Local testing environments

### 4. Monitoring and Compliance

- Set up Azure Policy compliance dashboards
- Configure alerts for policy violations
- Monitor SSL certificate health
- Regular review of exempted resources

## Testing

Test files are available in the `tests/` directory:

```bash
# Run policy tests
cd tests/function-app
./FunctionApp.Test-DenyFunctionAppHttpsOnly.Tests.ps1
```

## Security Considerations

### Certificate Security

- Use strong cipher suites
- Implement certificate pinning where appropriate
- Regular certificate rotation
- Monitor for certificate-based attacks

### Protocol Security

- Enforce minimum TLS version (1.2+)
- Disable deprecated protocols (SSL 2.0, 3.0, TLS 1.0, 1.1)
- Use HSTS headers for additional security
- Implement proper certificate validation

### Network Security

- Combine with network-level restrictions
- Consider VNet integration for internal functions
- Implement IP restrictions where appropriate
- Use Web Application Firewall (WAF) for additional protection

## Troubleshooting

### Common Issues

1. **Policy blocks legitimate HTTP-only functions**
   - Solution: Add the Function App to `exempted_function_apps`
   - Alternative: Move to a dedicated resource group and exempt the group

2. **Certificate issues with custom domains**
   - Verify certificate is valid and trusted
   - Check certificate binding configuration
   - Ensure proper DNS configuration

3. **Performance impact concerns**
   - Monitor SSL handshake overhead
   - Implement connection pooling
   - Use CDN for static content

4. **Legacy system integration failures**
   - Plan migration to HTTPS support
   - Use temporary exemptions during transition
   - Implement reverse proxy if needed

### Debugging Steps

1. **Check Policy Compliance**

   ```bash
   # Azure CLI
   az policy state list --policy-definition-name "deny-function-app-https-only"
   ```

2. **Review Function App Configuration**

   ```bash
   # Check HTTPS settings
   az functionapp show --name <function-app-name> --resource-group <rg-name> --query "httpsOnly"
   ```

3. **Test HTTPS Connectivity**

   ```bash
   # Test HTTPS endpoint
   curl -I https://your-function-app.azurewebsites.net/api/function

   # Verify HTTP redirects to HTTPS
   curl -I http://your-function-app.azurewebsites.net/api/function
   ```

4. **Validate Configuration**

   ```bash
   # Terraform validation
   terraform validate policies/function-app/deny-function-app-https-only/
   terraform plan
   ```

## Integration Examples

### With CI/CD Pipelines

```yaml
# Azure DevOps Pipeline
stages:
  - stage: PolicyValidation
    jobs:
      - job: ValidateFunctionAppHttpsPolicy
        steps:
          - script: |
              terraform validate policies/function-app/deny-function-app-https-only/
              echo "Function App HTTPS policy validated"
```

### With Secure Function App Deployment

```hcl
# Function App with HTTPS enforcement
resource "azurerm_function_app" "example" {
  name                = "secure-function-app"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  https_only = true

  site_config {
    ftps_state                = "FtpsOnly"
    http2_enabled            = true
    min_tls_version          = "1.2"
    scm_use_main_ip_restriction = true
  }
}
```

### With Custom Domain and SSL

```hcl
# Custom domain with SSL certificate
resource "azurerm_function_app_custom_hostname_binding" "example" {
  function_app_id = azurerm_function_app.example.id
  hostname        = "api.example.com"
}

resource "azurerm_app_service_certificate" "example" {
  name                = "api-example-com-cert"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  pfx_blob            = filebase64("certificate.pfx")
  password            = var.certificate_password
}
```

### With Monitoring

```hcl
# Monitor HTTPS policy compliance
resource "azurerm_monitor_activity_log_alert" "function_app_https_violation" {
  name                = "function-app-https-policy-violation"
  resource_group_name = var.resource_group_name
  scopes              = [var.subscription_id]
  description         = "Alert when Function App HTTPS policy is violated"

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

- **Web App HTTPS Policies**: Similar HTTPS enforcement for Web Apps
- **API Management Policies**: HTTPS enforcement at API gateway level
- **Network Security Policies**: VNet integration and private endpoints
- **Certificate Policies**: SSL certificate management and rotation

## Version History

- **v1.0**: Initial policy creation with HTTPS enforcement
  - Support for Function App HTTPS-only settings
  - Exemption mechanism for Function Apps and resource groups
  - Comprehensive parameter validation
  - Full Terraform module integration

## Compliance Frameworks

This policy helps meet requirements for:

- **SOC 2**: Encryption in transit requirements
- **ISO 27001**: Information security management
- **PCI DSS**: Data transmission and encryption standards
- **HIPAA**: Data protection and transmission security
- **GDPR**: Data protection and privacy requirements
- **NIST**: Cryptographic standards and guidelines
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
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces the policy to deny Function Apps that do not require HTTPS-only connections."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Deny Function App Non-HTTPS Access Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"deny-function-app-https-only-assignment"` | no |
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
