# VS Code Test Explorer Setup for Azure Policy Tests

This guide explains how to configure VS Code Test Explorer to run Azure Policy integration tests.

## Overview

The integration tests require an active Azure authentication context. When running tests from VS Code's Test Explorer, you need to establish an Azure connection that persists across test runs.

## Configuration Options

### Option 1: Use Saved Azure Context (Recommended)

This is the easiest approach for local development:

1. **Authenticate once in PowerShell:**

   ```powershell
   # Open PowerShell terminal in VS Code
   Connect-AzAccount

   # Verify connection
   Get-AzContext

   # Save the context (enables automatic reuse)
   Save-AzContext -Path "$HOME/.azure/AzureContext.json"
   ```

2. **The tests will automatically:**
   - Try to use the current Azure context
   - If no active context, load saved contexts
   - Skip tests gracefully if no Azure authentication is available

3. **Configure test behavior** in `config/test-config.ps1`:

   ```powershell
   Azure = @{
       # Skip tests instead of failing when no context
       SkipIfNoContext = $true  # Set to $false to fail tests instead
   }
   ```

### Option 2: Keep Azure Session Active

Maintain an active PowerShell session:

1. Open a PowerShell terminal in VS Code
2. Run `Connect-AzAccount`
3. Keep this terminal open while running tests
4. Tests will use the active Azure context

### Option 3: Service Principal (CI/CD)

For automated testing environments:

1. **Create a service principal:**

   ```bash
   az ad sp create-for-rbac --name "PolicyTestingSP" \
     --role Contributor \
     --scopes /subscriptions/{subscription-id}/resourceGroups/rg-azure-policy-testing
   ```

2. **Set environment variables:**

   ```powershell
   $env:AZURE_CLIENT_ID = "your-client-id"
   $env:AZURE_CLIENT_SECRET = "your-client-secret"  # pragma: allowlist secret
   $env:AZURE_TENANT_ID = "your-tenant-id"
   ```

3. **Authenticate before running tests:**

   ```powershell
   $securePassword = ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force  # pragma: allowlist secret
   $credential = New-Object System.Management.Automation.PSCredential($env:AZURE_CLIENT_ID, $securePassword)  # pragma: allowlist secret
   Connect-AzAccount -ServicePrincipal -TenantId $env:AZURE_TENANT_ID -Credential $credential  # pragma: allowlist secret
   ```

## Test Behavior

### With Azure Context Available

- Tests run normally
- Resources are created/deleted in Azure
- Policy compliance is validated
- Expected: 16 tests passed, 3 skipped (per test file)

### Without Azure Context

When `SkipIfNoContext = $true` (default):

- Tests are skipped gracefully
- No errors reported
- Message: "Skipping all tests - no Azure context available"
- Expected: All tests skipped

When `SkipIfNoContext = $false`:

- Tests fail immediately
- Error: "Environment initialization failed: No Azure context found"
- Must run `Connect-AzAccount` before testing

## Running Tests

### From Test Explorer

1. Click the Testing icon in VS Code sidebar (flask icon)
2. Ensure Azure context is established (see options above)
3. Click "Run All Tests" or run individual test files
4. View results in Test Explorer panel

### From Terminal

Run tests with explicit Azure connection check:

```powershell
# Run storage tests (includes Azure connectivity check)
./scripts/Run-StorageTest.ps1

# Run specific test file
Invoke-Pester -Path tests/storage/Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1 -Output Detailed  # pragma: allowlist secret

# Run all storage tests
Invoke-Pester -Path tests/storage/ -Output Detailed  # pragma: allowlist secret
```

## Troubleshooting

### Issue: Tests Skip with "No Azure context available"

**Cause:** No active or saved Azure authentication

**Solution:**

```powershell
Connect-AzAccount
Save-AzContext -Path "$HOME/.azure/AzureContext.json"
```

### Issue: Tests Fail with "Resource group not found"

**Cause:** Test resource group doesn't exist

**Solution:**

```powershell
New-AzResourceGroup -Name "rg-azure-policy-testing" -Location "eastus"
```

### Issue: "Token expired" or "Authentication failed"

**Cause:** Saved context is expired

**Solution:**

```powershell
# Re-authenticate
Connect-AzAccount

# Update saved context
Save-AzContext -Path "$HOME/.azure/AzureContext.json" -Force
```

### Issue: Tests hang or timeout

**Cause:** Azure operations can be slow

**Solution:**

- Adjust timeouts in `config/test-config.ps1`:

  ```powershell
  Timeouts = @{
      PolicyEvaluationWaitSeconds = 60  # Increase if needed
  }
  ```

## Best Practices

1. **Keep Azure Context Fresh**
   - Azure tokens expire after 1-2 hours
   - Re-authenticate when needed
   - Use `Get-AzContext` to check current status

2. **Test Locally Before CI/CD**
   - Run tests with `./scripts/Run-StorageTest.ps1`
   - Verify all prerequisites are met
   - Check resource cleanup after tests

3. **Use Tags for Selective Testing**

   ```powershell
   # Run only fast tests (no Azure resources created)
   Invoke-Pester -Path tests/storage/*.Tests.ps1 -Tag 'Fast' -Output Detailed  # pragma: allowlist secret

   # Run only unit tests
   Invoke-Pester -Path tests/storage/*.Tests.ps1 -Tag 'Unit' -Output Detailed  # pragma: allowlist secret
   ```

4. **Monitor Azure Costs**
   - Integration tests create temporary storage accounts
   - Tests should clean up automatically
   - Verify cleanup with: `Get-AzStorageAccount -ResourceGroupName "rg-azure-policy-testing"`

## Configuration Reference

Key settings in `config/test-config.ps1`:

```powershell
$script:TestConfig = @{
    Azure = @{
        ResourceGroupName           = 'rg-azure-policy-testing'
        DefaultLocation             = 'East US'
        RequireValidSubscription    = $true
        ValidateResourceGroupExists = $true
        SkipIfNoContext             = $true  # Key setting for Test Explorer
    }
}
```

## Additional Resources

- [Azure PowerShell Authentication](https://docs.microsoft.com/powershell/azure/authenticate-azureps)
- [VS Code Pester Test Adapter](https://marketplace.visualstudio.com/items?itemName=pspester.pester-test)
- [Running Integration Tests Guide](./Running-Integration-Tests.md)
