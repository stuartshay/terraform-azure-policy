# Scripts Directory

This directory contains PowerShell scripts for managing Azure Policy definitions, deployments, and testing.

## Authentication

### Connect-AzureServicePrincipal.ps1

**Purpose:** Authenticate to Azure using Service Principal credentials from environment variables (ideal for CI/CD and Codespaces).

**Usage:**

```powershell
# Authenticate (skips if already connected)
./scripts/Connect-AzureServicePrincipal.ps1

# Force re-authentication
./scripts/Connect-AzureServicePrincipal.ps1 -Force
```

**Required Environment Variables:**

- `ARM_CLIENT_ID` - Service Principal Application ID
- `ARM_CLIENT_SECRET` - Service Principal Secret
- `ARM_TENANT_ID` - Azure AD Tenant ID
- `ARM_SUBSCRIPTION_ID` - Azure Subscription ID

**Documentation:** See [Codespaces Azure Authentication Guide](../docs/Codespaces-Azure-Authentication.md)

### Validate-GitHubCopilotEnvironment.ps1

**Purpose:** Complete validation workflow for GitHub Copilot environment - validates environment variables, tests Azure authentication, and runs storage tests.

**Usage:**

```powershell
# Complete validation (environment + auth + storage tests)
./scripts/Validate-GitHubCopilotEnvironment.ps1

# Skip storage tests
./scripts/Validate-GitHubCopilotEnvironment.ps1 -SkipStorageTest

# Only validate environment variables
./scripts/Validate-GitHubCopilotEnvironment.ps1 -SkipAzureAuth
```

**Validation Steps:**

1. Validates all environment variables (ARM_*and TF_*)
2. Tests Azure authentication and connectivity
3. Runs storage policy tests to verify end-to-end functionality

**Recommended:** Use this as the primary validation script for GitHub Copilot environments.

### Test-EnvironmentConfiguration.ps1

**Purpose:** Validate GitHub Copilot environment configuration and test Azure connectivity.

**Usage:**

```powershell
# Full validation (environment variables + Azure connectivity)
./scripts/Test-EnvironmentConfiguration.ps1

# Only validate environment variables (skip Azure connectivity test)
./scripts/Test-EnvironmentConfiguration.ps1 -SkipAzureConnectivityTest
```

**Validates:**

- Azure environment variables: `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`
- Terraform Cloud variables: `TF_API_TOKEN`, `TF_CLOUD_ORGANIZATION` (optional)
- Azure authentication and connectivity
- Azure resource group access and permissions

**Use Cases:**

- Validate GitHub Codespaces/Actions environment setup
- Troubleshoot authentication issues
- Verify environment configuration before running tests

---

## Policy Management

### Deploy-PolicyDefinitions.ps1

**Purpose:** Deploy Azure Policy definitions to Azure.

**Usage:**

```powershell
# Deploy all policies
./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath ./policies

# What-if deployment (preview changes)
./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath ./policies -WhatIf
```

### Validate-PolicyDefinitions.ps1

**Purpose:** Validate Azure Policy JSON definitions for syntax and schema compliance.

**Usage:**

```powershell
./scripts/Validate-PolicyDefinitions.ps1 -PolicyPath ./policies
```

---

## Testing

### Run-StorageTest.ps1

**Purpose:** Run storage account public access policy integration tests.

**Usage:**

```powershell
# Run with Azure connection check
./scripts/Run-StorageTest.ps1

# Skip Azure connection check
./scripts/Run-StorageTest.ps1 -SkipAzureCheck
```

### Invoke-PolicyTests.ps1

**Purpose:** Run all policy tests using Pester.

**Usage:**

```powershell
# Run all tests
./scripts/Invoke-PolicyTests.ps1 -TestPath ./tests -ResourceGroup rg-azure-policy-testing

# Run specific test category
./scripts/Invoke-PolicyTests.ps1 -TestPath ./tests/storage -ResourceGroup rg-azure-policy-testing

# Output to NUnit XML format
./scripts/Invoke-PolicyTests.ps1 -TestPath ./tests -ResourceGroup rg-azure-policy-testing -OutputFormat NUnitXml -OutputPath ./reports/results.xml
```

### Invoke-PolicyTests-WithCoverage.ps1

**Purpose:** Run policy tests with code coverage analysis.

**Usage:**

```powershell
# Run tests with coverage
./scripts/Invoke-PolicyTests-WithCoverage.ps1 -TestPath ./tests -CodeCoverage $true -CoverageTarget 80

# Generate HTML coverage report
./scripts/Invoke-PolicyTests-WithCoverage.ps1 -TestPath ./tests -CodeCoverage $true -GenerateHtmlReport -CoverageTarget 80
```

### Test-PolicyCompliance.ps1

**Purpose:** Check policy compliance status for Azure resources.

**Usage:**

```powershell
# Check compliance (table format)
./scripts/Test-PolicyCompliance.ps1 -OutputFormat Table

# Check compliance (JSON format)
./scripts/Test-PolicyCompliance.ps1 -OutputFormat Json
```

---

## Reporting

### Generate-PolicyReports.ps1

**Purpose:** Generate comprehensive policy compliance and assignment reports.

**Usage:**

```powershell
# Generate all report formats
./scripts/Generate-PolicyReports.ps1 -ResourceGroup rg-azure-policy-testing -Format All

# Generate specific format
./scripts/Generate-PolicyReports.ps1 -ResourceGroup rg-azure-policy-testing -Format HTML
```

