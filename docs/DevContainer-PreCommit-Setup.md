# DevContainer Automated Setup Guide

## Overview

The devcontainer automatically installs PowerShell modules and configures pre-commit hooks when the container is built. This ensures a consistent development environment with all required tools and code quality checks.

The setup uses centralized PowerShell scripts for all configuration:

- **`scripts/Install-Requirements.ps1`** - Handles all PowerShell module installation
- **`scripts/Setup-PreCommit.ps1`** - Handles all pre-commit hook configuration

This approach provides consistent setup whether you're in a devcontainer or running locally, with single source of truth for all requirements.

## What's Included

### Automatic Installation

The `.devcontainer/setup.sh` script performs the following:

1. **Installs Python packages:**
   - `pre-commit` - Git hook framework
   - `commitizen` - Conventional commit message formatting
   - `detect-secrets` - Secret scanning

2. **Calls `scripts/Install-Requirements.ps1`:**
   - Reads module requirements from `requirements.psd1`
   - Installs all required PowerShell modules (Pester, PSScriptAnalyzer, Az modules)
   - Installs optional modules (Az.ResourceGraph, ImportExcel, PSWriteColor)
   - Verifies installation and provides detailed status
   - Sets PSGallery as trusted repository

3. **Calls `scripts/Setup-PreCommit.ps1`:**
   - Verifies pre-commit installation
   - Installs git hooks (pre-commit and commit-msg)
   - Checks for optional dependencies (PSScriptAnalyzer, Pester, Terraform)
   - Creates initial secrets baseline if needed
   - Provides detailed status and troubleshooting info

4. **Fallback configuration:**
   - If PowerShell is unavailable, setup gracefully degrades
   - Critical functionality still available

### Benefits of Centralized Scripts

- **Single source of truth**: All setup logic in PowerShell scripts, not duplicated in bash
- **Consistent setup**: Same process for devcontainer and local development
- **Better diagnostics**: PowerShell scripts provide detailed output and checks
- **Easy maintenance**: Update `requirements.psd1` or scripts once, applies everywhere
- **Manual control**: Users can run scripts directly anytime:
  - `./scripts/Install-Requirements.ps1 -IncludeOptional`
  - `./scripts/Setup-PreCommit.ps1`

## Pre-Commit Hooks Configuration

The `.pre-commit-config.yaml` file includes comprehensive checks:

### File Quality Checks

- Trailing whitespace removal
- End-of-file fixer
- Mixed line ending normalization
- Large file detection
- Merge conflict detection
- Private key detection

### PowerShell Checks

- Syntax validation
- Whitespace cleanup
- PSScriptAnalyzer (critical issues only)
- Unit test execution

### Terraform Checks

- `terraform fmt` - Formatting
- `terraform validate` - Validation
- `terraform docs` - Automatic README documentation
- `terraform tflint` - Linting

### Markdown & YAML

- Markdownlint - Markdown formatting
- Yamllint - YAML validation

### Security

- `detect-secrets` - Scan for hardcoded secrets
- Azure Policy JSON validation

### GitHub Actions

- `actionlint` - GitHub workflow validation

### Commit Messages

- `commitizen` - Enforces conventional commit format

## Usage

### Automatic (Recommended)

Hooks run automatically on every commit:

```bash
git add .
git commit -m "feat: add new feature"
# Pre-commit hooks run automatically
```

### Manual Execution

Run all hooks on all files:

```bash
pre-commit run --all-files
```

Run specific hook:

```bash
pre-commit run trailing-whitespace --all-files
pre-commit run powershell-syntax-check --all-files
pre-commit run pester-tests-unit --all-files
```

### Skip Hooks (Use Sparingly)

Skip all hooks for a commit:

```bash
git commit -m "fix: urgent fix" --no-verify
```

Skip specific hooks:

```bash
SKIP=pester-tests-unit,terraform_tflint git commit -m "fix: quick fix"
```

## Manual Setup

### Install PowerShell Modules

You can manually install or update PowerShell modules anytime using the centralized script:

#### Install Required Modules Only

```powershell
./scripts/Install-Requirements.ps1
```

#### Install Required + Optional Modules

```powershell
./scripts/Install-Requirements.ps1 -IncludeOptional
```

This installs:

- **Required:** Pester, PSScriptAnalyzer, Az.Accounts, Az.Resources, Az.PolicyInsights, Az.Storage
- **Optional:** Az.ResourceGraph, ImportExcel, PSWriteColor

#### Force Reinstall/Update Modules

```powershell
./scripts/Install-Requirements.ps1 -IncludeOptional -Force
```

#### Install to Current User Scope

```powershell
./scripts/Install-Requirements.ps1 -Scope CurrentUser
```

#### Module Definitions

All module requirements are defined in `requirements.psd1`:

- Module names and version numbers
- Descriptions and dependencies
- PowerShell version requirements
- Single file to update when versions change

### Configure Pre-Commit Hooks

You can manually run the setup script anytime to reconfigure or verify pre-commit hooks:

#### Full Setup (Install pre-commit and configure)

```powershell
./scripts/Setup-PreCommit.ps1
```

This will:

- Check Python installation
- Install/upgrade pre-commit via pip
- Install git hooks
- Check optional dependencies (PSScriptAnalyzer, Pester, Terraform)
- Run a full test of all hooks
- Create secrets baseline if needed

#### Configure Only (Skip Installation)

If pre-commit is already installed:

```powershell
./scripts/Setup-PreCommit.ps1 -SkipInstall
```

