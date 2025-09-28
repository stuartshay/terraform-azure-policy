# Deny Storage Account Blob Versioning Disabled Policy

## Overview

This Azure Policy denies the creation of Azure Storage accounts that have blob versioning disabled. Blob versioning provides comprehensive data protection by automatically maintaining previous versions of blobs, enabling recovery from accidental modifications, deletions, or corruptions. This policy ensures all applicable storage accounts implement proper data governance and compliance requirements.

## Policy Details

### What it does

- **Denies** creation of storage accounts without blob versioning enabled
- **Supports** configurable storage account types that require versioning
- **Allows** exemptions for specific storage accounts that don't require versioning
- **Evaluates** resources at creation and update time

### Resources Targeted

- `Microsoft.Storage/storageAccounts`

### Key Features

- **Granular Control**: Configure which storage account types require versioning
- **Flexible Exemptions**: Exclude specific storage accounts from the policy
- **Compliance Focused**: Helps meet data governance and regulatory requirements
- **Cost Awareness**: Allows exemption of premium storage where versioning costs are higher

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
          "field": "Microsoft.Storage/storageAccounts/blobServices/isVersioningEnabled",
          "exists": "false"
        },
        {
          "field": "Microsoft.Storage/storageAccounts/blobServices/isVersioningEnabled",
          "equals": "false"
        }
      ]
    }
  ]
}
```

The policy triggers when:

1. A storage account is being created or updated
2. The storage account type is in the configured list of types requiring versioning
3. The storage account is not in the exemption list
4. Blob versioning is not enabled or the property doesn't exist

## Usage

### Basic Deployment

```hcl
module "deny_storage_version" {
  source = "./policies/storage/deny-storage-version"

  environment = "production"
  owner       = "Data-Governance-Team"
}
```

### Advanced Deployment with Assignment

```hcl
module "deny_storage_version" {
  source = "./policies/storage/deny-storage-version"

  environment = "production"
  owner       = "Data-Governance-Team"

  create_assignment = true
  assignment_scope_id = "/subscriptions/your-subscription-id/resourceGroups/rg-production"
  policy_effect = "Deny"

  storage_account_types = [
    "Standard_LRS",
    "Standard_GRS",
    "Standard_RAGRS",
    "Standard_ZRS"
  ]

  exempted_storage_accounts = [
    "legacy-logs-storage",
    "temp-processing-storage"
  ]
}
```

### Audit Mode Deployment

```hcl
module "deny_storage_version" {
  source = "./policies/storage/deny-storage-version"

  environment = "sandbox"
  policy_effect = "Audit"

  create_assignment = true
  assignment_scope_id = "/subscriptions/your-subscription-id"
}
```

### Management Group Deployment

```hcl
module "deny_storage_version" {
  source = "./policies/storage/deny-storage-version"

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
| `storage_account_types` | `list(string)` | Standard types | Storage types requiring versioning |
| `exempted_storage_accounts` | `list(string)` | `[]` | Storage accounts exempt from policy |

### Storage Account Types

Default types requiring versioning:

- `Standard_LRS` - Locally redundant storage
- `Standard_GRS` - Geo-redundant storage  
- `Standard_RAGRS` - Read-access geo-redundant storage
- `Standard_ZRS` - Zone-redundant storage
- `Standard_GZRS` - Geo-zone-redundant storage
- `Standard_RAGZRS` - Read-access geo-zone-redundant storage

Premium storage types can be added if needed:

- `Premium_LRS` - Premium locally redundant storage
- `Premium_ZRS` - Premium zone-redundant storage

## Benefits of Blob Versioning

### Data Protection

- **Accidental Deletion Recovery**: Previous versions remain accessible
- **Corruption Protection**: Rollback to known good versions
- **Modification Tracking**: Audit trail of all changes

### Compliance & Governance

- **Regulatory Requirements**: Meet data retention and immutability needs
- **Audit Trails**: Complete history of data modifications
- **Legal Hold**: Support for litigation and compliance holds

### Business Continuity

- **Point-in-Time Recovery**: Restore data to specific moments
- **Human Error Mitigation**: Reduce impact of operational mistakes
- **Development Safety**: Safe testing with production data copies

## Cost Considerations

### Storage Costs

- Additional storage for version history
- Costs scale with number of versions and data size
- Configure lifecycle policies to manage version retention

### Access Costs

- Minimal additional costs for version management
- Standard blob access pricing applies to versioned data

### Optimization Strategies

```hcl
# Example: Exclude high-volume, low-value storage accounts
exempted_storage_accounts = [
  "logs-temporary-storage",
  "cache-storage-account",
  "batch-processing-temp"
]

# Example: Target only critical storage types
storage_account_types = [
  "Standard_GRS",
  "Standard_RAGRS",
  "Standard_GZRS"
]
```

## Testing

Test files are available in the `tests/` directory:

```bash
# Run policy tests
cd tests
./Test-DenyStorageVersion.Tests.ps1
```

## Implementation Best Practices

### 1. Phased Rollout

```hcl
# Phase 1: Audit mode to assess impact
policy_effect = "Audit"

# Phase 2: Enable for new storage accounts
policy_effect = "Deny"
```

### 2. Strategic Exemptions

- Legacy systems that cannot support versioning
- High-volume, low-value data storage
- Temporary or cache storage accounts
- Storage accounts with application-managed versioning

### 3. Lifecycle Management

Configure blob lifecycle policies to automatically:

- Delete old versions after retention period
- Move old versions to cooler storage tiers
- Balance compliance needs with storage costs

### 4. Monitoring and Alerts

- Set up Azure Policy compliance dashboards
- Configure alerts for policy violations
- Regular compliance reporting and remediation

### 5. Integration with Other Policies

Combine with related storage policies:

- Soft delete policies for additional protection
- Encryption policies for security
- Public access policies for data governance

## Security Considerations

### Access Control

- Policy assignments require appropriate RBAC permissions
- Version access controlled by blob-level permissions
- Consider separate permissions for version management

### Data Privacy

- Versions may contain sensitive data requiring special handling
- Apply encryption and access controls consistently across versions
- Consider data classification and handling requirements

### Compliance Integration

- Align with organizational data governance policies
- Consider regulatory requirements for specific industries
- Document version retention and deletion policies

## Troubleshooting

### Common Issues

1. **Policy doesn't apply to existing storage accounts**
   - This policy evaluates at creation/update time only
   - Use remediation tasks or manual updates for existing accounts

2. **High storage costs from versioning**
   - Implement blob lifecycle management policies
   - Consider exempting high-volume, low-value accounts
   - Review version retention requirements

3. **Application compatibility issues**
   - Some applications may not handle versioning correctly
   - Test applications with versioned storage accounts
   - Consider application-specific exemptions

4. **Policy assignment fails**
   - Verify RBAC permissions at assignment scope
   - Check management group hierarchy permissions
   - Ensure assignment scope exists and is accessible

### Debugging Steps

1. **Check Policy Compliance**

