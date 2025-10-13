# Initiative Consumption Guide

## Overview

This guide explains how to consume published Policy Bundles through Azure Policy Initiatives for actual deployment to Azure subscriptions.

## Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                    Publishing Layer                          │
│  Policy Bundle → MyGet/Terraform Cloud (Versioned Packages) │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                   Consumption Layer                          │
│    Initiatives Reference Specific Bundle Versions           │
│    (initiatives/storage/policies-prod.json)                 │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                   Deployment Layer                           │
│    Terraform/ARM Deploys Initiatives to Azure              │
│    (Creates Policy Assignments)                             │
└─────────────────────────────────────────────────────────────┘
```

## Key Concepts

### Policy Bundle

- **Purpose**: Publish versioned policy definitions
- **Location**: `policies/storage/` (source code)
- **Published To**: MyGet, Terraform Cloud Registry
- **Versioning**: Semantic versioning (1.0.0)
- **Does NOT**: Deploy to Azure

### Initiative

- **Purpose**: Group and configure policies for deployment
- **Location**: `initiatives/storage/`
- **References**: Specific bundle versions
- **Environment-Specific**: Dev, Prod, Sandbox configurations
- **Does**: Deploy to Azure subscriptions

## Initiative Structure

### Current Initiative Files

```text
initiatives/storage/
├── policies.json           # Base initiative (core policies)
├── policies-dev.json       # Development environment
├── policies-prod.json      # Production environment
└── policies-sandbox.json   # Sandbox/testing environment
```

### Initiative Schema

Each initiative JSON file contains:

```json
[
  {
    "policy_display_name": "deny-storage-account-public-access",
    "policy_definition_reference_id": "CKV_AZURE_190",
    "parameters": {},
    "version": "1.0.0"
  }
]
```

**Fields:**

- `policy_display_name`: Policy identifier from bundle
- `policy_definition_reference_id`: Compliance framework reference (Checkov ID)
- `parameters`: Policy-specific configuration
- `version`: Bundle version this policy comes from

## Environment-Specific Strategies

### Production Environment (`policies-prod.json`)

**Characteristics:**

- Strict policy enforcement
- Pinned bundle versions
- Effect: `Deny` (blocks non-compliant resources)
- Minimal exemptions
- Full audit coverage

**Example:**

```json
[
  {
    "policy_display_name": "deny-storage-account-public-access",
    "policy_definition_reference_id": "CKV_AZURE_190",
    "parameters": {
      "effect": "Deny"
    },
    "version": "1.0.0"
  }
]
```

### Development Environment (`policies-dev.json`)

**Characteristics:**

- Flexible policy enforcement
- May use latest bundle versions
- Effect: `Audit` (logs but doesn't block)
- More exemptions allowed
- Testing new policy versions

**Example:**

```json
[
  {
    "policy_display_name": "deny-storage-https-disabled",
    "policy_definition_reference_id": "CKV2_AZURE_33",
    "parameters": {
      "effect": "Audit",
      "exemptedStorageAccounts": ["devtestaccount"]
    },
    "version": "1.1.0"
  }
]
```

### Sandbox Environment (`policies-sandbox.json`)

**Characteristics:**

- Minimal enforcement
- Latest bundle versions for testing
- Effect: `Disabled` or `Audit`
- Maximum flexibility
- Testing ground for new policies

## Version Management Strategy

### Version Pinning in Production

Production initiatives should pin to specific bundle versions:

```json
{
  "version": "1.0.0"  // Pinned to specific version
}
```

**Benefits:**

- Predictable behavior
- Controlled rollout
- Easy rollback
- Change management compliance

### Version Flexibility in Development

Development initiatives may use ranges or latest:

```json
{
  "version": "1.x.x"  // Latest minor/patch version
}
```

**Benefits:**

- Early detection of issues
- Continuous testing
- Faster feedback loop

## Consuming Published Bundles

### Step 1: Check Available Versions

**Via MyGet:**

```powershell
# List available versions
Find-Package AzurePolicy.Storage.SecurityBundle -AllVersions -Source https://www.myget.org/F/YOUR-FEED/
```

**Via Terraform Cloud:**

```bash
# View module versions
terraform init
terraform providers
```

### Step 2: Update Initiative Configuration

Edit the appropriate initiative file (`policies-prod.json`, etc.):

```json
[
  {
    "policy_display_name": "deny-storage-account-public-access",
    "policy_definition_reference_id": "CKV_AZURE_190",
    "parameters": {
      "effect": "Deny"
    },
    "version": "1.1.0"  // Updated version
  }
]
```

### Step 3: Deploy Initiative

**Using Terraform:**

```hcl
# initiatives/storage/main.tf
locals {
  prod_policies = jsondecode(file("${path.module}/policies-prod.json"))
}

# Fetch policy bundle
data "http" "storage_bundle" {
  url = "https://www.myget.org/F/YOUR-FEED/api/v2/package/AzurePolicy.Storage.SecurityBundle/${local.prod_policies[0].version}"
}

# Create Policy Initiative (Policy Set)
resource "azurerm_policy_set_definition" "storage_prod" {
  name         = "storage-security-prod"
  policy_type  = "Custom"
  display_name = "Storage Security - Production"
  description  = "Production storage security policies from bundle v${local.prod_policies[0].version}"

  dynamic "policy_definition_reference" {
    for_each = local.prod_policies
    content {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/${policy_definition_reference.value.policy_display_name}"
      reference_id         = policy_definition_reference.value.policy_definition_reference_id
      parameter_values     = jsonencode(policy_definition_reference.value.parameters)
    }
  }
}

