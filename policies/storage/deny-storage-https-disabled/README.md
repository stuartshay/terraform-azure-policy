# Deny Storage Account HTTPS-Only Traffic Disabled Policy

## Overview

This Azure Policy denies the creation of Azure Storage accounts that do not have HTTPS-only traffic enabled. Enforcing HTTPS-only traffic ensures secure transport encryption for all storage account communications, protecting data in transit from interception and tampering. This policy helps meet security compliance requirements and implements transport layer security best practices.

## Policy Details

### What it does

- **Denies** creation of storage accounts without HTTPS-only traffic enabled
- **Supports** configurable storage account types that require HTTPS-only traffic
- **Allows** exemptions for specific storage accounts that don't require HTTPS enforcement
- **Evaluates** resources at creation and update time

### Resources Targeted

- `Microsoft.Storage/storageAccounts`

### Key Features

- **Security Focused**: Ensures all storage communications use encrypted transport
- **Granular Control**: Configure which storage account types require HTTPS-only traffic
- **Flexible Exemptions**: Exclude specific storage accounts from the policy
- **Compliance Aligned**: Helps meet security standards and regulatory requirements
- **Comprehensive Coverage**: Supports all storage account types including BlobStorage, BlockBlobStorage, and FileStorage

## Checkov Alignment

This policy aligns with **Checkov CKV_AZURE_3**: "Ensure that 'enable_https_traffic_only' is enabled"

### Policy Mapping

| **Aspect** | **Custom Policy** | **Checkov CKV_AZURE_3** |
|------------|-------------------|--------------------------|
| **Resource Type** | Microsoft.Storage/storageAccounts | azurerm_storage_account |
| **Property Checked** | supportsHttpsTrafficOnly | enable_https_traffic_only |
| **Enforcement** | Deny/Audit at deployment | Static analysis validation |
| **Scope** | Runtime policy enforcement | Pre-deployment code scanning |

### Validation Strategy

Our policy provides **runtime enforcement** that complements Checkov's **static analysis**:

1. **Pre-deployment**: Use Checkov to validate Terraform code
2. **Runtime**: This policy enforces HTTPS-only requirements in Azure
3. **Continuous**: Ongoing policy evaluation for configuration drift

### Compliance Verification

```bash
# Verify with Checkov
checkov -f storage-account.tf --check CKV_AZURE_3

# Verify with Azure Policy (after deployment)
az policy state list --policy-definition-name "deny-storage-https-disabled"
```

## Policy Logic

The policy evaluates storage accounts with the following conditions:

```json
{
  "allOf": [
    {
      "equals": "Microsoft.Storage/storageAccounts",
      "field": "type"
    },
    {
      "field": "Microsoft.Storage/storageAccounts/sku.name",
      "in": "[parameters('storageAccountTypes')]"
    },
    {
      "not": {
        "field": "name",
        "in": "[parameters('exemptedStorageAccounts')]"
      }
    },
    {
      "anyOf": [
        {
          "field": "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly",
          "exists": "false"
        },
        {
          "field": "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly",
          "equals": "false"
        }
      ]
    }
  ]
}
```

The policy triggers when:

1. A storage account is being created or updated
2. The storage account type is in the configured list of types requiring HTTPS-only traffic
3. The storage account is not in the exemption list
4. HTTPS-only traffic is not enabled or the property doesn't exist

## Usage

### Basic Deployment

```hcl
module "deny_storage_https_disabled" {
  source = "./policies/storage/deny-storage-https-disabled"

  environment = "production"
  owner       = "Security-Team"
}
```

### Advanced Deployment with Assignment

```hcl
module "deny_storage_https_disabled" {
  source = "./policies/storage/deny-storage-https-disabled"

  environment = "production"
  owner       = "Security-Team"

  create_assignment = true
  assignment_scope_id = "/subscriptions/your-subscription-id/resourceGroups/rg-production"
  policy_effect = "Deny"

  storage_account_types = [
    "Standard_LRS",
    "Standard_GRS",
    "Standard_RAGRS",
    "Standard_ZRS",
    "BlobStorage",
    "BlockBlobStorage"
  ]

  exempted_storage_accounts = [
    "legacy-http-storage",
    "development-test-storage"
  ]
}
```