   ```bash
   # Azure CLI
   az policy state list --policy-definition-name "deny-storage-version"
   ```

2. **Review Activity Logs**
   - Check Azure Activity Log for policy evaluation results
   - Look for policy violation details and resource information

3. **Validate Configuration**

   ```bash
   # Terraform validation
   terraform validate
   terraform plan
   ```

4. **Test with Sample Resources**
   - Create test storage accounts to verify policy behavior
   - Test both compliant and non-compliant configurations

## Integration Examples

### With Azure DevOps Pipelines

```yaml
# azure-pipelines.yml
stages:
  - stage: PolicyValidation
    jobs:
      - job: ValidateStorageVersionPolicy
        steps:
          - script: |
              terraform validate policies/storage/deny-storage-version/
              echo "Storage versioning policy validated"
```

### With Lifecycle Management

```json
{
  "rules": [
    {
      "name": "ManageVersions",
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"]
        },
        "actions": {
          "version": {
            "delete": {
              "daysAfterCreationGreaterThan": 90
            },
            "tierToCool": {
              "daysAfterCreationGreaterThan": 30
            }
          }
        }
      }
    }
  ]
}
```

### With Monitoring and Alerting

```hcl
# Azure Monitor Alert Rule
resource "azurerm_monitor_activity_log_alert" "storage_version_violation" {
  name                = "storage-version-policy-violation"
  resource_group_name = var.resource_group_name
  scopes              = [var.subscription_id]
  description         = "Alert when storage versioning policy is violated"

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
    action_group_id = azurerm_monitor_action_group.policy_alerts.id
  }
}
```

## Version History

- **v1.0**: Initial policy creation with blob versioning enforcement
  - Support for configurable storage account types
  - Exemption mechanism for legacy accounts
  - Comprehensive parameter validation
  - Full Terraform module integration

## Related Policies

- **Storage Policies**: `deny-storage-account-public-access`, `deny-storage-softdelete`
- **Security Policies**: Encryption and access control policies
- **Compliance Policies**: Data governance and retention policies

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
| <a name="input_exempted_storage_accounts"></a> [exempted\_storage\_accounts](#input\_exempted\_storage\_accounts) | List of storage account names that are exempt from this policy | `list(string)` | `[]` | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where the policy definition will be created | `string` | `null` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces the policy to deny storage accounts that have blob versioning disabled."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Deny Storage Account Without Blob Versioning Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"deny-storage-version-assignment"` | no |
| <a name="input_policy_effect"></a> [policy\_effect](#input\_policy\_effect) | The effect of the policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_storage_account_types"></a> [storage\_account\_types](#input\_storage\_account\_types) | List of storage account types that require blob versioning | `list(string)` | <pre>[<br/>  "Standard_LRS",<br/>  "Standard_GRS",<br/>  "Standard_RAGRS",<br/>  "Standard_ZRS",<br/>  "Standard_GZRS",<br/>  "Standard_RAGZRS"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the created policy assignment |
| <a name="output_policy_assignment_identity"></a> [policy\_assignment\_identity](#output\_policy\_assignment\_identity) | The identity of the created policy assignment |
| <a name="output_policy_assignment_name"></a> [policy\_assignment\_name](#output\_policy\_assignment\_name) | The name of the created policy assignment |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the created policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the created policy definition |
<!-- END_TF_DOCS -->
