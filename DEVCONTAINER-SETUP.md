# Dev Container Setup Summary

## ✅ What Was Created

The following files have been set up for a complete development container experience:

### Core Configuration Files

1. **`.devcontainer/devcontainer.json`**
   - Main configuration for VS Code Dev Containers
   - Includes PowerShell, Terraform, Azure CLI, Python, Git, and Node.js
   - Pre-configured VS Code extensions
   - Azure credentials mounting from host
   - Optimized settings for PowerShell and Terraform development

2. **`.devcontainer/setup.sh`**
   - Automated setup script (executable)
   - Installs system packages and tools
   - Configures PowerShell modules (Az.*, Pester, PSScriptAnalyzer)
   - Sets up pre-commit hooks
   - Initializes Terraform
   - Installs actionlint, markdownlint, commitizen, and other tools

3. **`.devcontainer/devcontainer.codespaces.json`**
   - GitHub Codespaces-specific configuration
   - Resource requirements (2 CPU, 8GB RAM, 32GB storage)
   - Secret management for Azure credentials
   - Port forwarding configuration

4. **`.devcontainer/.env.example`**
   - Template for environment variables
   - Azure subscription and tenant configuration
   - Optional service principal settings

5. **`.devcontainer/README.md`**
   - Complete documentation (7.5KB)
   - Quick start guides for VS Code and Codespaces
   - Azure authentication options
   - Development workflow instructions
   - Troubleshooting section
   - Configuration examples

### Documentation

1. **`docs/DevContainer-Quick-Reference.md`**
   - Quick reference guide for common tasks
   - Troubleshooting commands
   - Common workflows
   - Diagnostics and debugging
   - GitHub Codespaces specific commands

### CI/CD Integration

1. **`.github/workflows/devcontainer.yml`**
   - Automated testing of devcontainer build
   - Validates setup scripts
   - Checks documentation
   - Runs on changes to devcontainer files

### Updated Files

1. **`.gitignore`**
   - Added devcontainer-specific ignores
   - `.devcontainer/.tmp/`, `build.log`, `.env`

1. **`.vscode/settings.json`**
   - Updated PowerShell version to `pwsh` for Linux compatibility
   - Configured terminal profiles for devcontainer

1. **`requirements.psd1`**
    - Added Az.Storage module documentation
    - Updated for integration tests

1. **`.secrets.baseline`**

## 🚀 How to Use

### Local Development (VS Code)

```bash
# 1. Open project in VS Code
code /home/vagrant/git/terraform-azure-policy

# 2. Reopen in container (Command Palette)
# Press: Ctrl+Shift+P (Linux) or Cmd+Shift+P (Mac)
# Select: "Dev Containers: Reopen in Container"

# 3. Wait for setup (5-10 minutes first time)
# Subsequent starts are much faster

# 4. Authenticate with Azure
az login --use-device-code
az account set --subscription "<your-subscription-id>"

# 5. Start developing!
```

### GitHub Codespaces

```bash
# Option 1: From GitHub UI
# 1. Navigate to repository
# 2. Click "Code" button
# 3. Select "Codespaces" tab
# 4. Click "Create codespace on develop"

# Option 2: Using GitHub CLI
gh codespace create --repo stuartshay/terraform-azure-policy --branch develop
gh codespace code  # Opens in VS Code Desktop

# Option 3: From VS Code
# Command Palette → "Codespaces: Create New Codespace"
```

## 🎯 What's Included

### Tools (All Auto-Installed)

- ✅ PowerShell Core 7.x
- ✅ Terraform 1.13.1
- ✅ Azure CLI (latest)
- ✅ Python 3.11
- ✅ Git (latest)
- ✅ GitHub CLI
- ✅ Node.js LTS
- ✅ TFLint
- ✅ actionlint
- ✅ markdownlint
- ✅ commitizen
- ✅ detect-secrets
- ✅ yamllint
- ✅ shellcheck
- ✅ jq

### PowerShell Modules (All Auto-Installed)

**Required:**

- Az.Accounts 2.12.1
- Az.Resources 6.6.0
- Az.PolicyInsights 1.6.1
- PSScriptAnalyzer 1.21.0
- Pester 5.4.0
- PowerShellGet 2.2.5
- PackageManagement 1.4.8.1

