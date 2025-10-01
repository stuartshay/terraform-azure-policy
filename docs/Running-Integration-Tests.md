# Running Integration Tests

This guide explains how to run the integration tests for Azure Policy definitions.

## Prerequisites

### 1. Azure PowerShell Modules

Ensure you have the required Azure PowerShell modules installed:

```powershell
# Check installed modules
Get-Module -ListAvailable -Name Az.Accounts, Az.Resources, Az.Storage, Az.PolicyInsights

# Install if missing
Install-Module -Name Az.Accounts, Az.Resources, Az.Storage, Az.PolicyInsights -Scope CurrentUser
```

### 2. Pester Testing Framework

```powershell
# Check Pester version (requires v5.x)
Get-Module -ListAvailable -Name Pester

# Install if missing or upgrade
Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force
```

### 3. Azure Authentication

Connect to your Azure subscription:

```powershell
# Interactive login
Connect-AzAccount

# Or with service principal
$credential = Get-Credential  # pragma: allowlist secret
Connect-AzAccount -ServicePrincipal -TenantId "your-tenant-id" -Credential $credential  # pragma: allowlist secret

# Verify connection
Get-AzContext
```

### 4. Azure Resources

The tests require:

- **Resource Group**: `rg-azure-policy-testing` (or environment-specific name)
- **Policy Assignment**: The policy must be assigned to the resource group
- **Permissions**: Contributor or Owner role on the resource group

#### Quick Setup Script

Use the helper script to automatically check and create the resource group:

```powershell
./scripts/Run-StorageTest.ps1
```

## Running Tests

### Run All Tests in a File

```powershell
Invoke-Pester -Path tests/storage/Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1 -Output Detailed  # pragma: allowlist secret
```

### Run Specific Test Tags

```powershell
# Run only fast tests (no Azure resources created)
Invoke-Pester -Path tests/storage/Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1 -Tag 'Fast' -Output Detailed  # pragma: allowlist secret

# Run only unit tests
Invoke-Pester -Path tests/storage/Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1 -Tag 'Unit' -Output Detailed  # pragma: allowlist secret

# Run compliance tests
Invoke-Pester -Path tests/storage/Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1 -Tag 'Compliance' -Output Detailed  # pragma: allowlist secret
```

### Run All Storage Tests

```powershell
Invoke-Pester -Path tests/storage/ -Output Detailed
```

## Common Issues and Solutions

### Issue: "No Azure context found"

**Error**: `Environment initialization failed: No Azure context found. Please run Connect-AzAccount first.`

**Solution**:

```powershell
Connect-AzAccount
Get-AzContext  # Verify connection
```

### Issue: "Resource group not found"

**Error**: `Resource group 'rg-azure-policy-testing' not found. Please create it first.`

**Solution**:

```powershell
New-AzResourceGroup -Name "rg-azure-policy-testing" -Location "eastus"
```

### Issue: "Policy not assigned"

**Error**: Tests pass but no compliance data available

**Solution**: Assign the policy to the resource group:

```powershell
# Get the policy definition
$policyDef = Get-AzPolicyDefinition | Where-Object { $_.Properties.DisplayName -like "*Deny Storage Account Public Access*" }

# Assign to resource group
$rg = Get-AzResourceGroup -Name "rg-azure-policy-testing"
New-AzPolicyAssignment -Name "deny-storage-public-access" `
    -PolicyDefinition $policyDef `
    -Scope $rg.ResourceId `
    -DisplayName "Deny Storage Account Public Access"
```

### Issue: "Module not found"

**Error**: `The term 'Get-AzStorageAccount' is not recognized...`

**Solution**:

```powershell
# Install missing module
Install-Module -Name Az.Storage -Scope CurrentUser -Force

# Reimport
Import-Module Az.Storage -Force
```

### Issue: Tests taking too long

Integration tests with Azure resources can take several minutes due to:

- Resource creation time (30-60 seconds)
- Policy evaluation delays (configurable in `config/test-config.ps1`)
- Compliance scan processing (30-60 seconds)

You can:

1. Run only fast/unit tests: `-Tag 'Fast'`
2. Adjust timeout values in `config/test-config.ps1`
3. Skip cleanup: Remove `AfterAll` block temporarily

## Test Configuration

Test configuration is centralized in:

- `config/test-config.ps1` - General settings, timeouts, modules
- `config/policies.json` - Policy-specific settings
- `config/config-loader.ps1` - Helper functions

### Environment Selection

Tests default to `prod` environment. To use different environments:

```powershell
# Modify test file or set environment variable
$env:TEST_ENVIRONMENT = "dev"
```

Environment settings in `config/policies.json`:

- `dev`: Uses `rg-azure-policy-testing-dev`
- `staging`: Uses `rg-azure-policy-testing-staging`
- `prod`: Uses `rg-azure-policy-testing`

## Understanding Test Output

### Test Tags

- **Unit**: Fast tests, no Azure resources
- **Integration**: Requires Azure connection
- **Fast**: Completes in < 5 seconds
- **Slow**: May take minutes
- **Compliance**: Creates resources and checks compliance
- **RequiresCleanup**: Creates resources (cleaned up in AfterAll)

### Test Structure

1. **BeforeAll**: Sets up configuration, connects to Azure
2. **Policy Definition Validation**: Checks JSON structure
3. **Policy Assignment Validation**: Verifies policy is assigned
4. **Policy Compliance Testing**: Creates test resources
5. **Policy Remediation Testing**: Tests fixing non-compliant resources
6. **AfterAll**: Cleanup test resources

## Debugging Tests

### Enable Verbose Output

```powershell
$VerbosePreference = "Continue"
Invoke-Pester -Path tests/storage/Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1 -Output Detailed
```

### Run Individual Test

```powershell
# Run specific test by name
Invoke-Pester -Path tests/storage/Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1 `
    -FullNameFilter "*Should have valid policy definition structure*" `
    -Output Detailed
```

### Check Azure Resources

```powershell
# List storage accounts in test resource group
Get-AzStorageAccount -ResourceGroupName "rg-azure-policy-testing"

# Check policy compliance
Get-AzPolicyState -ResourceGroupName "rg-azure-policy-testing"
```

## Best Practices

1. **Always cleanup**: Tests should clean up resources in `AfterAll` blocks
2. **Use tags**: Tag tests appropriately for selective execution
3. **Mock when possible**: Use mocks for unit tests, real resources for integration tests
4. **Check prerequisites**: Verify Azure connection before running integration tests
5. **Monitor costs**: Integration tests create Azure resources (usually deleted quickly)

## CI/CD Considerations

For automated test execution:

1. Use service principal authentication
2. Pre-create resource groups
3. Assign policies before running tests
4. Set appropriate timeouts
5. Implement retry logic for transient Azure failures
6. Clean up resources even on test failure

Example CI/CD setup:

```powershell
# Authenticate with service principal
```powershell
$securePassword = ConvertTo-SecureString $env:AZURE_SP_PASSWORD -AsPlainText -Force  # pragma: allowlist secret
$credential = New-Object System.Management.Automation.PSCredential($env:AZURE_SP_ID, $securePassword)  # pragma: allowlist secret
Connect-AzAccount -ServicePrincipal -TenantId $env:AZURE_TENANT_ID -Credential $credential  # pragma: allowlist secret

# Run tests
Invoke-Pester -Path tests/ -Tag 'Integration' -Output Detailed -CI
```

## Additional Resources

- [Pester Documentation](https://pester.dev/)
- [Azure PowerShell Documentation](https://docs.microsoft.com/powershell/azure/)
- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
