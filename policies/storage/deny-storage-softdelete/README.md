# Deny Storage Account Soft Delete Disabled Policy

This policy denies the creation of Azure Storage accounts that have soft delete disabled for blobs or containers, or have insufficient retention periods. Soft delete should be enabled for data protection and recovery purposes.

## 📁 Structure

```
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

## 🧪 Testing

The policy can be tested using the parent project's test suite:

```bash
# From project root
./scripts/Invoke-PolicyTests.ps1 -TestPath "tests/storage"
```

### Test Scenarios

1. **Compliant Storage Account**:
   - Blob soft delete: `enabled = true`, `days >= minimumRetentionDays`
   - Container soft delete: `enabled = true`, `days >= minimumRetentionDays`

2. **Non-Compliant Storage Account** (triggers policy):
   - Blob soft delete disabled: `enabled = false`
   - Container soft delete disabled: `enabled = false`
   - Insufficient retention: `days < minimumRetentionDays`

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

- [Azure Blob Soft Delete](https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview)
- [Azure Container Soft Delete](https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview)  
- [Azure Policy Definition Structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)
- [Storage Account Properties](https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts)