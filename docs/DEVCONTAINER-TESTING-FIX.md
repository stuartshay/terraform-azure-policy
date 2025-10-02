# DevContainer Testing Fix Guide

## Problem Summary

When running tests in the devcontainer for the first time, the Pester and PSScriptAnalyzer modules were not installed properly during the initial setup, causing tests to fail in the VS Code Test Explorer.

## Root Cause

The `setup.sh` script attempted to install PowerShell modules, but the installation may have failed silently or been incomplete during the initial devcontainer build.

## Solution Applied

### 1. Installed Required PowerShell Modules

```bash
pwsh -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module -Name Pester -RequiredVersion 5.4.0 -Scope CurrentUser -Force -AllowClobber"

pwsh -Command "Install-Module -Name PSScriptAnalyzer -RequiredVersion 1.21.0 -Scope CurrentUser -Force -AllowClobber"
```

### 2. Updated VS Code Settings

Updated `.vscode/settings.json` to properly configure PowerShell in the Linux devcontainer:

- Changed `powershell.powerShellDefaultVersion` from `"PowerShell (x64)"` to `"pwsh"` (correct for Linux)
- Updated terminal profile name from `"PowerShell"` to `"pwsh"` to match Linux conventions
- Updated default terminal profile to `"pwsh"`

## Verification Steps

### 1. Verify Modules are Installed

```bash
pwsh -Command "Get-Module -ListAvailable Pester, PSScriptAnalyzer | Select-Object Name, Version, Path | Format-Table -AutoSize"
```

Expected output:

```text
Name             Version Path
----             ------- ----
Pester           5.4.0   /home/vscode/.local/share/powershell/Modules/Pester/5.4.0/Pester.psd1
PSScriptAnalyzer 1.21.0  /home/vscode/.local/share/powershell/Modules/PSScriptAnalyzer/1.21.0/PSScriptAnalyzer.psd1
```

### 2. Test Pester from Command Line

```bash
pwsh -Command "Invoke-Pester -Path tests/storage/Storage.Unit-DenyStorageHttpsDisabled.Tests.ps1 -Output Detailed"
```

You should see test results showing all tests passing.

### 3. Reload VS Code Window

**IMPORTANT:** For the Test Explorer to detect the newly installed modules:

1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
2. Type "Developer: Reload Window"
3. Press Enter

### 4. Restart PowerShell Extension

After reloading the window, restart the PowerShell extension:

1. Press `Ctrl+Shift+P`
2. Type "PowerShell: Restart Session"
3. Press Enter

### 5. Check Test Explorer

1. Click the Testing icon in the left sidebar (flask icon)
2. You should see your test files discovered:
   - `storage/Storage.Unit-DenyStorageHttpsDisabled.Tests.ps1`
   - `storage/Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1`
   - Other test files...
3. Click the "Refresh Tests" button (circular arrow icon) in the Test Explorer
4. Tests should now be discoverable and runnable

### 6. Run Tests from Test Explorer

- Click on any test file or individual test
- Click the "Run Test" button (play icon)
- Tests should execute and show results

## Troubleshooting

### Issue: Tests Still Not Showing in Test Explorer

**Solution:**

1. Close VS Code completely
2. Reopen the devcontainer
3. Wait for all extensions to load (check bottom right for "Extension Host" status)
4. Check the Output panel → Select "Pester" from dropdown
5. Look for any error messages

### Issue: "Pester module not found" in Test Explorer

**Solution:**

```bash
# Check if Pester is in the module path
pwsh -Command "\$env:PSModulePath"

# Verify Pester can be imported
pwsh -Command "Import-Module Pester; Get-Command -Module Pester | Select-Object -First 5"
```

### Issue: PowerShell Extension Not Working Properly

**Solution:**

1. Check PowerShell version: `pwsh -Version`
2. Check extension output: View → Output → Select "PowerShell"
3. Reinstall the extension if needed:
   - Uninstall "PowerShell" extension
   - Reload window
   - Reinstall "PowerShell" extension

### Issue: Tests Show but Won't Run

**Solution:**

1. Check if test file has `#Requires -Modules Pester` at the top
2. Verify the test file syntax:

   ```bash
   pwsh -Command "Import-Module Pester; Invoke-Pester -Path 'path/to/test.Tests.ps1' -DryRun"
   ```

3. Check the `.vscode/settings.json` pester configuration

## Additional Azure-Related Test Issues

