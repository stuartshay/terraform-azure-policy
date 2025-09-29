# Deny Storage Blob Logging Disabled Policy

This policy ensures that blob service logging is enabled for Azure Storage accounts. Logging provides audit trails for access to storage data and helps with security monitoring and compliance requirements.

## 🔒 Checkov Alignment

This policy implements **Checkov CKV2_AZURE_21**: "Ensure that Storage account has blob service logging enabled"

- **Checkov Rule**: `CKV2_AZURE_21`
- **Checkov Category**: Storage
- **Checkov Severity**: MEDIUM
- **Policy Alignment**: ✅ Fully Compliant

## 📁 Structure

```text
deny-storage-blob-logging-disabled/
├── rule.json                     # Policy definition (JSON)
├── main.tf                       # Terraform main configuration
├── variables.tf                  # Terraform variables
├── outputs.tf                    # Terraform outputs
├── terraform.tfvars.example      # Example variables file
└── README.md                     # This file
```

## 🎯 Policy Details

- **Name**: `deny-storage-blob-logging-disabled`
- **Display Name**: Deny Storage Blob Logging Disabled
- **Category**: Storage
- **Mode**: All
- **Policy Type**: Custom
- **Checkov Rule**: `CKV2_AZURE_21`
- **Compliance Framework**: Azure Security Benchmark, CIS Azure

### Policy Conditions

This policy aligns with **CKV2_AZURE_21** requirements and triggers when a storage account's blob service lacks proper diagnostic logging configuration:

1. **Missing Diagnostic Settings**: No diagnostic settings configured for blob services
   - **Security Risk**: No audit trail for blob access activities
   - **CKV2_AZURE_21 Requirement**: Must have diagnostic settings enabled

2. **Incomplete Logging Categories**: Missing required log categories (StorageRead, StorageWrite, StorageDelete)
   - **Security Risk**: Incomplete visibility into blob operations
   - **Best Practice**: All three categories should be enabled and logged

### Security Rationale

Following CKV2_AZURE_21 guidance, storage accounts without proper blob logging pose audit and compliance risks:

- **Audit Trail Gap**: Cannot track who accessed what data and when
- **Compliance Violations**: May violate regulatory requirements requiring access logging
- **Security Monitoring**: Limited ability to detect suspicious access patterns
- **Incident Response**: Insufficient data for forensic analysis

### Available Effects

- **Audit** (default): Log non-compliant resources
- **Deny**: Block creation of non-compliant resources
- **Disabled**: Turn off the policy

## 🚀 Deployment

### Prerequisites

1. **Terraform** >= 1.0
2. **Azure CLI** authenticated
3. **Appropriate permissions** to create policy definitions and assignments

### Quick Deploy

```bash
# Navigate to the policy directory
cd policies/storage/deny-storage-blob-logging-disabled

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# - assignment_scope_id: Your resource group ID
# - policy_effect: Audit or Deny
# - environment: Your environment name

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### Variables Configuration

Edit `terraform.tfvars`:

```hcl
# Required: Resource group scope for assignment
assignment_scope_id = "/subscriptions/YOUR-SUB-ID/resourceGroups/YOUR-RG-NAME"

# Policy behavior
policy_effect = "Audit"  # or "Deny" for enforcement

# Optional: Management group (if deploying at MG level)
# management_group_id = "your-management-group-id"

# Environment settings
environment = "sandbox"
owner = "Policy-Team"
```

## ✅ CKV2_AZURE_21 Compliance Validation

### Checkov Scanning

This policy addresses findings from Checkov rule CKV2_AZURE_21. You can validate compliance using:

```bash
# Scan Terraform files with Checkov
checkov -f main.tf --check CKV2_AZURE_21

# Scan entire directory
checkov -d . --check CKV2_AZURE_21

# Generate compliance report
checkov -d . --check CKV2_AZURE_21 --output json > compliance-report.json
```

### Expected Checkov Results

- **PASSED**: Storage accounts with proper diagnostic settings for blob services
- **FAILED**: Storage accounts without blob service logging or incomplete logging categories

## 🧪 Testing

The policy can be tested using the parent project's test suite:

```bash
# From project root
./scripts/Invoke-PolicyTests.ps1 -TestPath "tests/storage"

