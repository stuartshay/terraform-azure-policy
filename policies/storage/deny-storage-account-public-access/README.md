# Deny Storage Account Public Access Policy

This policy denies the creation of Azure Storage accounts that allow public blob access or public container access. Storage accounts should have public access disabled for security purposes.

## 📁 Structure

```
deny-storage-account-public-access/
├── rule.json                     # Policy definition (JSON)
├── main.tf                       # Terraform main configuration
├── variables.tf                  # Terraform variables
├── outputs.tf                    # Terraform outputs
├── terraform.tfvars.example      # Example variables file
└── README.md                     # This file
```

## 🎯 Policy Details

- **Name**: `deny-storage-account-public-access`
- **Display Name**: Deny Storage Account Public Access
- **Category**: Storage
- **Mode**: All
- **Policy Type**: Custom

### Policy Conditions

The policy triggers when a storage account is created or modified with any of these configurations:

1. **Blob Public Access Enabled**: `allowBlobPublicAccess = true`
2. **Public Network Access Enabled**: `publicNetworkAccess = "Enabled"`
3. **Network ACLs Allow All**: `networkAcls.defaultAction = "Allow"`

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
cd policies/storage/deny-storage-account-public-access

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

## 🧪 Testing

The policy can be tested using the parent project's test suite:

```bash
# From project root
./scripts/Invoke-PolicyTests.ps1 -TestPath "tests/storage"
```

### Test Scenarios

1. **Compliant Storage Account**:
   - `allowBlobPublicAccess = false`
   - `publicNetworkAccess = "Disabled"`
   - `networkAcls.defaultAction = "Deny"`

2. **Non-Compliant Storage Account** (triggers policy):
   - `allowBlobPublicAccess = true`
   - OR `publicNetworkAccess = "Enabled"`
   - OR `networkAcls.defaultAction = "Allow"`

## 📊 Outputs

After deployment, Terraform provides:

- `policy_definition_id`: Full resource ID of the policy definition
- `policy_definition_name`: Name of the policy definition
- `policy_assignment_id`: Full resource ID of the policy assignment (if created)
- `policy_assignment_principal_id`: Principal ID for remediation tasks

## 🔧 Customization

### Modify Policy Logic

Edit `rule.json` to change the policy conditions. The current logic uses:

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
          // Conditions that trigger the policy
        ]
      }
    ]
  },
  "then": {
    "effect": "[parameters('effect')]"
  }
}
```

### Add More Conditions

To add additional conditions, extend the `anyOf` array in `rule.json`.

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
az policy state list --policy-assignment "deny-storage-public-access-assignment"
```

## 🔗 Integration

This policy integrates with:

- **Parent project's test suite**: Automated validation
- **Pre-commit hooks**: JSON validation
- **CI/CD pipelines**: Automated deployment
- **Azure Policy compliance**: Built-in reporting

## 📚 References

- [Azure Policy Definition Structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)
- [Storage Account Properties](https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts)
- [Azure Policy Effects](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/effects)