**Optional:**

- Az.ResourceGraph 0.13.0
- ImportExcel 7.8.4
- PSWriteColor 1.0.1

### VS Code Extensions (All Auto-Installed)

- PowerShell
- Terraform (HashiCorp)
- Azure Account
- Azure Resources
- YAML, JSON, XML support
- GitHub Pull Requests
- GitLens
- Markdown tools
- Code Spell Checker
- ShellCheck

## 🔧 Features

### 1. Credential Persistence

Your Azure credentials are automatically mounted from your host machine:

- `~/.azure` from host → `~/.azure` in container
- Credentials persist across container rebuilds
- No need to re-authenticate every time

### 2. SSH Key Mounting

SSH keys are copied from host (read-only):

- `~/.ssh` from host → `~/.ssh` in container
- Automatically configured with correct permissions
- Works with Git operations

### 3. Pre-configured Settings

- PowerShell as default terminal
- Script Analyzer enabled
- Terraform validation on save
- Consistent formatting rules
- 120-character ruler

### 4. Pre-commit Hooks

Automatically installed and ready:

- PowerShell syntax check
- Terraform validation
- Markdown linting
- YAML validation
- Secret scanning
- Pester unit tests

## 📋 Next Steps

### 1. First Time Setup

```bash
# After container is built:
az login --use-device-code
az account set --subscription "<subscription-id>"
pre-commit run --all-files
```

### 2. Run Tests

```powershell
# Quick validation (no Azure required)
pre-commit run pester-tests-unit --all-files

# Integration tests (requires Azure auth)
./scripts/Invoke-PolicyTests.ps1 -TestPath "tests/storage"
```

### 3. Deploy Policies

```powershell
# What-if mode
./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath "policies" -WhatIf

# Actual deployment
./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath "policies"
```

## 🐛 Troubleshooting

### Container Won't Build

```bash
# Clear Docker cache
docker system prune -a

# Rebuild without cache
# Command Palette: "Dev Containers: Rebuild Without Cache"
```

### PowerShell Modules Missing

```powershell
# Reinstall modules
./scripts/Install-Requirements.ps1 -IncludeOptional

# Check installation
Get-Module -ListAvailable
```

### Azure Auth Issues

```bash
# Clear credentials
rm -rf ~/.azure

# Re-authenticate
az login --use-device-code
```

## 📚 Documentation Links

- **[.devcontainer/README.md](.devcontainer/README.md)** - Complete setup guide
- **[docs/DevContainer-Quick-Reference.md](docs/DevContainer-Quick-Reference.md)** - Quick commands
- **[VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)**
- **[GitHub Codespaces Docs](https://docs.github.com/en/codespaces)**

## ✨ Benefits

### For Local Development

- ✅ Consistent environment for all developers
- ✅ No need to install tools manually
- ✅ Works on Windows, Mac, and Linux
- ✅ Isolated from host system
- ✅ Easy to reset/rebuild

### For GitHub Codespaces

- ✅ Instant development environment
- ✅ No local setup required
- ✅ Works in browser or VS Code
- ✅ Ideal for collaboration
- ✅ Pay only for what you use

### For CI/CD

- ✅ Automated devcontainer testing
- ✅ Same environment in CI as development
- ✅ Fast builds with caching
- ✅ Validated on every change

## 🎉 Success Criteria

After setup, you should be able to:

1. ✅ Open terminal and see PowerShell prompt
2. ✅ Run `terraform version` → See v1.13.1
3. ✅ Run `az version` → See Azure CLI info
4. ✅ Run `Get-Module -ListAvailable` → See all modules
5. ✅ Run `pre-commit run --all-files` → Pass all checks
6. ✅ Run tests successfully with Azure auth

## 📝 Notes

- First build: 5-10 minutes (downloads images, installs tools)
- Subsequent builds: 1-2 minutes (uses cache)
- Container size: ~3-4 GB
- Recommended: 8 GB RAM, 32 GB storage
- Works offline (after initial build) except Azure operations

---

**Created**: October 2025
**For**: terraform-azure-policy project
**Author**: GitHub Copilot
**Status**: ✅ Ready to use
