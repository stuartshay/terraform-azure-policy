# Azure Policy Development Container

This devcontainer provides a complete development environment for the Azure Policy Terraform project with all necessary tools and dependencies pre-installed.

## � Configuration Files

This project includes multiple devcontainer configurations for different scenarios:

- **`devcontainer.json`** - CI/CD optimized configuration (used by GitHub Actions)
  - Minimal mounts for GitHub Actions compatibility
  - Optimized for automated testing
  - No host directory dependencies

- **`devcontainer.local.json`** - Local development configuration
  - Includes Azure credentials and SSH key mounts
  - Full IDE integration
  - For use with VS Code locally or Codespaces

- **`devcontainer.codespaces.json`** - GitHub Codespaces specific
  - Resource requirements and port forwarding
  - Secret management for Azure credentials
  - Codespaces-specific optimizations

### Using the Local Configuration

To use the local development configuration with mounts:

1. Rename `devcontainer.json` to `devcontainer.ci.json`
2. Rename `devcontainer.local.json` to `devcontainer.json`
3. Reopen in container

Or use the Dev Containers CLI:

```bash
devcontainer up --workspace-folder . --config .devcontainer/devcontainer.local.json
```

## �🚀 Features

### Tools & Dependencies

- **PowerShell Core 7.x** - Primary scripting language
- **Terraform 1.13.1** - Infrastructure as Code
- **Azure CLI** - Azure management and authentication
- **Python 3.11** - For pre-commit and tooling
- **Git & GitHub CLI** - Version control and GitHub integration
- **Node.js LTS** - For npm-based tools

### PowerShell Modules (Auto-installed)

**Required:**

- Az.Accounts (2.12.1)
- Az.Resources (6.6.0)
- Az.PolicyInsights (1.6.1)
- PSScriptAnalyzer (1.21.0)
- Pester (5.4.0)
- PowerShellGet (2.2.5)
- PackageManagement (1.4.8.1)

**Optional:**

- Az.ResourceGraph (0.13.0)
- ImportExcel (7.8.4)
- PSWriteColor (1.0.1)

### Development Tools

- **TFLint** - Terraform linting
- **actionlint** - GitHub Actions validation
- **markdownlint** - Markdown formatting
- **commitizen** - Commit message formatting
- **detect-secrets** - Secret scanning
- **yamllint** - YAML validation
- **shellcheck** - Shell script analysis
- **jq** - JSON processing

### VS Code Extensions (Auto-installed)

- PowerShell
- Terraform
- Azure Account & Resources
- YAML, JSON, XML support
- Git integration (GitLens, GitHub PR)
- Markdown tools
- Code spell checker
- Shell script support

## 📦 Quick Start

### Using VS Code (Local Development)