# Assign Initiative to Subscription
resource "azurerm_subscription_policy_assignment" "storage_prod" {
  name                 = "storage-security-prod-assignment"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = azurerm_policy_set_definition.storage_prod.id
  location             = "eastus"

  identity {
    type = "SystemAssigned"
  }
}
```

### Step 4: Verify Deployment

```bash
# Check policy assignment
az policy assignment list --query "[?name=='storage-security-prod-assignment']"

# Check compliance
az policy state list --resource-group YOUR_RG --filter "policyAssignmentName eq 'storage-security-prod-assignment'"
```

## Upgrade Workflow

### Upgrading to a New Bundle Version

1. **Review Changelog**

   ```bash
   # Check what changed in new version
   cat policies/storage/CHANGELOG.md
   ```

2. **Test in Sandbox**

   ```json
   // initiatives/storage/policies-sandbox.json
   {
     "version": "1.2.0"  // New version
   }
   ```

3. **Deploy to Sandbox**

   ```bash
   terraform apply -target=azurerm_policy_assignment.storage_sandbox
   ```

4. **Validate in Sandbox**
   - Check compliance reports
   - Verify no unexpected blocks
   - Test with sample resources

5. **Promote to Dev**

   ```json
   // initiatives/storage/policies-dev.json
   {
     "version": "1.2.0"
   }
   ```

6. **Monitor Dev Environment**
   - Review audit logs
   - Collect feedback
   - Verify business processes unaffected

7. **Promote to Production**

   ```json
   // initiatives/storage/policies-prod.json
   {
     "version": "1.2.0"
   }
   ```

8. **Document Deployment**
   - Record version in change log
   - Update runbooks
   - Notify stakeholders

## Rollback Procedures

### Scenario: Production Issue with New Version

1. **Identify Issue**

   ```bash
   # Check recent compliance changes
   az policy state list --filter "timestamp ge datetime'2025-10-11'"
   ```

2. **Immediate Mitigation**

   **Option A: Disable Problematic Policy**

   ```json
   {
     "policy_display_name": "deny-storage-https-disabled",
     "parameters": {
       "effect": "Disabled"  // Temporary disable
     },
     "version": "1.2.0"
   }
   ```

   **Option B: Rollback Initiative**

   ```json
   {
     "version": "1.1.0"  // Previous working version
   }
   ```

3. **Deploy Rollback**

   ```bash
   terraform apply -target=azurerm_policy_assignment.storage_prod
   ```

4. **Verify Rollback**

   ```bash
   # Confirm old version deployed
   az policy assignment show -n storage-security-prod-assignment
   ```

5. **Document Incident**
   - Record issue in tracking system
   - Update CHANGELOG
   - Plan fix for next version

## Best Practices

### 1. Version Control

- Always commit initiative changes to Git
- Use pull requests for production changes
- Require approvals for production initiative updates

### 2. Testing Strategy

```text
Sandbox → Dev → Prod
  ↓        ↓      ↓
 Days    Weeks   Planned
```

### 3. Change Management

- Document all initiative changes
- Link to bundle changelog
- Maintain deployment history

### 4. Monitoring

- Set up Azure Policy compliance dashboards
- Alert on new non-compliant resources
- Track exemption requests

### 5. Documentation

- Keep environment differences documented
- Maintain exemption registry
- Document known issues per version

## Troubleshooting

### Issue: Policy Not Enforcing

**Check:**

1. Initiative version deployed: `az policy assignment show`
2. Policy effect parameter: Should be `Deny` not `Audit`
3. Assignment scope: Verify subscription/resource group
4. Exemptions: Check if resource has exemption

### Issue: Bundle Version Not Found

**Solution:**

1. Verify version exists in registry
2. Check network access to MyGet/Terraform Cloud
3. Validate version format (1.0.0 not v1.0.0)

### Issue: Unexpected Policy Blocks

**Resolution:**

1. Review compliance reports
2. Check policy parameters
3. Verify bundle changelog for breaking changes
4. Add temporary exemption if needed

## Examples

### Complete Production Initiative

```json
[
  {
    "policy_display_name": "deny-storage-account-public-access",
    "policy_definition_reference_id": "CKV_AZURE_190",
    "parameters": {
      "effect": "Deny"
    },
    "version": "1.0.0"
  },
  {
    "policy_display_name": "deny-storage-https-disabled",
    "policy_definition_reference_id": "CKV2_AZURE_33",
    "parameters": {
      "effect": "Deny",
      "exemptedStorageAccounts": []
    },
    "version": "1.0.0"
  },
  {
    "policy_display_name": "deny-storage-softdelete",
    "policy_definition_reference_id": "CKV2_AZURE_38",
    "parameters": {
      "effect": "Deny",
      "minimumRetentionDays": 30
    },
    "version": "1.0.0"
  }
]
```

## Additional Resources

- [Storage Bundle README](../policies/storage/BUNDLE-README.md)
- [Versioning Guide](./Storage-Bundle-Versioning-Guide.md)
- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

**Last Updated:** 2025-10-11  
**Maintained by:** Azure Policy Testing Project