### Generate-CoverageBadge.ps1

**Purpose:** Generate a code coverage badge SVG for documentation.

**Usage:**

```powershell
./scripts/Generate-CoverageBadge.ps1 -Coverage 85 -OutputPath ./reports/coverage-badge.svg
```

### Generate-CheckovReport.ps1

**Purpose:** Run Checkov security scanning and generate reports.

**Usage:**

```powershell
./scripts/Generate-CheckovReport.ps1
```

---

## Setup & Maintenance

### Install-ModulesForCI.ps1

**Purpose:** Install PowerShell modules for CI/CD environments with retry logic and error handling to handle firewall restrictions and network issues.

**Usage:**

```powershell
# Install default modules (Pester, PSScriptAnalyzer, Az.Accounts, Az.Resources)
./scripts/Install-ModulesForCI.ps1

# Install specific modules
./scripts/Install-ModulesForCI.ps1 -RequiredModules @('Pester', 'PSScriptAnalyzer')

# Install with custom retry settings
./scripts/Install-ModulesForCI.ps1 -RequiredModules @('Pester') -MaxRetries 5 -RetryDelaySeconds 10
```

**Features:**

- ✅ Automatic retry logic for failed installations (default: 3 attempts)
- ✅ PowerShell Gallery connectivity validation
- ✅ TLS 1.2 configuration for secure connections
- ✅ Module import verification
- ✅ Detailed logging and error reporting
- ✅ Handles firewall restrictions and network timeouts

**Parameters:**

- `-RequiredModules` - Array of module names to install (default: Pester, PSScriptAnalyzer, Az.Accounts, Az.Resources)
- `-MaxRetries` - Maximum retry attempts per module (default: 3)
- `-RetryDelaySeconds` - Delay between retries (default: 5 seconds)

**Use Cases:**

- GitHub Actions workflows (CI/CD)
- Environments with firewall restrictions
- Intermittent network connectivity scenarios
- Automated deployment pipelines

See [GitHub Actions Setup Guide](../docs/GitHub-Actions-Setup-Guide.md) for detailed usage in workflows.

### Install-Requirements.ps1

**Purpose:** Install required PowerShell modules and dependencies.

**Usage:**

```powershell
# Install required modules
./scripts/Install-Requirements.ps1

# Install required and optional modules
./scripts/Install-Requirements.ps1 -IncludeOptional
```

### Setup-PreCommit.ps1

**Purpose:** Configure pre-commit hooks for code quality checks.

**Usage:**

```powershell
./scripts/Setup-PreCommit.ps1
```

### Setup-TerraformBackend.ps1

**Purpose:** Initialize Terraform backend configuration for state management.

**Usage:**

```powershell
./scripts/Setup-TerraformBackend.ps1
```

### Setup-AzureCredentials.sh

**Purpose:** Configure Azure credentials for Terraform (bash script).

**Usage:**

```bash
./scripts/Setup-AzureCredentials.sh
```

---

## Quick Start for Codespaces

1. **Authenticate to Azure:**

   ```powershell
   ./scripts/Connect-AzureServicePrincipal.ps1
   ```

2. **Install dependencies:**

   ```powershell
   ./scripts/Install-Requirements.ps1 -IncludeOptional
   ```

3. **Validate policies:**

   ```powershell
   ./scripts/Validate-PolicyDefinitions.ps1 -PolicyPath ./policies
   ```

4. **Run tests:**

   ```powershell
   ./scripts/Run-StorageTest.ps1
   ```

---

## Prerequisites

- PowerShell 7.0 or later
- Azure PowerShell modules (installed via `Install-Requirements.ps1`)
- Pester 5.x for testing
- Active Azure subscription
- Appropriate Azure RBAC permissions

---

## Common Workflows

### Development Workflow

```powershell
# 1. Authenticate
./scripts/Connect-AzureServicePrincipal.ps1

# 2. Validate changes
./scripts/Validate-PolicyDefinitions.ps1 -PolicyPath ./policies

# 3. Run tests
./scripts/Invoke-PolicyTests.ps1 -TestPath ./tests -ResourceGroup rg-azure-policy-testing

# 4. Check coverage
./scripts/Invoke-PolicyTests-WithCoverage.ps1 -TestPath ./tests -CodeCoverage $true
```

### CI/CD Workflow

```powershell
# 1. Auto-authenticate (using environment variables)
./scripts/Connect-AzureServicePrincipal.ps1

# 2. Validate
./scripts/Validate-PolicyDefinitions.ps1 -PolicyPath ./policies

# 3. What-if deployment
./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath ./policies -WhatIf

# 4. Run tests with output
./scripts/Invoke-PolicyTests.ps1 -TestPath ./tests -OutputFormat NUnitXml -OutputPath ./results.xml

# 5. Deploy (if tests pass)
./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath ./policies
```

---

## Additional Documentation

- [Codespaces Azure Authentication Guide](../docs/Codespaces-Azure-Authentication.md)
- [Deployment Guide](../docs/Deployment-Guide.md)
- [Running Integration Tests](../docs/Running-Integration-Tests.md)
- [Code Coverage Guide](../docs/Code-Coverage-Guide.md)
- [Pre-commit Guide](../docs/PreCommit-Guide.md)
