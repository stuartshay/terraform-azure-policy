# Storage Account Public Access Denial Policy

This directory contains an Azure Policy definition and Terraform configuration to deny the creation of Azure Storage accounts with public access enabled.

## Policy Overview

**Policy Name:** `deny-storage-account-public-access`  
**Display Name:** Deny Storage Account Public Access  
**Category:** Storage  
**Effect:** Deny (configurable)

### What This Policy Does

This policy prevents the creation of Azure Storage accounts that have:
- Public blob access enabled (`allowBlobPublicAccess: true`)
- Public network access enabled (`publicNetworkAccess: Enabled`)
- Default network action set to "Allow" without proper restrictions

### Policy Rule Logic

The policy evaluates storage accounts and denies creation if:
1. Resource type is `Microsoft.Storage/storageAccounts`
2. The resource group is NOT in the exempted list
3. ANY of the following conditions are true:
   - `allowBlobPublicAccess` is set to `true`
   - `publicNetworkAccess` is set to `Enabled`
   - Network ACLs default action is `Allow`

## Files Structure

```
policies/storage/
├── deny-storage-account-public-access.json    # Policy definition
└── README.md                                  # This documentation

terraform/policy-definitions/
├── main.tf                    # Main Terraform configuration
├── variables.tf              # Variable definitions
├── policy-assignment.tf      # Policy assignment configuration
├── backend.tf               # Backend configuration
└── terraform.tfvars.example # Example variables file
```

## Policy Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `effect` | String | `Deny` | Policy effect: Audit, Deny, or Disabled |
| `exemptedResourceGroups` | Array | `[]` | Resource groups exempt from this policy |

## Deployment with Terraform

### Prerequisites

1. Azure CLI or PowerShell Az module installed and authenticated
2. Terraform installed (>= 1.0)
3. Appropriate permissions to create policy definitions and assignments

### Step 1: Configure Variables

Copy the example variables file and update with your values:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
subcription_id     = "12345678-1234-1234-1234-123456789012"
mangement_group_id = "mg-root-tenant"
scope_id          = "/providers/Microsoft.Management/managementGroups/mg-root-tenant"

policy_effect = "Deny"  # or "Audit" for testing
exempted_resource_groups = ["rg-dev-storage", "rg-legacy-systems"]
```

### Step 2: Initialize and Deploy

```bash
# Navigate to the Terraform directory
cd terraform/policy-definitions

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the policy
terraform apply
```

### Step 3: Verify Deployment

Use the PowerShell validation script:
```powershell
pwsh ./scripts/Validate-PolicyDefinitions.ps1 -PolicyPath "./policies/storage"
```

## Testing the Policy

### Test Policy Compliance
```powershell
# Load the PowerShell profile
. ./PowerShell/Microsoft.PowerShell_profile.ps1

# Test compliance for the policy
tpc -PolicyName "deny-storage-account-public-access"

# Generate a compliance report
gcr -OutputFormat "Table"
```

### Manual Testing

Try creating a storage account with public access:
```bash
# This should be denied by the policy
az storage account create \
  --name "teststoragepublic" \
  --resource-group "rg-test" \
  --location "East US" \
  --sku "Standard_LRS" \
  --allow-blob-public-access true
```

## Policy Effects

### Deny Mode (Recommended for Production)
- **Effect:** Prevents creation/modification of non-compliant resources
- **Use Case:** Enforce security compliance
- **Result:** Resource creation fails with policy violation error

### Audit Mode (Recommended for Testing)
- **Effect:** Allows resource creation but logs non-compliance
- **Use Case:** Monitor compliance without blocking operations
- **Result:** Resource created, compliance event logged

### Disabled Mode
- **Effect:** Policy rule is not evaluated
- **Use Case:** Temporarily disable policy without removing assignment
- **Result:** No policy evaluation occurs

## Exemptions

Resource groups can be exempted from this policy by adding them to the `exemptedResourceGroups` parameter:

```hcl
exempted_resource_groups = [
  "rg-legacy-systems",
  "rg-dev-sandbox",
  "rg-special-use-case"
]
```

## Monitoring and Compliance

### View Compliance Status
```powershell
# Generate detailed compliance report
pwsh ./scripts/Test-PolicyCompliance.ps1 -PolicyName "deny-storage-account-public-access" -OutputFormat "JSON" -ExportPath "./reports/storage-compliance.json"
```

### Azure Portal
1. Navigate to Azure Policy in the Azure Portal
2. Go to Compliance
3. Filter by the policy assignment name
4. Review compliant and non-compliant resources

## Troubleshooting

### Common Issues

1. **Policy not taking effect immediately**
   - Policy evaluation can take up to 15 minutes
   - Use `az policy state trigger-scan` to force evaluation

2. **Storage account creation fails unexpectedly**
   - Check if the resource group is in the exempted list
   - Verify the policy assignment scope includes the target subscription/management group

3. **Terraform deployment fails**
   - Ensure you have Policy Contributor permissions
   - Verify the management group ID exists and is accessible

### Validation Commands

```bash
# Validate Terraform configuration
terraform validate

# Check policy definition syntax
pwsh ./scripts/Validate-PolicyDefinitions.ps1 -PolicyPath "./policies/storage"

# Test policy deployment (dry run)
pwsh ./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath "./policies/storage" -WhatIf
```

## Security Best Practices

1. **Start with Audit mode** to understand impact before enforcing
2. **Use exemptions sparingly** and document reasons
3. **Regular compliance reviews** to ensure policy effectiveness
4. **Monitor policy violations** for potential security incidents
5. **Test policy changes** in non-production environments first

## Related Policies

Consider implementing these complementary storage security policies:
- Require HTTPS traffic only
- Require encryption at rest
- Restrict storage account network access
- Require private endpoints for storage accounts

## Support

For issues or questions about this policy:
1. Check the validation scripts output
2. Review Azure Policy compliance reports
3. Consult Azure Policy documentation
4. Contact the Policy Team for organization-specific guidance