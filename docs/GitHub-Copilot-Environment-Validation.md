# GitHub Copilot Environment Configuration & Validation Guide

This guide provides comprehensive instructions for validating the GitHub Copilot environment configuration and testing connectivity to Azure.

## Overview

The GitHub Copilot environment requires specific environment variables to be configured for:

1. **Azure Authentication** - Service Principal credentials for Azure access
2. **Terraform Cloud** - API token and organization for Terraform Cloud integration (optional)

## Required Environment Variables

### Azure Service Principal (Required)

These variables are essential for authenticating to Azure:

| Variable | Description | Example |
|----------|-------------|---------|
| `ARM_CLIENT_ID` | Service Principal Application (Client) ID | `50ac2ed1-1ea1-46e6-9992-6c5de5f5da24` |
| `ARM_CLIENT_SECRET` | Service Principal Secret | `***` (hidden) |
| `ARM_TENANT_ID` | Azure AD Tenant ID | `725ad9b-4d37-4c38-b78d-3859e706283d` |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID | `09e01a7d-07d4-43ee-80c7-8b2c0d7ec41f` |

### Terraform Cloud (Optional)

These variables enable Terraform Cloud integration:

| Variable | Description | Example |
|----------|-------------|---------|
| `TF_API_TOKEN` | Terraform Cloud API Token | `***` (hidden) |
| `TF_CLOUD_ORGANIZATION` | Terraform Cloud Organization Name | `azure-policy-compliance` |

## Setting Up Environment Variables

### GitHub Codespaces