1. **Prerequisites:**
   - Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Install [VS Code](https://code.visualstudio.com/)
   - Install [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

2. **Open in Container:**

   ```bash
   # Open VS Code
   code .

   # Use Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
   # Select: "Dev Containers: Reopen in Container"
   ```

3. **Wait for Setup:**
   - First build takes 5-10 minutes
   - Subsequent starts are much faster
   - Watch the terminal for setup progress

4. **Verify Installation:**

   ```powershell
   # Check PowerShell modules
   Get-Module -ListAvailable

   # Check Terraform
   terraform version

   # Check Azure CLI
   az version
   ```

### Using GitHub Codespaces

1. **Create Codespace:**
   - Navigate to the repository on GitHub
   - Click the green "Code" button
   - Select "Codespaces" tab
   - Click "Create codespace on develop"

2. **Automatic Setup:**
   - Environment builds automatically
   - All tools pre-installed
   - Ready to code in browser or VS Code

3. **Connect via VS Code Desktop:**

   ```bash
   # From Codespaces page, click "Open in VS Code Desktop"
   # Or use: gh codespace code
   ```

## 🔧 Configuration

### Azure Authentication

#### Option 1: Azure CLI (Recommended for Codespaces)

```bash
# Login via device code
az login --use-device-code

# Set subscription
az account set --subscription "<subscription-id>"

# Verify
az account show
```

#### Option 2: Service Principal

```bash
# Set environment variables in .env file
ARM_CLIENT_ID="<client-id>"
ARM_CLIENT_SECRET="<client-secret>"
ARM_SUBSCRIPTION_ID="<subscription-id>"
ARM_TENANT_ID="<tenant-id>"

# Login with service principal
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
```

### Terraform Backend Configuration

```bash
# Copy backend configuration example
cp config/backend/sandbox.tfbackend.example config/backend/sandbox.tfbackend

# Edit with your values
# Then initialize Terraform
cd policies
terraform init -backend-config=../config/backend/sandbox.tfbackend
```

### Git Configuration

```bash
# Configure Git user
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Configure SSH (if needed)
ssh-keygen -t ed25519 -C "your.email@example.com"
cat ~/.ssh/id_ed25519.pub  # Add to GitHub
```

## 🧪 Development Workflow

### 1. Install Pre-commit Hooks

```powershell
# Setup hooks
./scripts/Setup-PreCommit.ps1

# Or manually
pre-commit install --install-hooks
```

### 2. Run Tests

```powershell
# Quick validation (no Azure auth required)
pre-commit run pester-tests-quick --all-files

# Run specific test suite
./scripts/Invoke-PolicyTests.ps1 -TestPath "tests/storage"

# Run all tests
./scripts/Invoke-PolicyTests.ps1 -TestPath "tests"

# Run with coverage
./scripts/Invoke-PolicyTests-WithCoverage.ps1 -TestPath "tests" -CodeCoverage $true
```

### 3. Validate Changes

```bash
# Pre-commit checks (runs automatically on commit)
pre-commit run --all-files

# Terraform validation
terraform fmt -recursive
terraform validate

# PowerShell analysis
Invoke-ScriptAnalyzer -Path . -Recurse
```

### 4. Deploy Policies

```powershell
# What-if deployment
./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath "policies" -WhatIf

# Deploy to Azure
./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath "policies"
```

## 📁 Workspace Mounts

The devcontainer automatically mounts:

- **Azure credentials**: `~/.azure` → Container `~/.azure`
  - Persists Azure CLI authentication
  - Works across container rebuilds

- **SSH keys**: `~/.ssh` → Container `~/.ssh-localhost` (read-only)
  - Automatically copied during setup
  - Used for Git operations

## 🛠️ Troubleshooting

### PowerShell Module Issues

```powershell
# Reinstall modules
./scripts/Install-Requirements.ps1 -IncludeOptional

# Check module paths
$env:PSModulePath -split [System.IO.Path]::PathSeparator

# Import manually
Import-Module Pester -RequiredVersion 5.4.0
```

### Terraform Issues

```bash
# Clear cache and reinitialize
rm -rf .terraform .terraform.lock.hcl
terraform init

# Verify provider installation
terraform providers
```

### Azure CLI Issues

```bash
# Clear cached credentials
rm -rf ~/.azure

# Re-authenticate
az login --use-device-code

# Check account
az account show
```

### Container Rebuild

```bash
# Force rebuild container
# Command Palette: "Dev Containers: Rebuild Container"

# Or rebuild without cache
# Command Palette: "Dev Containers: Rebuild Without Cache"
```

## 🔄 Updating the Container

### Update Tools

```bash
# Update pre-commit hooks
pre-commit autoupdate

# Update PowerShell modules
Update-Module -Force

# Update Azure CLI
az upgrade
```

### Rebuild Container Image

```bash
# Rebuild with latest features
# Command Palette: "Dev Containers: Rebuild Container"
```

## 📚 Additional Resources

- [VS Code Dev Containers Documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)
- [Project Documentation](../docs/README.md)
- [Pre-commit Guide](../docs/PreCommit-Guide.md)
- [Testing Guide](../tests/README.md)

## 🤝 Contributing

When making changes to the devcontainer:

1. Test locally first with "Rebuild Container"
2. Update this README with any new requirements
3. Ensure all team members can build successfully
4. Document any new environment variables or secrets

## 💡 Tips

- Use `pwsh` as default terminal (already configured)
- Install additional VS Code extensions as needed
- Customize VS Code settings in `.vscode/settings.json`
- Use environment variables for sensitive values
- Leverage GitHub Codespaces for quick collaboration

## 🎯 Next Steps

1. **Authenticate**: `az login --use-device-code`
2. **Run tests**: `./scripts/Invoke-PolicyTests.ps1 -TestPath "tests/storage"`
3. **Pre-commit**: `pre-commit run --all-files`
4. **Deploy**: `./scripts/Deploy-PolicyDefinitions.ps1 -WhatIf`

Happy coding! 🚀
