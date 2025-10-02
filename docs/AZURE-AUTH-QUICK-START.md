# Azure Authentication Quick Guide for Integration Tests

## Quick Start (3 Steps)

### 1. Login to Azure CLI

```bash
az login
```

A browser window will open. Sign in with your Azure credentials.

### 2. Set Your Subscription

```bash
# List available subscriptions
az account list --output table

# Set the subscription you want to use
az account set --subscription "your-subscription-name-or-id"
```

### 3. Verify Resource Group

```bash
# Check if test resource group exists
az group show --name rg-azure-policy-testing

# If not, create it
az group create --name rg-azure-policy-testing --location eastus
```

## Automated Setup (Recommended)

Run our setup script to do everything automatically:

```bash
pwsh -ExecutionPolicy Bypass -File ./scripts/Setup-AzureForTesting.ps1
```

This script will:

- ✅ Check Azure CLI authentication
- ✅ Display current subscription
- ✅ Create resource group if needed
- ✅ Connect Az PowerShell modules
- ✅ Save Azure context for test reuse
- ✅ Verify permissions

## Now Run Your Tests

### From VS Code Test Explorer

1. Open Test Explorer (flask icon in sidebar)
2. Expand the test folders
3. Click on any Integration test
4. Click the "Run Test" button (play icon)

### From Command Line

```bash
# Run all storage integration tests
pwsh -Command "Invoke-Pester -Path tests/storage/*Integration*.Tests.ps1 -Output Detailed"

# Run specific integration test
pwsh -Command "Invoke-Pester -Path tests/storage/Storage.Integration-DenyStorageHttpsDisabled.Tests.ps1 -Output Detailed"

# Run the helper script
./scripts/Run-StorageTest.ps1
```

## Troubleshooting

### "Not logged in" error

```bash
az login
az account show
```

### "Subscription not set" error

```bash
az account list --output table
az account set --subscription "your-subscription-id"
```

### "Resource group not found" error

```bash
az group create --name rg-azure-policy-testing --location eastus
```

### "Token expired" error

```bash
# Re-authenticate
az login

# Reconnect PowerShell
pwsh -Command "Connect-AzAccount"
```

## Current Test Status

Based on your Test Explorer:

✅ **Unit Tests (26 total)** - Working!

- No Azure required
- Fast execution
- Already passing

⚠️ **Integration Tests** - Need Azure authentication

- Require Azure CLI login
- Create real Azure resources
- Take longer to run

## What Each Test Type Does

### Unit Tests (Fast)

- Validate JSON policy definitions
- Check policy structure and syntax
- No Azure resources created
- Run in seconds

### Integration Tests (Slow)

- Deploy policies to Azure
- Create test storage accounts
- Validate compliance in real Azure
- Clean up resources after test
- Take 30-60 seconds each

## Next Steps After Authentication

1. ✅ Login complete → Run setup script
2. ✅ Setup complete → Reload VS Code Test Explorer
3. ✅ Tests visible → Click "Refresh Tests" button
4. ✅ Ready → Run integration tests!

---

**Need Help?**

- Setup script: `./scripts/Setup-AzureForTesting.ps1`
- Full docs: `docs/VSCode-Test-Explorer-Setup.md`
- Integration tests: `docs/Running-Integration-Tests.md`
