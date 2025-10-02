# DevContainer Test Setup - Quick Fix Summary

## ✅ What Was Fixed

### 1. Installed Missing PowerShell Modules

The following critical modules were missing and have been installed:

- **Pester 5.4.0** - PowerShell testing framework
- **PSScriptAnalyzer 1.21.0** - Code analysis tool
- **Az.Accounts 2.12.1** - Azure authentication (optional)
- **Az.Resources 6.6.0** - Azure resource management (optional)
- **Az.PolicyInsights 1.6.1** - Azure policy insights (optional)

### 2. Updated VS Code Settings

Fixed PowerShell configuration in `.vscode/settings.json`:

- Changed `powershell.powerShellDefaultVersion` to `"pwsh"` (correct for Linux)
- Updated terminal profile to use `"pwsh"` instead of `"PowerShell"`

### 3. Updated DevContainer Setup Script

Improved `.devcontainer/setup.sh` to:

- Better error handling for module installation
- Priority-based installation (critical modules first)
- Verification of critical modules after installation

### 4. Created Helper Scripts

- **`scripts/Fix-DevContainerTests.ps1`** - Diagnostic and repair script
- **`DEVCONTAINER-TESTING-FIX.md`** - Comprehensive troubleshooting guide

## 🚀 Next Steps (IMPORTANT!)

### Step 1: Reload VS Code Window

The PowerShell extension needs to detect the newly installed modules:

1. Press **`Ctrl+Shift+P`** (or `Cmd+Shift+P` on Mac)
2. Type: **"Developer: Reload Window"**
3. Press **Enter**

### Step 2: Restart PowerShell Session (After Reload)

1. Press **`Ctrl+Shift+P`** again
2. Type: **"PowerShell: Restart Session"**
3. Press **Enter**

### Step 3: Open Test Explorer

1. Click the **Testing** icon in the left sidebar (flask/beaker icon)
2. Click the **"Refresh Tests"** button (circular arrow icon at the top)
3. Your test files should now appear!

## 📋 Verification

Run this command to verify everything is working:

```bash
pwsh -ExecutionPolicy Bypass -File ./scripts/Fix-DevContainerTests.ps1
```

Expected output: "✅ All checks passed! Test setup is ready."

## 🧪 Test Your Setup

### Run a Single Unit Test

```bash
pwsh -Command "Invoke-Pester -Path tests/storage/Storage.Unit-DenyStorageHttpsDisabled.Tests.ps1 -Output Detailed"
```

### Run All Unit Tests

```bash
pwsh -Command "Invoke-Pester -Path tests/storage/*Unit*.Tests.ps1 -Output Detailed"
```

### Using Test Explorer

1. Open Test Explorer (Testing icon in sidebar)
2. Expand test folders
3. Click any test or test file
4. Click the **Run Test** button (play icon)

## 📚 Test Types

### Unit Tests (Fast, No Azure Required)

- Pattern: `*.Unit-*.Tests.ps1`
- Test JSON definitions and logic
- Run immediately, no setup required
- Example: `Storage.Unit-DenyStorageHttpsDisabled.Tests.ps1`

### Integration Tests (Requires Azure)

- Pattern: `*.Integration-*.Tests.ps1`
- Create actual Azure resources
- Require Azure authentication
- Example: `Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1`

For integration tests, you need to authenticate with Azure:

```bash
az login
az account set --subscription "your-subscription-id"
```

## 🔍 Troubleshooting

### Tests Still Not Showing?

1. **Check Output Panel:**
   - View → Output
   - Select "Pester" from dropdown
   - Look for error messages

2. **Check PowerShell Extension:**
   - View → Output
   - Select "PowerShell" from dropdown
   - Look for startup errors

3. **Verify Modules:**

   ```bash
   pwsh -Command "Get-Module -ListAvailable Pester, PSScriptAnalyzer | Format-Table Name, Version, Path"
   ```

4. **Re-run Fix Script:**

   ```bash
   pwsh -ExecutionPolicy Bypass -File ./scripts/Fix-DevContainerTests.ps1
   ```

### Still Having Issues?

1. Close VS Code completely
2. Reopen the devcontainer
3. Wait for all extensions to finish loading (check status bar)
4. Run the fix script again
5. Reload window

## 📖 Additional Documentation

- **Comprehensive Guide:** `DEVCONTAINER-TESTING-FIX.md`
- **Test Explorer Setup:** `docs/VSCode-Test-Explorer-Setup.md`
- **Integration Tests:** `docs/Running-Integration-Tests.md`
- **DevContainer Reference:** `docs/DevContainer-Quick-Reference.md`

## ✨ Status

- ✅ PowerShell 7.5.3 installed
- ✅ Pester 5.4.0 installed
- ✅ PSScriptAnalyzer 1.21.0 installed
- ✅ VS Code settings updated for Linux
- ✅ Test files validated
- ✅ Command-line testing works

**Ready to use after reloading VS Code window!**

---

**Last Updated:** October 2, 2025
**DevContainer:** Ubuntu 24.04.3 LTS
