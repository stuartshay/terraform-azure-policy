# Deny Storage Account Soft Delete Disabled Policy

This policy denies the creation of Azure Storage accounts that have soft delete disabled for blobs or containers, or have insufficient retention periods. Soft delete should be enabled for data protection and recovery purposes.

## 📁 Structure

```text
deny-storage-softdelete/
├── rule.json                     # Policy definition (JSON)
├── main.tf                       # Terraform main configuration
├── variables.tf                  # Terraform variables
├── outputs.tf                    # Terraform outputs
├── terraform.tfvars.example      # Example variables file
└── README.md                     # This file
```

## 🎯 Policy Details

- **Name**: `deny-storage-softdelete`
- **Display Name**: Deny Storage Account Soft Delete Disabled
- **Category**: Storage
- **Mode**: All
- **Policy Type**: Custom

## 🔒 Checkov Alignment

This policy provides **enhanced coverage** beyond existing Checkov rules for Azure Storage soft delete:

- **Related Checkov Rule**: `CKV2_AZURE_38` - "Ensure soft-delete is enabled on Azure storage account"
- **Policy Gap Filled**: Addresses the lack of comprehensive soft delete retention policy validation in Checkov
- **Enhanced Coverage**: This policy provides more comprehensive soft delete controls including:
  - ✅ Blob soft delete retention period validation
  - ✅ Container soft delete retention period validation  
  - ✅ Configurable minimum retention days (1-365 days)
  - ✅ Multiple enforcement modes (Audit/Deny/Disabled)
  - ✅ Granular policy conditions for different soft delete scenarios

### Checkov CKV2_AZURE_38 Comparison

| Feature | CKV2_AZURE_38 | This Policy |
|---------|---------------|-------------|
| **Scope** | Basic soft delete enabled check | Comprehensive retention validation |
| **Blob Soft Delete** | ✅ Enabled check only | ✅ Enabled + retention period validation |
| **Container Soft Delete** | ❌ Not covered | ✅ Enabled + retention period validation |
| **Retention Validation** | ❌ No retention checks | ✅ Configurable minimum retention days |
| **Enforcement Options** | ❌ Limited | ✅ Audit/Deny/Disabled modes |
| **Customization** | ❌ Fixed behavior | ✅ Parameterized retention requirements |

### Policy Conditions

The policy triggers when a storage account is created or modified with any of these configurations:

1. **Blob Soft Delete Disabled**: `deleteRetentionPolicy.enabled = false`
2. **Blob Soft Delete Retention Too Low**: `deleteRetentionPolicy.days < minimumRetentionDays`
3. **Container Soft Delete Disabled**: `containerDeleteRetentionPolicy.enabled = false`
4. **Container Soft Delete Retention Too Low**: `containerDeleteRetentionPolicy.days < minimumRetentionDays`

### Available Effects

- **Audit** (default): Log non-compliant resources
- **Deny**: Block creation of non-compliant resources
- **Disabled**: Turn off the policy

### Parameters

- **effect**: The enforcement effect (Audit, Deny, Disabled)
- **minimumRetentionDays**: Minimum retention period (1-365 days, default: 7)

## 🚀 Deployment

### Prerequisites

1. **Terraform** >= 1.0
2. **Azure CLI** authenticated
3. **Appropriate permissions** to create policy definitions and assignments

### Quick Deploy

```bash
# Navigate to the policy directory
cd policies/storage/deny-storage-softdelete

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# - assignment_scope_id: Your resource group ID
# - policy_effect: Audit or Deny
# - minimum_retention_days: Retention period (7-365 days)
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

# Soft delete configuration
minimum_retention_days = 7  # 1-365 days

# Optional: Management group (if deploying at MG level)
# management_group_id = "your-management-group-id"

# Environment settings
environment = "sandbox"
owner = "Policy-Team"
```

## ✅ Checkov Validation

While Checkov CKV2_AZURE_38 provides basic soft delete validation, you can use it alongside this policy for comprehensive coverage:

### Checkov Scanning

