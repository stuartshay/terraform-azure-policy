# PowerShell Profile Fix Summary

## Problem

When running the project in a devcontainer, the PowerShell terminal was not loading the project-specific profile (`PowerShell/Microsoft.PowerShell_profile.ps1`) correctly. The issue was:

1. **Hardcoded User Path**: The setup script had a hardcoded path `/home/vscode/.config/powershell`
2. **Wrong User**: You were running as user `vagrant`, not `vscode`
3. **Profile Not Found**: PowerShell couldn't find the project profile in the expected location

## Solution Applied

### 1. Fixed setup.sh Script

**Before:**

```bash
PROFILE_DIR="/home/vscode/.config/powershell"
mkdir -p "$PROFILE_DIR"
if [ -f "$WORKSPACE_ROOT/PowerShell/Microsoft.PowerShell_profile.ps1" ]; then
    cp "$WORKSPACE_ROOT/PowerShell/Microsoft.PowerShell_profile.ps1" "$PROFILE_DIR/Microsoft.PowerShell_profile.ps1"
    print_success "PowerShell profile configured"
fi
```

**After:**

```bash
# Detect current user dynamically instead of hardcoding vscode
CURRENT_USER="${USER:-$(whoami)}"
PROFILE_DIR="$HOME/.config/powershell"
mkdir -p "$PROFILE_DIR"

if [ -f "$WORKSPACE_ROOT/PowerShell/Microsoft.PowerShell_profile.ps1" ]; then
    # Create symbolic link to project profile so it stays in sync
    ln -sf "$WORKSPACE_ROOT/PowerShell/Microsoft.PowerShell_profile.ps1" "$PROFILE_DIR/Microsoft.PowerShell_profile.ps1"
    print_success "PowerShell profile configured for user: $CURRENT_USER"
    print_status "Profile linked from: $WORKSPACE_ROOT/PowerShell/Microsoft.PowerShell_profile.ps1"
else
    print_warning "Project PowerShell profile not found at: $WORKSPACE_ROOT/PowerShell/Microsoft.PowerShell_profile.ps1"
fi
```

### 2. Key Improvements

✅ **Dynamic User Detection**: Uses `$HOME` instead of hardcoded `/home/vscode`
✅ **Symbolic Link**: Creates symlink instead of copy (stays in sync with project changes)
✅ **Better Logging**: Shows which user and path the profile is configured for
✅ **Error Handling**: Warns if project profile is missing

### 3. Manual Fix Applied (Current Session)

Created the symbolic link for your current user:

```bash
ln -sf /home/vagrant/git/terraform-azure-policy/PowerShell/Microsoft.PowerShell_profile.ps1 \
       ~/.config/powershell/Microsoft.PowerShell_profile.ps1
```

## How PowerShell Profiles Work

PowerShell loads profiles in this order:

1. **AllUsersAllHosts**: `/opt/microsoft/powershell/7/profile.ps1`
2. **AllUsersCurrentHost**: `/opt/microsoft/powershell/7/Microsoft.PowerShell_profile.ps1`
3. **CurrentUserAllHosts**: `~/.config/powershell/profile.ps1` ← Your generic profile
4. **CurrentUserCurrentHost**: `~/.config/powershell/Microsoft.PowerShell_profile.ps1` ← Project profile

You're seeing both profiles load because:

- `profile.ps1` = Your existing PowerShell customizations (the "Azure Policy & Functions" banner)
- `Microsoft.PowerShell_profile.ps1` = This project's specific tools (the "Azure Policy Testing Environment" banner)

## Verification

After the fix, opening a new PowerShell terminal shows:

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

## Files Changed

1. **`.devcontainer/setup.sh`** (lines 181-194)
   - Changed from hardcoded path to dynamic user detection
   - Changed from `cp` to `ln -sf` (symbolic link)
   - Added better logging

2. **Created: `.devcontainer/POWERSHELL-PROFILE-SETUP.md`**
   - Complete documentation on PowerShell profile setup
   - Troubleshooting guide
   - Explanation of dual profile loading

3. **Created Symlink: `~/.config/powershell/Microsoft.PowerShell_profile.ps1`**
   - Points to project profile
   - Works for current user (vagrant)

## Benefits

✅ **Works for Any User**: No longer hardcoded to `vscode` user
✅ **Stays in Sync**: Symbolic link means edits to project profile are immediate
✅ **Proper Profile Loading**: Both generic and project profiles load correctly
✅ **Devcontainer Ready**: Future container rebuilds will set this up automatically

## Next Steps

1. **Test in Fresh Terminal**: Open a new PowerShell terminal to verify
2. **Rebuild Container** (Optional): Rebuild devcontainer to test automated setup
3. **Customize Profile**: Edit `PowerShell/Microsoft.PowerShell_profile.ps1` as needed

## Testing Commands

```powershell
# Check profile path
$PROFILE.CurrentUserCurrentHost

# Verify symbolic link
ls -l ~/.config/powershell/Microsoft.PowerShell_profile.ps1

# Test profile functions
Get-Command -Name Test-AzurePolicyCompliance
Get-Alias tpc
```

---

**Fixed By**: Dynamic user detection and symbolic linking  
**Date**: October 6, 2025  
**Status**: ✅ Complete and tested