1. Go to [GitHub Codespaces Settings](https://github.com/settings/codespaces)
2. Click **New secret** under "Codespaces secrets"
3. Add each required variable:
   - **Name**: Variable name (e.g., `ARM_CLIENT_ID`)
   - **Value**: Variable value
   - **Repository access**: Select this repository
4. Repeat for all required variables

### GitHub Actions (Repository Secrets)

1. Go to your repository settings
2. Navigate to **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each required variable
5. Repeat for all required variables

### GitHub Environments

1. Go to your repository settings
2. Navigate to **Environments**
3. Select or create an environment (e.g., `copilot`)
4. Add environment secrets for each required variable

## Validation Process

### Quick Validation (Recommended)

For a complete validation workflow that includes environment variables, Azure authentication, and connectivity testing:

```powershell
./scripts/Validate-GitHubCopilotEnvironment.ps1
```

This comprehensive script:

- ✅ Validates all environment variables (ARM_\* and TF_\*)
- ✅ Tests Azure authentication and connectivity
- ✅ Runs storage policy tests to verify end-to-end functionality
- ✅ Provides clear success/failure feedback

**Expected Output:**

```text
╔═══════════════════════════════════════════════════════════╗
║  GitHub Copilot Environment Validation & Testing         ║
╚═══════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step 1: Validating Environment Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

... environment validation output ...

✅ Environment validation completed successfully!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step 2: Testing Azure Connectivity with Storage Tests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 Running storage policy tests to verify Azure connectivity...
... storage test output ...

✅ Storage tests completed successfully!

╔═══════════════════════════════════════════════════════════╗
║           ✅ Validation & Testing Complete!               ║
╚═══════════════════════════════════════════════════════════╝

🎉 Your GitHub Copilot environment is correctly configured!
```

### Detailed Validation

#### Step 1: Validate Environment Configuration

Run the environment validation script to check all required variables:

```powershell
./scripts/Test-EnvironmentConfiguration.ps1
```

This script will:

- ✅ Check all Azure environment variables (`ARM_*`)
- ✅ Check Terraform Cloud variables (`TF_*`) - optional
- ✅ Authenticate to Azure using Service Principal
- ✅ Verify Azure resource access and permissions
- ✅ Check for the testing resource group

**Expected Output:**

```text
╔════════════════════════════════════════════════════════╗
║  GitHub Copilot Environment Configuration Validator   ║
╚════════════════════════════════════════════════════════╝

========================================
  Validating Azure Environment Variables
========================================
   ✅ ARM_CLIENT_ID: 50ac2ed1-1ea1-46e6-9992-6c5de5f5da24
   ✅ ARM_CLIENT_SECRET: [HIDDEN]
   ✅ ARM_TENANT_ID: 725ad9b-4d37-4c38-b78d-3859e706283d
   ✅ ARM_SUBSCRIPTION_ID: 09e01a7d-07d4-43ee-80c7-8b2c0d7ec41f

========================================
  Validating Terraform Cloud Environment Variables
========================================
   ✅ TF_API_TOKEN: [HIDDEN]
   ✅ TF_CLOUD_ORGANIZATION: azure-policy-compliance

========================================
  Testing Azure Connectivity
========================================
   🔐 Authenticating to Azure...
   ✅ Successfully connected to Azure
      Subscription: Azure Policy Testing
      Tenant: 725ad9b-4d37-4c38-b78d-3859e706283d
      Account: 50ac2ed1-1ea1-46e6-9992-6c5de5f5da24

   🔍 Testing Azure permissions...
   ✅ Can access 5 resource group(s)
   ✅ Testing resource group 'rg-azure-policy-testing' exists

========================================
  Validation Summary
========================================
   ✅ Environment configuration is valid!

   📝 Next steps:
      - Run storage tests: ./scripts/Run-StorageTest.ps1
      - Test policy compliance: ./scripts/Test-PolicyCompliance.ps1
      - Deploy policies: ./scripts/Deploy-PolicyDefinitions.ps1
```

### Step 2: Test Azure Connectivity (Optional)

The validation script automatically tests Azure connectivity. To skip this test:

```powershell
./scripts/Test-EnvironmentConfiguration.ps1 -SkipAzureConnectivityTest
```

### Step 3: Run Storage Tests

Once environment validation passes, test Azure connectivity by running the storage policy tests:

```powershell
./scripts/Run-StorageTest.ps1
```

This script will:

- ✅ Verify Azure connection
- ✅ Check/create the testing resource group (`rg-azure-policy-testing`)
- ✅ Run integration tests for storage account policies
- ✅ Validate policy enforcement

## Troubleshooting

### Missing Environment Variables

**Problem:** Variables are not set or missing.

**Solution:**

1. Verify variables are added to GitHub Codespaces/Actions secrets
2. Ensure correct variable names (case-sensitive)
3. For Codespaces: Rebuild the Codespace after adding secrets
4. For Actions: Re-run the workflow

### Authentication Failures

**Problem:** Azure authentication fails with AADSTS errors.

**Solution:**

1. Verify Service Principal credentials are correct
2. Check that Service Principal has not expired
3. Ensure Service Principal has access to the subscription
4. Verify the Tenant ID is correct

### Permission Errors

**Problem:** Cannot access resource groups or resources.

**Solution:**

1. Verify Service Principal has appropriate RBAC roles
2. Check subscription access
3. Ensure resource group exists or can be created
4. Required permissions: Contributor or custom role with resource group access

### Azure PowerShell Module Not Installed

**Problem:** Script warns about missing Azure PowerShell modules.

**Solution:**
Install required modules:

```powershell
./scripts/Install-Requirements.ps1
```

## Complete Validation Workflow

### Option 1: Comprehensive Validation (Recommended)

Use the all-in-one validation script that performs all checks automatically:

```powershell
# Complete validation workflow
./scripts/Validate-GitHubCopilotEnvironment.ps1
```

This single command:

1. ✅ Validates all environment variables
2. ✅ Tests Azure authentication
3. ✅ Runs storage tests to verify connectivity

### Option 2: Manual Step-by-Step Validation

For more control over each validation step:

```powershell
# 1. Validate environment configuration
./scripts/Test-EnvironmentConfiguration.ps1

# 2. If validation passes, authenticate to Azure (if not already authenticated)
./scripts/Connect-AzureServicePrincipal.ps1

# 3. Run storage policy tests to verify Azure connectivity
./scripts/Run-StorageTest.ps1

# 4. (Optional) Run all policy compliance tests
./scripts/Test-PolicyCompliance.ps1
```

## Quick Reference

### Validation Commands

| Command | Purpose |
|---------|---------|
| `./scripts/Validate-GitHubCopilotEnvironment.ps1` | **Recommended:** Complete validation workflow (env vars + auth + storage tests) |
| `./scripts/Validate-GitHubCopilotEnvironment.ps1 -SkipStorageTest` | Validate environment + Azure auth only |
| `./scripts/Validate-GitHubCopilotEnvironment.ps1 -SkipAzureAuth` | Validate environment variables only |
| `./scripts/Test-EnvironmentConfiguration.ps1` | Detailed environment validation + Azure connectivity test |
| `./scripts/Test-EnvironmentConfiguration.ps1 -SkipAzureConnectivityTest` | Validate environment variables only |
| `./scripts/Connect-AzureServicePrincipal.ps1` | Authenticate to Azure using Service Principal |
| `./scripts/Run-StorageTest.ps1` | Test Azure connectivity with storage policy tests |

### Environment Variable Check

Quick check if variables are set:

```powershell
# Azure variables
$env:ARM_CLIENT_ID
$env:ARM_CLIENT_SECRET     # Will show the value - be careful!
$env:ARM_TENANT_ID
$env:ARM_SUBSCRIPTION_ID

# Terraform Cloud variables
$env:TF_API_TOKEN          # Will show the value - be careful!
$env:TF_CLOUD_ORGANIZATION
```

**Note:** Avoid printing sensitive variables (`ARM_CLIENT_SECRET`, `TF_API_TOKEN`) in logs or console output.

## CI/CD Integration

### GitHub Actions Workflow Example

```yaml
name: Validate Environment

on:
  workflow_dispatch:
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    environment: copilot  # Uses environment secrets

    steps:
      - uses: actions/checkout@v5

      - name: Setup PowerShell
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Validate Environment Configuration
        run: |
          pwsh -File ./scripts/Test-EnvironmentConfiguration.ps1
        env:
          ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
          ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
          TF_API_TOKEN: ${{ secrets.TF_API_TOKEN }}
          TF_CLOUD_ORGANIZATION: ${{ secrets.TF_CLOUD_ORGANIZATION }}

      - name: Run Storage Tests
        run: |
          pwsh -File ./scripts/Run-StorageTest.ps1
        env:
          ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
          ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
```

## Related Documentation

- [Codespaces Azure Authentication Guide](./Codespaces-Azure-Authentication.md)
- [Azure Auth Quick Start](./AZURE-AUTH-QUICK-START.md)
- [Terraform Cloud Setup Guide](./Terraform-Cloud-Setup-Guide.md)
- [Scripts Directory README](../scripts/README.md)

## Support

For issues or questions:

1. Check validation script output for specific error messages
2. Review troubleshooting section above
3. Consult related documentation links
4. Open an issue with validation output and error details