#### Quick Configuration (No Testing)

For fast setup without running all hooks (used by devcontainer):

```powershell
./scripts/Setup-PreCommit.ps1 -SkipInstall -SkipTest
```

#### Force Reinstall Hooks

To overwrite existing hooks:

```powershell
./scripts/Setup-PreCommit.ps1 -Force
```

### Complete Manual Setup

Run both scripts for full setup:

```bash
# Install all PowerShell modules
pwsh -ExecutionPolicy Bypass -File ./scripts/Install-Requirements.ps1 -IncludeOptional

# Setup pre-commit hooks
pwsh -ExecutionPolicy Bypass -File ./scripts/Setup-PreCommit.ps1
```

### Script Features

The centralized PowerShell scripts (`Install-Requirements.ps1` and `Setup-PreCommit.ps1`) provide:

- ✅ **Color-coded output:** Clear success, warning, error messages
- ✅ **Environment validation:** Checks PowerShell version, Python, pip, git
- ✅ **Smart installation:** Only installs missing modules, skips already installed
- ✅ **Version verification:** Confirms installed versions match requirements
- ✅ **Dependency checks:** Validates PSScriptAnalyzer, Pester, Terraform availability
- ✅ **Secrets baseline:** Automatic `.secrets.baseline` creation if needed
- ✅ **Hook testing:** Full validation of all hooks (when not skipped)
- ✅ **Comprehensive summary:** Shows what was installed, what was skipped, next steps
- ✅ **Error handling:** Detailed troubleshooting guidance on failures
- ✅ **Single source of truth:** Both devcontainer and manual setup use same scripts

## Verification

After container rebuild or manual setup, verify everything is installed:

### Check PowerShell Modules

```powershell
# List installed Az modules
Get-Module -ListAvailable Az.*

# Check specific required modules
Get-Module -ListAvailable Pester, PSScriptAnalyzer, Az.Accounts

# Verify module versions
Get-InstalledModule Az.Accounts, Az.Resources, Az.PolicyInsights
```

### Check Pre-Commit

```bash
# Check pre-commit version
pre-commit --version

# Check installed hooks
ls -la .git/hooks/

# Verify hook configuration
pre-commit run --all-files --verbose
```

## Troubleshooting

### PowerShell Module Issues

If modules are missing or old versions:

```powershell
# Reinstall all modules with force
./scripts/Install-Requirements.ps1 -IncludeOptional -Force

# Check PSGallery trust
Get-PSRepository

# Manually trust PSGallery if needed
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
```

### Pre-commit not found

If pre-commit isn't in PATH after container rebuild:

```bash
pip3 install --user pre-commit
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg
```

### Hooks not running

Reinstall hooks:

```bash
pre-commit uninstall
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg
```

### Hook failures

View detailed error messages:

```bash
pre-commit run --all-files --verbose
```

Update hook environments:

```bash
pre-commit clean
pre-commit install --install-hooks
```

### PowerShell hooks failing

Ensure modules are installed:

```bash
pwsh -Command "Get-Module -ListAvailable Pester, PSScriptAnalyzer, Az.Storage"
```

If missing, run:

```bash
./scripts/Install-Requirements.ps1
```

## DevContainer Rebuild

When you rebuild the container, everything installs automatically:

1. **Container starts** → `.devcontainer/setup.sh` runs
2. **Python packages installed** → pre-commit, commitizen, detect-secrets
3. **PowerShell modules installed** → Pester, PSScriptAnalyzer, Az modules
4. **Git hooks installed** → pre-commit and commit-msg hooks
5. **Hook environments initialized** → All hook dependencies cached

## CI/CD Integration

The pre-commit configuration includes CI-specific settings:

```yaml
ci:
  skip: [
    powershell-syntax-check,
    powershell-script-analyzer,
    pester-tests-unit,
    terraform_tflint,
  ]
```

These resource-intensive hooks are skipped in automated CI environments.

## Hook Customization

To modify hooks, edit `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
```

After changes, update hooks:

```bash
pre-commit install --install-hooks
```

## Performance Tips

### Fast Commits

Most hooks are lightweight and run in seconds. Heavy hooks (Terraform, Pester tests) are skipped in CI.

### Parallel Execution

Pre-commit runs hooks in parallel when possible, speeding up execution.

### Cached Environments

Hook dependencies are cached in `.pre-commit-cache/`, so subsequent runs are faster.

## Best Practices

1. **Commit Often** - Smaller commits pass hooks faster
2. **Run Manually** - Test with `pre-commit run --all-files` before committing
3. **Keep Updated** - Run `pre-commit autoupdate` periodically
4. **Skip Rarely** - Only use `--no-verify` for urgent fixes
5. **Fix Issues** - Don't skip hooks to bypass quality checks

## Additional Resources

- [Pre-commit Documentation](https://pre-commit.com/)
- [Commitizen Guide](https://commitizen-tools.github.io/commitizen/)
- [Project Pre-Commit Guide](PreCommit-Guide.md)
- [DevContainer Setup](../DEVCONTAINER-SETUP.md)

## Summary

✅ **Automatic Installation** - Everything installs when container builds
✅ **Git Hooks** - pre-commit and commit-msg hooks configured
✅ **Quality Checks** - Comprehensive code quality validation
✅ **Security Scanning** - Detect secrets and vulnerabilities
✅ **CI/CD Ready** - Optimized for automated environments

**Pre-commit ensures code quality at every commit!** 🚀