```bash
# Scan Terraform files for basic soft delete compliance (CKV2_AZURE_38)
checkov -f main.tf --check CKV2_AZURE_38

# Scan entire directory for all Azure storage policies
checkov -d . --framework terraform --check CKV2_AZURE_38,CKV_AZURE_*

# Generate compliance report for storage policies
checkov -d . --framework terraform --check CKV2_AZURE_38 --output json > soft-delete-compliance.json
```

### Expected Checkov Results

- **CKV2_AZURE_38 PASSED**: Storage accounts with basic soft delete enabled
- **CKV2_AZURE_38 FAILED**: Storage accounts without soft delete enabled  
- **Policy Gap**: CKV2_AZURE_38 won't validate retention periods (this policy fills that gap)

### Combined Validation Strategy

```bash
# Use both Checkov and this policy for comprehensive coverage
# 1. Run Checkov for basic compliance
checkov -d . --check CKV2_AZURE_38

# 2. Deploy this policy for retention period validation
./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath "./policies/storage/deny-storage-softdelete"

# 3. Test policy compliance
./scripts/Test-PolicyCompliance.ps1
```

## 🧪 Testing

The policy can be tested using the parent project's test suite:

```bash
# From project root
./scripts/Invoke-PolicyTests.ps1 -TestPath "tests/storage"

# Test combined with Checkov validation
./scripts/Generate-CheckovReport.ps1 | grep -i "CKV2_AZURE_38\|soft.delete"
```

### Test Scenarios

#### ✅ Fully Compliant Configuration (Passes Both Checkov & This Policy)

```hcl
resource "azurerm_storage_account" "compliant" {
  name                     = "compliantstorageacct"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Meets CKV2_AZURE_38 requirement
  blob_properties {
    delete_retention_policy {
      enabled = true
      days    = 30  # Sufficient retention period
    }

    container_delete_retention_policy {
      enabled = true
      days    = 30  # Sufficient retention period
    }
  }
}
```

#### ⚠️ Partially Compliant (Passes Checkov CKV2_AZURE_38, Fails This Policy)

```hcl
resource "azurerm_storage_account" "partial_compliant" {
  name                     = "partialstorageacct"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    delete_retention_policy {
      enabled = true
      days    = 1  # ❌ Too low retention (< minimumRetentionDays)
    }
    # ❌ Missing container soft delete entirely
  }
}
```

#### ❌ Non-Compliant Configuration (Fails Both)

```hcl
resource "azurerm_storage_account" "non_compliant" {
  name                     = "noncompliantstorageacct"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # ❌ No soft delete configuration at all
  # Fails both CKV2_AZURE_38 and this policy
}
```

### Validation Results Summary

| Configuration | CKV2_AZURE_38 | This Policy | Notes |
|---------------|---------------|-------------|-------|
| **Fully Compliant** | ✅ PASS | ✅ PASS | Comprehensive soft delete setup |
| **Partially Compliant** | ✅ PASS | ❌ FAIL | Basic soft delete but insufficient retention |
| **Non-Compliant** | ❌ FAIL | ❌ FAIL | No soft delete configuration |

### Manual Testing

Create test storage accounts to validate policy behavior:

```bash
# Compliant storage account (soft delete enabled with sufficient retention)
az storage account create \
  --name "compliantstoragetest" \
  --resource-group "rg-azure-policy-testing" \
  --location "East US" \
  --sku "Standard_LRS" \
  --enable-blob-delete-retention \
  --blob-delete-retention-days 30

# Non-compliant storage account (will be flagged by policy)
az storage account create \
  --name "noncompliantstoragetest" \
  --resource-group "rg-azure-policy-testing" \
  --location "East US" \
  --sku "Standard_LRS"
  # (soft delete disabled by default)
```

## 📊 Outputs

After deployment, Terraform provides:

- `policy_definition_id`: Full resource ID of the policy definition
- `policy_definition_name`: Name of the policy definition
- `policy_assignment_id`: Full resource ID of the policy assignment (if created)
- `policy_assignment_principal_id`: Principal ID for remediation tasks

## 🔧 Customization

### Modify Policy Logic

Edit `rule.json` to change the policy conditions. The current logic checks:

```json
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Storage/storageAccounts"
      },
      {
        "anyOf": [
          // Conditions for blob soft delete
          // Conditions for container soft delete
        ]
      }
    ]
  },
  "then": {
    "effect": "[parameters('effect')]"
  }
}
```

