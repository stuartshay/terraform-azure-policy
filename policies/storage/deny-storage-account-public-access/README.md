# Deny Storage Account Public Access Policy

This policy denies the creation of Azure Storage accounts that allow public blob access or public container access. Storage accounts should have public access disabled for security purposes.

## 🔒 Checkov Alignment

This policy implements **Checkov CKV_AZURE_59**: "Ensure that Storage accounts disallow public access"

- **Checkov Rule**: `CKV_AZURE_59`
- **Checkov Category**: Storage
- **Checkov Severity**: HIGH
- **Policy Alignment**: ✅ Fully Compliant

## 📁 Structure

```text
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
- **Checkov Rule**: `CKV_AZURE_59`
- **Compliance Framework**: Azure Security Benchmark, CIS Azure

### Policy Conditions

This policy aligns with **CKV_AZURE_59** requirements and triggers when a storage account is created or modified with any of these non-compliant configurations:

1. **Blob Public Access Enabled**: `allowBlobPublicAccess = true`
   - **Security Risk**: Allows anonymous public read access to blobs
   - **CKV_AZURE_59 Requirement**: Must be set to `false`

2. **Public Network Access Enabled**: `publicNetworkAccess = "Enabled"`
   - **Security Risk**: Allows access from any public IP address
   - **Best Practice**: Should be `"Disabled"` for enhanced security

3. **Network ACLs Allow All**: `networkAcls.defaultAction = "Allow"`
   - **Security Risk**: Permits traffic from all networks by default
   - **Secure Configuration**: Should be `"Deny"` with explicit allow rules

### Security Rationale

Following CKV_AZURE_59 guidance, storage accounts with public access enabled pose significant security risks:

- **Data Exposure**: Sensitive data may be accessible without authentication
- **Compliance Violations**: May violate regulatory requirements (GDPR, HIPAA, etc.)
- **Attack Surface**: Increases potential for data breaches and unauthorized access

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

## ✅ CKV_AZURE_59 Compliance Validation

### Checkov Scanning

This policy addresses findings from Checkov rule CKV_AZURE_59. You can validate compliance using:

```bash
# Scan Terraform files with Checkov
checkov -f main.tf --check CKV_AZURE_59

# Scan entire directory
checkov -d . --check CKV_AZURE_59

# Generate compliance report
checkov -d . --check CKV_AZURE_59 --output json > compliance-report.json
```

### Expected Checkov Results

- **PASSED**: Storage accounts with `allowBlobPublicAccess = false`
- **FAILED**: Storage accounts with `allowBlobPublicAccess = true` or missing property

## 🧪 Testing

The policy can be tested using the parent project's test suite:

```bash
# From project root
./scripts/Invoke-PolicyTests.ps1 -TestPath "tests/storage"

# Test specific to CKV_AZURE_59 compliance
./scripts/Generate-CheckovReport.ps1 | grep -i "CKV_AZURE_59"
```

### Test Scenarios

#### ✅ CKV_AZURE_59 Compliant Configuration

```hcl
resource "azurerm_storage_account" "compliant" {
  name                          = "compliantstorageacct"
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  allow_nested_items_to_be_public = false  # CKV_AZURE_59 requirement
  public_network_access_enabled   = false  # Additional security

  network_rules {
    default_action = "Deny"
    # Add specific IP ranges or virtual networks as needed
  }
}
```

#### ❌ Non-Compliant Configuration (triggers policy)

```hcl
resource "azurerm_storage_account" "non_compliant" {
  name                            = "noncompliantstorageacct"
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = true   # ❌ Violates CKV_AZURE_59
  public_network_access_enabled   = true   # ❌ Additional security risk
}
```

**Policy Triggers**: Any of these conditions will trigger the policy:

- `allowBlobPublicAccess = true` (Primary CKV_AZURE_59 violation)
- `publicNetworkAccess = "Enabled"`
- `networkAcls.defaultAction = "Allow"`

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

### Checkov & Compliance

- [Checkov CKV_AZURE_59](https://docs.checkov.io/4.Integrations/GitHubActions.html) - Ensure that Storage accounts disallow public access
- [Azure Security Benchmark](https://docs.microsoft.com/en-us/azure/security/benchmarks/security-controls-v2-data-protection) - Data Protection controls
- [CIS Azure Foundations Benchmark](https://www.cisecurity.org/benchmark/azure) - Storage Account security recommendations

### Azure Documentation

- [Azure Policy Definition Structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)
- [Storage Account Properties](https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts)
- [Azure Policy Effects](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/effects)
- [Storage Account Security](https://docs.microsoft.com/en-us/azure/storage/common/storage-security-guide) - Comprehensive security guide

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
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces the policy to deny storage accounts with public access enabled."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Deny Storage Account Public Access Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"deny-storage-public-access-assignment"` | no |
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