### For Integration Tests Requiring Azure

Integration tests need Azure authentication. See the full guide in [docs/VSCode-Test-Explorer-Setup.md](docs/VSCode-Test-Explorer-Setup.md).

Quick setup:

```bash
# Authenticate with Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Verify resource group exists
az group show --name rg-azure-policy-testing

# If not, create it
az group create --name rg-azure-policy-testing --location eastus
```

### Running Unit Tests vs Integration Tests

**Unit Tests** (No Azure required):

- Pattern: `*.Unit-*.Tests.ps1`
- Run immediately after module installation
- Fast execution (< 1 second)
- Example: `Storage.Unit-DenyStorageHttpsDisabled.Tests.ps1`

**Integration Tests** (Azure required):

- Pattern: `*.Integration-*.Tests.ps1`
- Require Azure authentication
- Slower execution (10-30 seconds)
- Example: `Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1`

To run only unit tests:

```bash
pwsh -Command "Invoke-Pester -Path tests/storage/*Unit*.Tests.ps1 -Output Detailed"
```

## Complete Setup Script

If you need to set up from scratch in a new devcontainer:

```bash
#!/bin/bash
# Run this script to set up testing in the devcontainer

echo "Installing PowerShell modules..."
pwsh -Command "
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    Install-Module -Name Pester -RequiredVersion 5.4.0 -Scope CurrentUser -Force -AllowClobber
    Install-Module -Name PSScriptAnalyzer -RequiredVersion 1.21.0 -Scope CurrentUser -Force -AllowClobber

    # Optional but useful modules
    Install-Module -Name Az.Accounts -RequiredVersion 2.12.1 -Scope CurrentUser -Force -AllowClobber
    Install-Module -Name Az.Resources -RequiredVersion 6.6.0 -Scope CurrentUser -Force -AllowClobber
    Install-Module -Name Az.PolicyInsights -RequiredVersion 1.6.1 -Scope CurrentUser -Force -AllowClobber

    Get-Module -ListAvailable Pester, PSScriptAnalyzer | Select-Object Name, Version
"

echo ""
echo "✅ Modules installed successfully!"
echo ""
echo "Next steps:"
echo "1. Press Ctrl+Shift+P and select 'Developer: Reload Window'"
echo "2. Open the Test Explorer (Testing icon in sidebar)"
echo "3. Click 'Refresh Tests' button"
echo "4. Run your tests!"
```

## VS Code Extension Settings Reference

Relevant settings in `.vscode/settings.json`:

```jsonc
{
    // PowerShell Configuration
    "powershell.powerShellDefaultVersion": "pwsh",
    "powershell.scriptAnalysis.enable": true,
    "powershell.scriptAnalysis.settingsPath": ".vscode/PSScriptAnalyzerSettings.psd1",

    // Terminal Configuration
    "terminal.integrated.defaultProfile.linux": "pwsh",

    // Pester Test Extension Configuration
    "pester.useLegacyCodeLens": false,
    "pester.outputVerbosity": "Detailed",
    "pester.debugOutputVerbosity": "Detailed",
    "pester.enableCodeLens": true,
    "pester.autoRefreshTests": true,
    "pester.respectGitIgnore": true,
    "pester.testFilePath": [
        "**/*.Tests.ps1",
        "**/tests/**/*.ps1"
    ],
    "pester.excludePath": [
        "**/node_modules/**",
        "**/.terraform/**",
        "**/reports/**",
        "**/config/**"
    ],
    "pester.testArgs": [
        "-CI"
    ],

    // Test Panel Configuration
    "testExplorer.useNativeTesting": true,
    "testing.automaticallyOpenPeekView": "failureInVisibleDocument",
    "testing.followRunningTest": true,
    "testing.defaultGutterClickAction": "run"
}
```

## Related Documentation

- [DevContainer Quick Reference](docs/DevContainer-Quick-Reference.md)
- [Test Panel Guide](docs/TestPanel-Guide.md)
- [VS Code Test Explorer Setup](docs/VSCode-Test-Explorer-Setup.md)
- [Running Integration Tests](docs/Running-Integration-Tests.md)

## Summary

The core issue was missing PowerShell modules in the devcontainer. After installing Pester and PSScriptAnalyzer, and updating the VS Code settings for Linux compatibility, tests should work properly in the Test Explorer.

**Remember to reload the VS Code window after installing modules!**
