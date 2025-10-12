# Azure Storage Security Policies Bundle

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](./version.json)
[![Policies](https://img.shields.io/badge/policies-5-green.svg)](./bundle.metadata.json)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](../../LICENSE)

## Overview

The **Azure Storage Security Policies Bundle** is a comprehensive collection of Azure Policy definitions designed to enforce security best practices for Azure Storage accounts. This bundle implements controls derived from Checkov security rules and Azure Security Benchmark recommendations.

**Bundle Version:** 1.0.0  
**Last Updated:** 2025-10-11  
**Total Policies:** 5  
**Category:** Storage Security

## ⚠️ Publishing vs Deployment

### This Bundle: Publishing Only

This bundle **publishes** versioned policy definitions to registries. It does **NOT** deploy policies to Azure subscriptions.

**What This Bundle Does:**

- ✅ Creates versioned policy packages
- ✅ Publishes to MyGet (NuGet) for discovery
- ✅ Publishes to Terraform Cloud Registry for consumption
- ✅ Provides policy definitions in JSON format

**What This Bundle Does NOT Do:**

- ❌ Deploy policies to Azure subscriptions
- ❌ Create policy assignments
- ❌ Configure Azure resources

### Deployment: Via Initiatives

Actual Azure deployment happens through **Policy Initiatives** located in `/initiatives/storage/`:

**Initiative Structure:**

- `policies.json` - Base initiative with core policies
- `policies-dev.json` - Development environment policies
- `policies-prod.json` - Production environment policies
- `policies-sandbox.json` - Sandbox environment policies

**Deployment Flow:**

```text
1. Policy Bundle Published (v1.0.0)
   ↓
2. Initiative References Bundle Version
   ↓
3. Terraform/ARM Deploys Initiative
   ↓
4. Azure Policy Assignment Created
```

For deployment instructions, see the [Initiative Consumption Guide](../../docs/Initiative-Consumption-Guide.md).

## Bundle Contents

### 1. Deny Storage Account Public Access

**Policy ID:** `deny-storage-account-public-access`  
**Checkov ID:** CKV_AZURE_190  
**Severity:** High  
**Default Effect:** Deny

Prevents storage accounts from allowing public blob access or public container access. Storage accounts should have public access disabled for security purposes.

**Key Features:**

- Blocks public blob access
- Prevents public container access
- Validates network access configuration

### 2. Deny Storage Blob Logging Disabled

**Policy ID:** `deny-storage-blob-logging-disabled`  
**Checkov ID:** CKV2_AZURE_21  
**Severity:** Medium  
**Default Effect:** Audit

Ensures blob service logging is enabled for Azure Storage accounts. Logging provides audit trails for access to storage data and helps with security monitoring and compliance requirements.

**Key Features:**

- Validates diagnostic settings
- Requires StorageRead logging
- Requires StorageWrite logging
- Requires StorageDelete logging

### 3. Deny Storage Account Without HTTPS-Only Traffic

**Policy ID:** `deny-storage-https-disabled`  
**Severity:** High  
**Default Effect:** Deny

Enforces HTTPS-only traffic for all storage account communications, ensuring secure transport encryption.

**Key Features:**

- Enforces HTTPS-only access
- Supports storage account type filtering
- Allows exemption list for specific accounts

**Parameters:**

- `effect`: Audit, Deny, or Disabled
- `exemptedStorageAccounts`: Array of exempted account names
- `storageAccountTypes`: Array of storage account SKUs to validate

### 4. Deny Storage Account Soft Delete Disabled

**Policy ID:** `deny-storage-softdelete`  
**Severity:** Medium  
**Default Effect:** Deny

Requires soft delete to be enabled for blobs and containers for data protection and recovery purposes.

**Key Features:**

- Validates blob soft delete settings
- Validates container soft delete settings
- Enforces minimum retention period

**Parameters:**

- `effect`: Audit, Deny, or Disabled
- `minimumRetentionDays`: Minimum retention days (default: 7, range: 1-365)

### 5. Deny Storage Account Blob Versioning Disabled

**Policy ID:** `deny-storage-version`  
**Severity:** Medium  
**Default Effect:** Deny

Ensures blob versioning is enabled for data protection, compliance, and recovery purposes.

**Key Features:**

- Validates blob versioning configuration
- Supports storage account type filtering
- Allows exemption list for specific accounts

**Parameters:**

- `effect`: Audit, Deny, or Disabled
- `exemptedStorageAccounts`: Array of exempted account names
- `storageAccountTypes`: Array of storage account SKUs to validate

## Compliance Mapping

| Policy | Checkov | Azure Security Benchmark | Other Frameworks |
|--------|---------|-------------------------|------------------|
| deny-storage-account-public-access | CKV_AZURE_190 | ✓ | - |
| deny-storage-blob-logging-disabled | CKV2_AZURE_21 | ✓ | NIST |
| deny-storage-https-disabled | - | ✓ | PCI-DSS |
| deny-storage-softdelete | - | ✓ | Data Protection |
| deny-storage-version | - | ✓ | Data Protection |

## Version Management

This bundle follows **Semantic Versioning (SemVer)**:

- **MAJOR** (x.0.0): Breaking changes to policy rules
- **MINOR** (1.x.0): New policies added or significant enhancements
- **PATCH** (1.0.x): Bug fixes or minor refinements

**Current Version:** 1.0.0  
See [CHANGELOG.md](./CHANGELOG.md) for version history.

### Bundled Versioning Strategy

All policies in this bundle share a single version number. When any policy is updated:

1. The bundle version increments according to the change type
2. All policies are re-published together
3. The CHANGELOG documents which specific policies changed

## Deployment

### Prerequisites

- Terraform >= 1.13.0
- Azure Provider >= 4.45.0
- Azure subscription with appropriate permissions
- Policy Contributor or Resource Policy Contributor role

### Terraform Cloud Deployment

```hcl
# Deploy the storage policy bundle
module "storage_policies" {
  source  = "app.terraform.io/YOUR-ORG/storage-policy-bundle/azurerm"
  version = "1.0.0"

  # Deployment Configuration
  assignment_scope_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group}"
  environment         = "production"
  owner              = "security-team"

  # Policy Controls (enable/disable individual policies)
  enable_public_access_policy = true
  enable_blob_logging_policy  = true
  enable_https_policy         = true
  enable_softdelete_policy    = true
  enable_versioning_policy    = true

  # Global Effect Override
  policy_effect = "Deny"  # Options: Audit, Deny, Disabled

  # Policy-Specific Parameters
  softdelete_retention_days = 30
  https_exempted_accounts  = ["devstorageaccount"]
}
```

### MyGet Package Installation

```powershell
# Install from MyGet feed
Install-Package AzurePolicy.Storage.SecurityBundle -Version 1.0.0 -Source https://www.myget.org/F/YOUR-FEED/api/v3/index.json

# Extract and use
$packagePath = "path/to/extracted/package"
cd $packagePath/content/terraform
terraform init
terraform plan
terraform apply
```

### GitHub Actions Deployment

```yaml
- name: Deploy Storage Policy Bundle
  uses: ./.github/workflows/deploy-storage-bundle.yml
  with:
    version: '1.0.0'
    resource_group: 'rg-production'
    environment: 'production'
    policy_effect: 'Deny'
```

## Individual Policy Toggle

Each policy can be individually enabled or disabled during deployment:

```hcl
module "storage_policies" {
  source  = "..."
  version = "1.0.0"

  # Enable only specific policies
  enable_public_access_policy = true
  enable_blob_logging_policy  = true
  enable_https_policy         = false  # Disabled
  enable_softdelete_policy    = true
  enable_versioning_policy    = false  # Disabled
}
```

## Policy Effects

All policies support three effects:

- **Audit**: Log non-compliant resources but allow creation
- **Deny**: Block creation of non-compliant resources
- **Disabled**: Deactivate the policy

### Effect Recommendations

| Environment | Recommended Effect | Rationale |
|-------------|-------------------|-----------|
| Production | Deny | Enforce security requirements |
| Staging | Deny | Match production configuration |
| Development | Audit | Allow flexibility for testing |
| Sandbox | Disabled | Maximum flexibility |

## Testing and Validation

### Unit Testing

```powershell
# Run policy unit tests
Invoke-Pester -Path tests/storage/Storage.Unit-*.Tests.ps1
```

### Integration Testing

```powershell
# Run integration tests (requires Azure subscription)
Invoke-Pester -Path tests/storage/Storage.Integration-*.Tests.ps1
```

## Rollback Procedures

### Version Rollback

```hcl
# Rollback to previous version
module "storage_policies" {
  source  = "app.terraform.io/YOUR-ORG/storage-policy-bundle/azurerm"
  version = "0.9.0"  # Previous version
  # ... rest of configuration
}
```

### Emergency Disable

```hcl
# Disable all policies in emergency
module "storage_policies" {
  source  = "..."
  version = "1.0.0"

  policy_effect = "Disabled"  # Temporarily disable all policies
}
```

## Troubleshooting

### Common Issues

**Issue:** Policies blocking legitimate storage accounts

**Solution:** Use exemption lists:

```hcl
https_exempted_accounts = ["legacystorageaccount"]
```

**Issue:** Soft delete causing costs

**Solution:** Adjust retention period:

```hcl
softdelete_retention_days = 7  # Minimum allowed
```

**Issue:** Versioning not supported on storage account type

**Solution:** Filter storage account types:

```hcl
versioning_storage_types = ["Standard_LRS", "Standard_GRS"]
```

## Contributing

To propose changes to this bundle:

1. Create a feature branch
2. Update relevant policy files
3. Update bundle.metadata.json
4. Update CHANGELOG.md
5. Submit pull request
6. Version will be bumped upon merge

## Support

- **Issues:** Report via GitHub Issues
- **Documentation:** See [docs/](../../docs/)
- **Tests:** See [tests/storage/](../../tests/storage/)

## License

MIT License - See [LICENSE](../../LICENSE) file for details

## Additional Resources

- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Azure Storage Security Guide](https://docs.microsoft.com/azure/storage/common/storage-security-guide)
- [Checkov Documentation](https://www.checkov.io/)
- [Terraform Cloud Registry](https://registry.terraform.io/)

---

**Version:** 1.0.0  
**Last Updated:** 2025-10-11  
**Maintained by:** Azure Policy Testing Project
