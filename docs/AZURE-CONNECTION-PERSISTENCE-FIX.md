# Fixing Azure Connection Persistence in DevContainer

## The Problem

You're experiencing the issue where:

1. ✅ `az login` works and you can authenticate
2. ❌ PowerShell Az modules don't stay connected
3. ❌ Integration tests fail because Az context is not available

This happens because **Azure CLI** and **PowerShell Az modules** use separate authentication systems that don't automatically sync.

## The Solution

### Option 1: Automated Fix (Recommended)

Run this simple script after `az login`:

```bash
./scripts/fix-azure-connection.sh
```

This will:

- ✅ Detect your Azure CLI session
- ✅ Connect PowerShell Az modules using CLI credentials
- ✅ Save the context permanently
- ✅ Enable auto-loading for future sessions
- ✅ Verify resource group access

### Option 2: Interactive PowerShell Setup

For more control, run the PowerShell script:

```bash
pwsh -ExecutionPolicy Bypass -File ./scripts/Connect-AzureSession.ps1
```

This offers multiple authentication methods:

1. **Azure CLI token** (instant, recommended)
2. **Device code** (works anywhere)
3. **Browser** (may not work in devcontainer)

### Option 3: Manual Steps

If scripts don't work, do it manually:

```bash
# 1. Login to Azure CLI
az login
az account set --subscription "your-subscription-name"

# 2. Connect PowerShell
pwsh
```

Then in PowerShell:

```powershell
# Import module
Import-Module Az.Accounts

# Get CLI credentials and connect
$cliAccount = az account show | ConvertFrom-Json
$token = az account get-access-token --resource https://management.azure.com --query accessToken -o tsv
Connect-AzAccount -AccessToken $token -AccountId $cliAccount.user.name -TenantId $cliAccount.tenantId

# Save context (IMPORTANT for persistence!)
Save-AzContext -Path ~/.azure/AzureRmContext.json -Force

# Enable auto-loading (IMPORTANT!)
Enable-AzContextAutosave -Scope CurrentUser

# Verify
Get-AzContext
```

## Why This Happens

### In Local Development

- Azure CLI and PowerShell Az share authentication via `~/.azure/` directory
- Context persists automatically

### In DevContainer

- Fresh environment each time
- Authentication needs to be explicitly saved
- Auto-context loading must be enabled
- Tokens expire and need refresh

## Verification

After running the fix, verify it worked:

```bash
# Check Azure CLI
az account show

# Check PowerShell Az
pwsh -Command "Get-AzContext"

# Should show the same subscription in both!
```

Expected output:

```text
Account               : your-email@domain.com
SubscriptionName      : Your Subscription Name
SubscriptionId        : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
TenantId              : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Environment           : AzureCloud
```

## Test It

Once connected, run a test:

```bash
# From command line
pwsh -Command "Invoke-Pester -Path tests/storage/Storage.Integration-DenyStorageHttpsDisabled.Tests.ps1 -Output Detailed"

# Or from VS Code Test Explorer
# Click on any Integration test and run it
```

## Troubleshooting

### "Context not found" error

```bash
# Re-run the fix script
./scripts/fix-azure-connection.sh

# Or manually reconnect
pwsh -Command "Connect-AzAccount -UseDeviceAuthentication; Save-AzContext -Force; Enable-AzContextAutosave"
```

### "Token expired" error

```bash
# Re-login to Azure CLI
az login

# Re-run fix script
./scripts/fix-azure-connection.sh
```

### Connection works but doesn't persist

```bash
# Ensure context is saved AND autosave is enabled
pwsh -Command "
    Save-AzContext -Path ~/.azure/AzureRmContext.json -Force
    Enable-AzContextAutosave -Scope CurrentUser
    Get-AzContextAutosaveSetting
"
```

### Still not working?

Try the device code method (always works):

```bash
pwsh -Command "
    Connect-AzAccount -UseDeviceAuthentication
    Save-AzContext -Force
    Enable-AzContextAutosave -Scope CurrentUser
"
```

## Key Concepts

### Azure CLI (`az`)

- Uses `~/.azure/accessTokens.json`
- Command: `az login`
- Verify: `az account show`

### PowerShell Az Modules

- Uses `~/.azure/AzureRmContext.json`
- Command: `Connect-AzAccount`
- Verify: `Get-AzContext`

### Making It Persistent

1. **Save Context**: `Save-AzContext -Force`
2. **Enable Autosave**: `Enable-AzContextAutosave`
3. Both are needed!

## Quick Commands Reference

```bash
# Check if Azure CLI is connected
az account show

# Check if PowerShell is connected
pwsh -Command "Get-AzContext"

# Fix connection persistence
./scripts/fix-azure-connection.sh

# Manually reconnect if needed
pwsh -Command "Connect-AzAccount -UseDeviceAuthentication"

# Force save context
pwsh -Command "Save-AzContext -Path ~/.azure/AzureRmContext.json -Force"

# Enable auto-load
pwsh -Command "Enable-AzContextAutosave -Scope CurrentUser"

# Check autosave status
pwsh -Command "Get-AzContextAutosaveSetting"
```

## After Setup

Once fixed, your integration tests will work:

1. ✅ Open VS Code Test Explorer
2. ✅ Expand test folders
3. ✅ Click any Integration test
4. ✅ Click Run (play button)
5. ✅ Tests create real Azure resources
6. ✅ Tests validate policies
7. ✅ Resources are cleaned up automatically

## Need Help?

- Run diagnostic: `./scripts/Fix-DevContainerTests.ps1`
- Check docs: `docs/VSCode-Test-Explorer-Setup.md`
- Run setup: `./scripts/Connect-AzureSession.ps1`

---

**TL;DR**: Run `./scripts/fix-azure-connection.sh` after `az login` to make PowerShell Az modules stay connected! 🚀