# Test specific to CKV2_AZURE_21 compliance
./scripts/Generate-CheckovReport.ps1 | grep -i "CKV2_AZURE_21"
```

### Test Scenarios

#### ✅ CKV2_AZURE_21 Compliant Configuration

```hcl
resource "azurerm_storage_account" "compliant" {
  name                     = "compliantstorageacct"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_monitor_diagnostic_setting" "blob_logs" {
  name               = "blob-service-logs"
  target_resource_id = "${azurerm_storage_account.compliant.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}
```

#### ❌ Non-Compliant Configuration (triggers policy)

```hcl
resource "azurerm_storage_account" "non_compliant" {
  name                     = "noncompliantstorageacct"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  # ❌ No diagnostic settings for blob services - Violates CKV2_AZURE_21
}
```

**Policy Triggers**: Any of these conditions will trigger the policy:

- Missing diagnostic settings for blob services (Primary CKV2_AZURE_21 violation)
- Incomplete log categories (missing StorageRead, StorageWrite, or StorageDelete)
- Disabled logging for any of the required categories

## 📊 Outputs

After deployment, Terraform provides:

- `policy_definition_id`: Full resource ID of the policy definition
- `policy_definition_name`: Name of the policy definition
- `policy_assignment_id`: Full resource ID of the policy assignment (if created)
- `policy_assignment_principal_id`: Principal ID for remediation tasks

## 🔧 Customization

### Modify Policy Logic

Edit `rule.json` to change the policy conditions. The current logic checks for:

```json
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Storage/storageAccounts/blobServices"
      },
      {
        "anyOf": [
          // Conditions that check for missing or incomplete diagnostic settings
        ]
      }
    ]
  },
  "then": {
    "effect": "[parameters('effect')]"
  }
}
```

### Add More Log Categories

To require additional log categories, extend the logging conditions in `rule.json`.

### Change Default Effect

Modify the `defaultValue` in the `effect` parameter within `rule.json`.

## 🛠️ Management

### Update Policy

1. Modify `rule.json`
2. Run `terraform plan` to see changes
3. Run `terraform apply` to update

### Remove Policy

```bash
terraform destroy
```

### View Compliance

Use Azure Policy portal or:

```bash
# View policy states
az policy state list --policy-assignment "deny-storage-blob-logging-disabled-assignment"
```

## 🔗 Integration

This policy integrates with:

- **Parent project's test suite**: Automated validation
- **Pre-commit hooks**: JSON validation
- **CI/CD pipelines**: Automated deployment
- **Azure Policy compliance**: Built-in reporting

## 📚 References

### Checkov & Compliance

- [Checkov CKV2_AZURE_21](https://docs.checkov.io/4.Integrations/GitHubActions.html) - Ensure that Storage account has blob service logging enabled
- [Azure Security Benchmark](https://docs.microsoft.com/en-us/azure/security/benchmarks/security-controls-v2-logging-threat-detection) - Logging and threat detection controls
- [CIS Azure Foundations Benchmark](https://www.cisecurity.org/benchmark/azure) - Storage Account logging recommendations

### Azure Documentation

- [Azure Policy Definition Structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)
- [Storage Diagnostic Settings](https://docs.microsoft.com/en-us/azure/storage/common/storage-analytics-logging)
- [Azure Policy Effects](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/effects)
- [Storage Account Monitoring](https://docs.microsoft.com/en-us/azure/storage/common/storage-monitoring-diagnosing-troubleshooting) - Comprehensive monitoring guide

### Tools & Testing

- [Checkov Documentation](https://www.checkov.io/) - Static code analysis for infrastructure as code
- [Azure Policy Visual Studio Code Extension](https://marketplace.visualstudio.com/items?itemName=AzurePolicy.azurepolicyextension) - Policy development tools

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
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where the policy definition will be created | `string` | `null` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces the policy to ensure blob service logging is enabled for storage accounts."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Deny Storage Blob Logging Disabled Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"deny-storage-blob-logging-disabled-assignment"` | no |
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