### Audit Mode Deployment

```hcl
module "deny_storage_https_disabled" {
  source = "./policies/storage/deny-storage-https-disabled"

  environment = "sandbox"
  policy_effect = "Audit"

  create_assignment = true
  assignment_scope_id = "/subscriptions/your-subscription-id"
}
```

### Management Group Deployment

```hcl
module "deny_storage_https_disabled" {
  source = "./policies/storage/deny-storage-https-disabled"

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
| `storage_account_types` | `list(string)` | All major types | Storage types requiring HTTPS-only |
| `exempted_storage_accounts` | `list(string)` | `[]` | Storage accounts exempt from policy |

### Storage Account Types

Default types requiring HTTPS-only traffic:

**General Purpose:**

- `Standard_LRS` - Locally redundant storage
- `Standard_GRS` - Geo-redundant storage  
- `Standard_RAGRS` - Read-access geo-redundant storage
- `Standard_ZRS` - Zone-redundant storage
- `Standard_GZRS` - Geo-zone-redundant storage
- `Standard_RAGZRS` - Read-access geo-zone-redundant storage

**Premium Storage:**

- `Premium_LRS` - Premium locally redundant storage
- `Premium_ZRS` - Premium zone-redundant storage

**Specialized Storage:**

- `BlobStorage` - Blob storage account
- `BlockBlobStorage` - Block blob storage account
- `FileStorage` - File storage account

## Benefits of HTTPS-Only Traffic

### Security Benefits

- **Transport Encryption**: All data in transit is encrypted using TLS/SSL
- **Data Integrity**: Protects against man-in-the-middle attacks and data tampering
- **Authentication**: Ensures communication with legitimate Azure storage endpoints
- **Compliance**: Meets security requirements for regulated industries

### Protocol Security

- **TLS 1.2+**: Uses modern, secure transport layer security protocols
- **Certificate Validation**: Verifies server certificates to prevent spoofing
- **Perfect Forward Secrecy**: Protects past communications if keys are compromised

### Business Impact

- **Risk Reduction**: Eliminates insecure HTTP communication vectors
- **Regulatory Compliance**: Meets PCI DSS, HIPAA, and other security standards
- **Customer Trust**: Demonstrates commitment to data security
- **Audit Requirements**: Satisfies security audit and compliance checks

## Cost Considerations

### Performance Impact

- **Minimal Overhead**: HTTPS adds negligible latency for most workloads
- **Modern Hardware**: Current systems handle TLS encryption efficiently
- **Azure Optimization**: Azure storage is optimized for HTTPS performance

### No Additional Costs

- **Free Feature**: HTTPS-only enforcement has no additional Azure charges
- **Standard Pricing**: Same storage pricing applies regardless of protocol
- **No Premium Required**: Available on all storage account types

## Testing

Test files are available in the `tests/` directory:

```bash
# Run policy tests
cd tests
./Test-DenyStorageHttpsDisabled.Tests.ps1
```

### Test Scenarios

1. **Compliant Storage Account**

   ```hcl
   resource "azurerm_storage_account" "compliant" {
     name                     = "compliantstorageacct"
     resource_group_name      = azurerm_resource_group.test.name
     location                 = azurerm_resource_group.test.location
     account_tier             = "Standard"
     account_replication_type = "LRS"
     enable_https_traffic_only = true  # Policy compliant
   }
   ```

2. **Non-Compliant Storage Account** (Blocked by policy)

   ```hcl
   resource "azurerm_storage_account" "non_compliant" {
     name                     = "noncompliantstorageacct"
     resource_group_name      = azurerm_resource_group.test.name
     location                 = azurerm_resource_group.test.location
     account_tier             = "Standard"
     account_replication_type = "LRS"
     enable_https_traffic_only = false  # Policy violation
   }
   ```

## Implementation Best Practices

### 1. Phased Rollout

```hcl
# Phase 1: Audit mode to assess current state
policy_effect = "Audit"