### Adjust Retention Requirements

Modify the `minimumRetentionDays` parameter in variables.tf or terraform.tfvars:

```hcl
# Stricter retention requirement
minimum_retention_days = 30  # 30 days minimum

# More lenient retention requirement  
minimum_retention_days = 1   # 1 day minimum
```

### Add File Share Soft Delete

Extend the policy to include file share soft delete by adding conditions for:

- `Microsoft.Storage/storageAccounts/fileServices/shares/shareDeleteRetentionPolicy`

## 🛠️ Management

### Update Policy

1. Modify `rule.json` or variables
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
az policy state list --policy-assignment "deny-storage-softdelete-assignment"

# Check specific storage account compliance
az policy state list --resource "/subscriptions/SUB-ID/resourceGroups/RG-NAME/providers/Microsoft.Storage/storageAccounts/STORAGE-NAME"
```

## 🔗 Integration

This policy integrates with:

- **Parent project's test suite**: Automated validation
- **Pre-commit hooks**: JSON validation
- **CI/CD pipelines**: Automated deployment
- **Azure Policy compliance**: Built-in reporting
- **Main policies deployment**: Can be deployed with other policies

## 📈 Best Practices

### Recommended Settings

- **Production**: `policy_effect = "Deny"`, `minimum_retention_days = 30`
- **Development**: `policy_effect = "Audit"`, `minimum_retention_days = 7`
- **Critical Data**: `policy_effect = "Deny"`, `minimum_retention_days = 90`

### Soft Delete Benefits

- **Accidental Deletion Protection**: Recover deleted blobs and containers
- **Ransomware Protection**: Additional layer against malicious deletion
- **Compliance Requirements**: Meet data retention regulations
- **Operational Safety**: Reduce risk of permanent data loss

## 🚨 Considerations

### Performance Impact

- Soft delete may increase storage costs due to retained deleted items
- Monitor storage usage and adjust retention periods as needed

### Exemptions

Consider exempting:

- Temporary/scratch storage accounts
- Log storage with external backup systems
- Test environments with synthetic data

### Remediation

The policy creates a system-assigned identity that can be used for automatic remediation:

```bash
# Enable soft delete on existing storage accounts
az storage account blob-service-properties update \
  --account-name "storageaccountname" \
  --resource-group "rg-name" \
  --enable-delete-retention true \
  --delete-retention-days 30
```

## 📚 References

### Checkov & Compliance

- [Checkov CKV2_AZURE_38](https://www.checkov.io/5.Policy%20Index/all.html) - Ensure soft-delete is enabled on Azure storage account
- [Checkov Documentation](https://www.checkov.io/) - Static code analysis for infrastructure as code
- [Azure Security Benchmark](https://docs.microsoft.com/en-us/azure/security/benchmarks/security-controls-v2-data-protection) - Data Protection controls

### Azure Storage Soft Delete

- [Azure Blob Soft Delete](https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview) - Comprehensive guide to blob soft delete
- [Azure Container Soft Delete](https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview) - Container soft delete overview  
- [Storage Account Security Best Practices](https://docs.microsoft.com/en-us/azure/storage/common/storage-security-guide) - Security recommendations

### Azure Policy & Governance

- [Azure Policy Definition Structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure) - Policy authoring guide
- [Storage Account Properties](https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts) - ARM template reference
- [Azure Policy Effects](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/effects) - Understanding policy effects

### Tools & Validation

- [Azure Policy Visual Studio Code Extension](https://marketplace.visualstudio.com/items?itemName=AzurePolicy.azurepolicyextension) - Policy development tools
- [Checkov GitHub Repository](https://github.com/bridgecrewio/checkov) - Open source static analysis tool
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
| <a name="input_minimum_retention_days"></a> [minimum\_retention\_days](#input\_minimum\_retention\_days) | Minimum number of days for soft delete retention | `number` | `7` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces the policy to deny storage accounts with soft delete disabled or insufficient retention periods."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Deny Storage Account Soft Delete Disabled Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"deny-storage-softdelete-assignment"` | no |
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
