# VS Code Terminal Profile Configuration

## Overview

The `.vscode/settings.json` file has been configured to automatically load the project-specific PowerShell profile (`PowerShell/Microsoft.PowerShell_profile.ps1`) when you open a new PowerShell terminal in VS Code.

## Configuration

### Terminal Profile Settings

```json
"terminal.integrated.profiles.linux": {
    "pwsh": {
        "path": "/opt/microsoft/powershell/7/pwsh",
        "icon": "terminal-powershell",
        "args": [
            "-WorkingDirectory",
            "${workspaceFolder}",
            "-Command",
            ". ${workspaceFolder}/PowerShell/Microsoft.PowerShell_profile.ps1"
        ]
    }
},
"terminal.integrated.defaultProfile.linux": "pwsh"
```

### How It Works

1. **Path**: Uses the PowerShell 7 executable
2. **Working Directory**: Sets to the workspace folder
3. **Command**: Dot-sources the project profile using `. ${workspaceFolder}/PowerShell/Microsoft.PowerShell_profile.ps1`

This ensures that every time you open a PowerShell terminal in VS Code, it will:

- Start in the project directory
- Load your general PowerShell profile (`~/.config/powershell/profile.ps1`)
- Load the project-specific profile (`PowerShell/Microsoft.PowerShell_profile.ps1`)

## What You'll See

When you open a new PowerShell terminal, you should see:

```text
🚀 Azure Policy & Functions PowerShell Environment Loaded!

Quick Commands:
  azconnect          - Connect to Azure
  azctx              - Show Azure context
  policies           - List policy definitions
  ...

=== Azure Policy Testing Environment ===
Available commands:
  Test-AzurePolicyCompliance (alias: tpc)
  Deploy-AzurePolicyDefinition (alias: dpd)
  Get-PolicyComplianceReport (alias: gcr)
  Initialize-AzurePolicyProject (alias: init-azure)

Run 'init-azure' to initialize the environment
===============================================
```

## Profile Loading Order

1. **General Profile** (`~/.config/powershell/profile.ps1`)
   - Your personal PowerShell customizations
   - Shows the "Azure Policy & Functions" banner

2. **Project Profile** (`PowerShell/Microsoft.PowerShell_profile.ps1`)
   - Project-specific functions and aliases
   - Shows the "Azure Policy Testing Environment" banner

## Available Profiles

You can switch between terminal profiles in VS Code:

1. Click the `+` dropdown in the terminal panel
2. Select from:
   - **pwsh** - PowerShell with project profile (default)
   - **bash** - Standard Bash shell
   - **zsh** - Z shell

## Customization

### Change Default Profile

To use a different shell as default, modify `.vscode/settings.json`:

```json
"terminal.integrated.defaultProfile.linux": "bash"
```

### Add Another Profile

Add additional terminal profiles:

```json
"terminal.integrated.profiles.linux": {
    "pwsh": { ... },
    "my-custom-profile": {
        "path": "/bin/bash",
        "args": ["-c", "echo 'Hello!' && bash"]
    }
}
```

## Troubleshooting

### Profile Not Loading

**Symptom**: Terminal opens but doesn't show the project profile messages

**Solutions**:

1. **Reload Window**:
   - `Ctrl+Shift+P` → "Developer: Reload Window"

2. **Close and Reopen Terminal**:
   - Close all terminal tabs
   - Open a new terminal with `Ctrl+Shift+` ` (backtick)

3. **Verify Profile Exists**:

   ```bash
   ls -l PowerShell/Microsoft.PowerShell_profile.ps1
   ```

4. **Test Profile Manually**:

   ```powershell
   . ./PowerShell/Microsoft.PowerShell_profile.ps1
   ```

### Error: Profile Script Not Found

**Symptom**: Error message about missing profile script

**Solution**: Ensure you're opening the terminal from the workspace root. The `${workspaceFolder}` variable resolves to the workspace root directory.

### Want Only Project Profile (Skip General Profile)

**Symptom**: Don't want the general profile to load

**Solution**: Use `-NoProfile` flag:

```json
"args": [
    "-NoProfile",
    "-WorkingDirectory",
    "${workspaceFolder}",
    "-Command",
    ". ${workspaceFolder}/PowerShell/Microsoft.PowerShell_profile.ps1"
]
```

### Terminal Color Customization

You can customize the terminal appearance:

```json
"terminal.integrated.profiles.linux": {
    "pwsh": {
        "path": "/opt/microsoft/powershell/7/pwsh",
        "icon": "terminal-powershell",
        "color": "terminal.ansiCyan",
        "args": [ ... ]
    }
}
```

Available colors:

- `terminal.ansiBlack`
- `terminal.ansiRed`
- `terminal.ansiGreen`
- `terminal.ansiYellow`
- `terminal.ansiBlue`
- `terminal.ansiMagenta`
- `terminal.ansiCyan`
- `terminal.ansiWhite`

## DevContainer Compatibility

This configuration works in both:

✅ **Local Development** - When opening the project locally
✅ **DevContainer** - When running in a container
✅ **GitHub Codespaces** - When using Codespaces

The `${workspaceFolder}` variable automatically resolves to the correct path in all environments.

## Related Files

- `.vscode/settings.json` - Terminal profile configuration
- `PowerShell/Microsoft.PowerShell_profile.ps1` - Project PowerShell profile
- `~/.config/powershell/profile.ps1` - Your general PowerShell profile (not in repo)
- `.devcontainer/setup.sh` - DevContainer setup script

## Testing

To test the configuration:

1. Open a new PowerShell terminal in VS Code
2. Verify the project profile loaded:

   ```powershell
   Get-Command Test-AzurePolicyCompliance
   Get-Alias tpc
   ```

3. Check you're in the right directory:

   ```powershell
   pwd
   # Should show: /home/vagrant/git/terraform-azure-policy
   ```

---

**Last Updated**: October 6, 2025  
**Configuration File**: `.vscode/settings.json`  
**Profile Location**: `PowerShell/Microsoft.PowerShell_profile.ps1`