# Phase 2: Enable enforcement for new storage accounts
policy_effect = "Deny"
```

### 2. Application Updates

Before enforcing the policy:

- **Update Application Code**: Ensure all applications use HTTPS endpoints
- **SDK Configuration**: Configure Azure SDKs to use HTTPS-only connections
- **Connection Strings**: Update connection strings to use HTTPS protocols
- **Third-Party Tools**: Verify external tools support HTTPS-only storage access

### 3. Strategic Exemptions

Consider exemptions for:

- **Legacy Applications**: Systems that cannot be updated to support HTTPS-only
- **Development Environments**: Test environments where HTTP may be needed temporarily
- **Migration Scenarios**: Temporary exemptions during application modernization
- **Third-Party Integrations**: External systems with HTTP-only requirements

### 4. Monitoring and Compliance

- **Policy Compliance Dashboards**: Monitor compliance status across subscriptions
- **Security Center Integration**: Track security recommendations and findings
- **Audit Logging**: Enable logging for policy evaluation and enforcement events
- **Regular Reviews**: Periodic assessment of exemptions and compliance status

### 5. Integration with CI/CD

```yaml
# Azure DevOps Pipeline
- task: checkov@1
  displayName: 'Run Checkov Security Scan'
  inputs:
    directory: '$(Build.SourcesDirectory)/terraform'
    check: 'CKV_AZURE_3'
    soft_fail: false
