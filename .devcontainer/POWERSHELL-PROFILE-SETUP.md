# PowerShell Profile Setup in DevContainer

## Overview

This devcontainer is configured to load the project-specific PowerShell profile that provides Azure Policy development tools and helpers.

## Profile Loading Order

PowerShell profiles are loaded in the following order:

1. **Global Profile** (`profile.ps1`) - Loads first
   - Location: `~/.config/powershell/profile.ps1`
   - Contains general PowerShell customizations
   - Applies to all PowerShell sessions

2. **Current Host Profile** (`Microsoft.PowerShell_profile.ps1`) - Loads second
   - Location: `~/.config/powershell/Microsoft.PowerShell_profile.ps1`
   - Symlinked to: `/workspaces/terraform-azure-policy/PowerShell/Microsoft.PowerShell_profile.ps1`
   - Contains project-specific Azure Policy tools

## What the Project Profile Provides

The Azure Policy PowerShell profile includes:

### 🛠️ Functions

- **Test-AzurePolicyCompliance** (alias: `tpc`) - Test policy compliance
- **Deploy-AzurePolicyDefinition** (alias: `dpd`) - Deploy policy definitions
- **Get-PolicyComplianceReport** (alias: `gcr`) - Generate compliance reports
- **Initialize-AzurePolicyProject** (alias: `init-azure`) - Initialize environment

### 📦 Auto-Imported Modules

- `Az.Accounts`
- `Az.Resources`
- `Az.PolicyInsights`
- `PSScriptAnalyzer`
- `Pester`

### 🔐 Auto-Authentication (Codespaces Only)

When running in GitHub Codespaces with ARM credentials configured:

- Automatically authenticates to Azure using service principal
- Runs the `Connect-AzureServicePrincipal.ps1` script

### 🌍 Environment Variables

- `AZURE_POLICY_PROJECT_ROOT` - Set to project root directory

## Setup in DevContainer

The `setup.sh` script automatically creates a symbolic link:

```bash
ln -sf $WORKSPACE_ROOT/PowerShell/Microsoft.PowerShell_profile.ps1 \
       ~/.config/powershell/Microsoft.PowerShell_profile.ps1
```

### Why Symbolic Link?

Using a symbolic link instead of copying ensures:

- ✅ Changes to the project profile are immediately reflected
- ✅ No synchronization issues between copies
- ✅ Single source of truth for the profile
- ✅ Works across devcontainer rebuilds

## Manual Setup (If Needed)

If the profile isn't loading, run these commands:

```bash
# Create PowerShell config directory
mkdir -p ~/.config/powershell

# Create symbolic link to project profile
ln -sf /workspaces/terraform-azure-policy/PowerShell/Microsoft.PowerShell_profile.ps1 \
       ~/.config/powershell/Microsoft.PowerShell_profile.ps1

# Verify the link
ls -l ~/.config/powershell/Microsoft.PowerShell_profile.ps1
```

## Verifying Profile Load

Open a new PowerShell terminal and you should see:

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
  ...
```

## Testing Profile Path

Run this command to verify which profile is loaded:

```powershell
pwsh -Command '$PROFILE | Select-Object *'
```

Expected output:

```text
AllUsersAllHosts       : /opt/microsoft/powershell/7/profile.ps1
AllUsersCurrentHost    : /opt/microsoft/powershell/7/Microsoft.PowerShell_profile.ps1
CurrentUserAllHosts    : /home/vscode/.config/powershell/profile.ps1
CurrentUserCurrentHost : /home/vscode/.config/powershell/Microsoft.PowerShell_profile.ps1
```

## Troubleshooting

### Profile Not Loading

**Symptom:** PowerShell opens without the Azure Policy environment message

**Solution:**

```bash
# Check if symbolic link exists
ls -l ~/.config/powershell/Microsoft.PowerShell_profile.ps1

# If missing, recreate it
ln -sf /workspaces/terraform-azure-policy/PowerShell/Microsoft.PowerShell_profile.ps1 \
       ~/.config/powershell/Microsoft.PowerShell_profile.ps1
```

### Wrong User Directory

**Symptom:** Profile setup fails during container creation

**Solution:** The setup.sh script now dynamically detects the current user instead of hardcoding `/home/vscode`. If you're running as a different user (e.g., `vagrant`), the script will automatically use `$HOME/.config/powershell`.

### Dual Profile Messages

**Symptom:** Seeing messages from both a generic profile and the project profile

**Explanation:** This is normal! PowerShell loads both:

1. `profile.ps1` - Your general PowerShell customizations
2. `Microsoft.PowerShell_profile.ps1` - Project-specific Azure Policy tools

Both profiles coexist and provide different functionalities.

### Module Installation Failures

**Symptom:** Errors about missing Az modules

**Solution:**

```powershell
# Run the requirements installation script
pwsh -ExecutionPolicy Bypass -File scripts/Install-Requirements.ps1 -IncludeOptional
```

## DevContainer vs Local Mode

### Local Mode

- Loads your machine's global PowerShell profile
- Then loads the project profile if you manually linked it

### DevContainer Mode

- Automatically sets up the symbolic link during container creation
- Ensures consistent environment across all developers
- Profile is ready immediately on first terminal open

## Customization

To customize the project PowerShell profile, edit:

```text
PowerShell/Microsoft.PowerShell_profile.ps1
```

Changes will be reflected immediately in all new PowerShell sessions (due to symbolic link).

## VS Code Settings

The devcontainer.json configures VS Code to use PowerShell as the default terminal:

```json
{
  "terminal.integrated.defaultProfile.linux": "pwsh",
  "powershell.startAsLoginShell.linux": true
}
```

This ensures:

- PowerShell is the default terminal
- Profiles are loaded on terminal startup
- Login shell mode for proper environment initialization

---

**Location:** `/workspaces/terraform-azure-policy/PowerShell/Microsoft.PowerShell_profile.ps1`  
**Link Location:** `~/.config/powershell/Microsoft.PowerShell_profile.ps1`  
**Setup Script:** `.devcontainer/setup.sh` (lines 181-194)