```

## Security Considerations

### Transport Layer Security

- **TLS Version**: Azure storage supports TLS 1.2 and higher
- **Cipher Suites**: Uses strong encryption algorithms and key sizes
- **Certificate Management**: Azure handles certificate provisioning and renewal
- **HSTS Support**: HTTP Strict Transport Security prevents protocol downgrade

### Access Control Integration

- **RBAC Compatibility**: Works with Azure role-based access control
- **SAS Token Security**: Shared Access Signatures respect HTTPS-only settings
- **Identity Integration**: Compatible with Azure AD authentication
- **Private Endpoints**: Can be combined with private endpoint configurations

### Compliance Frameworks

- **PCI DSS**: Meets payment card industry data security standards
- **HIPAA**: Supports healthcare data protection requirements
- **SOC 2**: Satisfies service organization control security criteria
- **ISO 27001**: Aligns with information security management standards

## Troubleshooting

### Common Issues

1. **Legacy Application Compatibility**

   ```hcl
   # Temporary exemption for legacy systems
   exempted_storage_accounts = [
     "legacy-system-storage"
   ]
   ```

2. **Development Environment Conflicts**

   ```hcl
   # Different policy for development
   policy_effect = var.environment == "development" ? "Audit" : "Deny"
   ```

3. **Third-Party Tool Integration**
   - Update tool configurations to use HTTPS endpoints
   - Check for tool-specific HTTPS-only support options
   - Consider proxy solutions for unsupported tools

4. **SDK and Library Updates**

   ```csharp
   // .NET SDK example - ensure HTTPS-only
   var storageAccount = CloudStorageAccount.Parse(connectionString);
   storageAccount.BlobEndpoint; // Will use HTTPS if account configured properly
   ```

### Debugging Steps

1. **Check Policy Evaluation**

   ```bash
   # Azure CLI
   az policy state list --policy-definition-name "deny-storage-https-disabled"
   ```

2. **Validate Storage Account Configuration**

   ```bash
   # Check current HTTPS-only setting
   az storage account show --name mystorageaccount --resource-group mygroup \
     --query "enableHttpsTrafficOnly"
   ```

3. **Test Connectivity**

   ```bash
   # Test HTTPS endpoint
   curl -I https://mystorageaccount.blob.core.windows.net/

   # HTTP should be blocked (if HTTPS-only enabled)
   curl -I http://mystorageaccount.blob.core.windows.net/
   ```

## Integration Examples

### With Terraform Validation

```hcl
# Local validation in Terraform
resource "azurerm_storage_account" "example" {
  name                     = "examplestorageacct"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Ensure HTTPS-only is enabled
  enable_https_traffic_only = true

  # Validation to prevent misconfiguration
  lifecycle {
    precondition {
      condition     = self.enable_https_traffic_only == true
      error_message = "Storage account must have HTTPS-only traffic enabled for security compliance."
    }
  }
}
```

### With Azure Monitor Alerts

```hcl
# Monitor for policy violations
resource "azurerm_monitor_activity_log_alert" "https_policy_violation" {
  name                = "storage-https-policy-violation"
  resource_group_name = var.resource_group_name
  scopes              = [var.subscription_id]
  description         = "Alert when storage HTTPS-only policy is violated"

  criteria {
    operation_name = "Microsoft.Authorization/policies/audit/action"
    category       = "Policy"

    resource_health {
      current  = ["Available"]
      previous = ["Available"]
      reason   = ["PlatformInitiated"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.security_alerts.id
  }
}
```

### With Azure Security Center

```json
{
  "properties": {
    "displayName": "Storage Accounts HTTPS-Only Compliance",
    "policyType": "Custom",
    "description": "Tracks compliance with HTTPS-only requirements for storage accounts",
    "metadata": {
      "category": "Storage",
      "securityCenter": {
        "severity": "High",
        "assessmentKey": "https-only-storage-compliance"
      }
    }
  }
}
```

## Version History

- **v1.0**: Initial policy creation with HTTPS-only enforcement
  - Support for all storage account types
  - Exemption mechanism for legacy systems
  - Comprehensive parameter validation
  - Full Terraform module integration
  - Checkov CKV_AZURE_3 alignment

## Related Policies

- **Storage Policies**: `deny-storage-account-public-access`, `deny-storage-version`, `deny-storage-softdelete`
- **Security Policies**: TLS encryption and access control policies
- **Compliance Policies**: Data governance and security policies

## References

### Checkov & Compliance

- [Checkov CKV_AZURE_3 Documentation](https://www.checkov.io/5.Policy%20Index/azure.html)
- [Azure Storage Security Best Practices](https://docs.microsoft.com/en-us/azure/storage/common/storage-security-guide)

### Azure Storage HTTPS-Only

- [Require secure transfer for Azure Storage](https://docs.microsoft.com/en-us/azure/storage/common/storage-require-secure-transfer)
- [Configure HTTPS-only for storage accounts](https://docs.microsoft.com/en-us/azure/storage/common/storage-security-guide#enforce-https-only)

### Azure Policy & Governance

- [Azure Policy documentation](https://docs.microsoft.com/en-us/azure/governance/policy/)
- [Storage account policy examples](https://docs.microsoft.com/en-us/azure/governance/policy/samples/storage)

### Tools & Validation

- [Checkov Static Analysis](https://www.checkov.io/)
- [Azure Policy Compliance](https://docs.microsoft.com/en-us/azure/governance/policy/how-to/get-compliance-data)

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
| <a name="input_exempted_storage_accounts"></a> [exempted\_storage\_accounts](#input\_exempted\_storage\_accounts) | List of storage account names that are exempt from this policy | `list(string)` | `[]` | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where the policy definition will be created | `string` | `null` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces the policy to deny storage accounts that do not have HTTPS-only traffic enabled."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Deny Storage Account Without HTTPS-Only Traffic Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"deny-storage-https-disabled-assignment"` | no |
| <a name="input_policy_effect"></a> [policy\_effect](#input\_policy\_effect) | The effect of the policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_storage_account_types"></a> [storage\_account\_types](#input\_storage\_account\_types) | List of storage account types that require HTTPS-only traffic | `list(string)` | <pre>[<br/>  "Standard_LRS",<br/>  "Standard_GRS",<br/>  "Standard_RAGRS",<br/>  "Standard_ZRS",<br/>  "Standard_GZRS",<br/>  "Standard_RAGZRS",<br/>  "Premium_LRS",<br/>  "Premium_ZRS",<br/>  "BlobStorage",<br/>  "BlockBlobStorage",<br/>  "FileStorage"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the created policy assignment |
| <a name="output_policy_assignment_identity"></a> [policy\_assignment\_identity](#output\_policy\_assignment\_identity) | The identity of the created policy assignment |
| <a name="output_policy_assignment_name"></a> [policy\_assignment\_name](#output\_policy\_assignment\_name) | The name of the created policy assignment |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the created policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the created policy definition |
<!-- END_TF_DOCS -->
