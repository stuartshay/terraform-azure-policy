# Dev Container Quick Reference

This guide provides quick commands and troubleshooting tips for working with the Azure Policy Development Container.

## 🚀 Quick Commands

### Container Management

```bash
# Open in container (VS Code Command Palette)
Dev Containers: Reopen in Container

# Rebuild container
Dev Containers: Rebuild Container

# Rebuild without cache (clean build)
Dev Containers: Rebuild Without Cache

# Open in new window
Dev Containers: Clone Repository in Container Volume
```

### Azure Authentication

```bash
# Login with device code (works in Codespaces)
az login --use-device-code

# Login with browser (local only)
az login

# Set subscription
az account set --subscription "<subscription-id>"

# Show current account
az account show

# List subscriptions
az account list --output table
```

### PowerShell

```bash
# Start PowerShell
pwsh

# List installed modules
Get-Module -ListAvailable

# Import a module
Import-Module Az.Accounts

# Update all modules
Update-Module -Force

# Check PowerShell version
$PSVersionTable
```

### Testing

```powershell
# Run all tests
./scripts/Invoke-PolicyTests.ps1 -TestPath "tests"

# Run specific category
./scripts/Invoke-PolicyTests.ps1 -TestPath "tests/storage"

# Run with coverage
./scripts/Invoke-PolicyTests-WithCoverage.ps1 -TestPath "tests" -CodeCoverage $true

# Run quick unit tests (no Azure)
pre-commit run pester-tests-unit --all-files
```

### Pre-commit Hooks

```bash
# Install hooks
pre-commit install --install-hooks

# Run all hooks
pre-commit run --all-files

# Run specific hook
pre-commit run terraform-fmt --all-files
pre-commit run pester-tests-unit --all-files

# Update hooks
pre-commit autoupdate

# Skip hooks for a commit
git commit --no-verify -m "message"
```

### Terraform

```bash
# Initialize
cd policies
terraform init

# Format
terraform fmt -recursive

# Validate
terraform validate

# Plan
terraform plan

# Apply
terraform apply -auto-approve
```

### Policy Management

```powershell
# Validate policy definitions
./scripts/Validate-PolicyDefinitions.ps1 -PolicyPath "policies"

# Deploy (what-if)
./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath "policies" -WhatIf

# Deploy to Azure
./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath "policies"

# Test compliance
./scripts/Test-PolicyCompliance.ps1 -OutputFormat Table

# Generate reports
./scripts/Generate-PolicyReports.ps1 -ResourceGroup "rg-azure-policy-testing" -Format All
```

## 🔧 Troubleshooting

### Container Won't Build

```bash
# Clear Docker cache
docker system prune -a

# Rebuild without cache
# Command Palette: Dev Containers: Rebuild Without Cache

# Check Docker logs
docker logs azure-policy-devcontainer

# Remove old containers
docker container prune
```

### PowerShell Module Issues

```powershell
# Clear module cache
$env:PSModulePath -split [System.IO.Path]::PathSeparator |
    Where-Object { $_ -like "*home/vscode*" } |
    ForEach-Object { Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue }

# Reinstall modules
./scripts/Install-Requirements.ps1 -IncludeOptional

# Check specific module
Get-Module -ListAvailable -Name Pester

# Force import with version
Import-Module Pester -RequiredVersion 5.4.0 -Force
```

### Azure CLI Authentication

```bash
# Clear cached credentials
rm -rf ~/.azure

# Re-login with device code
az login --use-device-code

# Check token expiration
az account get-access-token --query expiresOn -o tsv

# Refresh token
az account get-access-token --query accessToken -o tsv > /dev/null
```

### Terraform Issues

```bash
# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Reinitialize
terraform init -upgrade

# Check provider configuration
terraform providers

# Validate configuration
terraform validate

# Show detailed plan
terraform plan -out=tfplan
terraform show tfplan
```

### Git Issues

```bash
# Fix line endings
git config --global core.autocrlf input

# Reset permissions
chmod 600 ~/.ssh/*
chmod 700 ~/.ssh

# Test GitHub connection
ssh -T git@github.com

# Configure safe directory
git config --global --add safe.directory /workspaces/terraform-azure-policy
```

### File Permission Issues

```bash
# Fix script permissions
find . -type f -name "*.sh" -exec chmod +x {} \;

# Fix SSH permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_* 2>/dev/null || true
chmod 644 ~/.ssh/*.pub 2>/dev/null || true
```

### Performance Issues

```bash
# Check container resources
docker stats azure-policy-devcontainer

# Clear caches
rm -rf ~/.cache/*
rm -rf /tmp/*

# Restart container
# Command Palette: Dev Containers: Rebuild Container
```

## 📦 Environment Variables

### Required for Deployment

```bash
# Azure authentication
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"

# Optional: Service Principal
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
```

### Add to .env file (local only)

```bash
# Create .env file
cat > .env << EOF
ARM_SUBSCRIPTION_ID=your-subscription-id
ARM_TENANT_ID=your-tenant-id
ARM_MANAGEMENT_GROUP_ID=your-management-group-id
EOF

# Load in PowerShell
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}
```

## 🔍 Diagnostics

### System Information

```bash
# Container info
cat /etc/os-release
uname -a

# Tool versions
pwsh -Version
terraform version
az version
python3 --version
git --version

# Disk space
df -h

# Memory usage
free -h
```

### Module Diagnostics

```powershell
# PowerShell diagnostic
Get-PSRepository
Get-PackageProvider
$PSVersionTable

# Module paths
$env:PSModulePath -split [System.IO.Path]::PathSeparator

# Installed modules with versions
Get-InstalledModule | Select-Object Name, Version | Sort-Object Name
```

### Network Diagnostics

```bash
# Test Azure connectivity
curl -s https://management.azure.com

# Test GitHub connectivity
curl -s https://api.github.com

# DNS resolution
nslookup github.com
nslookup management.azure.com

# Network interfaces
ip addr show
```

## 🚀 GitHub Codespaces Specific

### Codespace Commands

```bash
# List codespaces
gh codespace list

# Connect to codespace
gh codespace code

# SSH to codespace
gh codespace ssh

# Stop codespace
gh codespace stop

# Delete codespace
gh codespace delete
```

### Port Forwarding

```bash
# Forward port from codespace
gh codespace ports forward 8080:80

# List forwarded ports
gh codespace ports
```

### Secrets Management

```bash
# List codespace secrets
gh codespace secret list

# Set a secret
gh codespace secret set SECRET_NAME

# Remove a secret
gh codespace secret remove SECRET_NAME
```

## 📝 Tips & Best Practices

### Performance

1. **Use volumes for cache**: Module cache persists across rebuilds
2. **Close unused extensions**: Disable extensions you don't need
3. **Limit concurrent operations**: Don't run multiple Terraform operations
4. **Use local cache**: Azure CLI and Terraform cache locally

### Security

1. **Never commit credentials**: Use environment variables or Azure CLI
2. **Rotate secrets regularly**: Update credentials periodically
3. **Use service principals**: For CI/CD, not personal accounts
4. **Review permissions**: Follow least-privilege principle

### Workflow

1. **Pre-commit first**: Always run pre-commit before pushing
2. **Test locally**: Run unit tests before integration tests
3. **Small commits**: Commit frequently with clear messages
4. **Use branches**: Never commit directly to master

### Cost Optimization (Codespaces)

1. **Stop when idle**: Codespaces auto-stop after 30 minutes
2. **Delete unused**: Remove codespaces you're not using
3. **Use smaller machine**: Default 2-core is usually sufficient
4. **Pre-build images**: Configure pre-builds for faster starts

## 🆘 Getting Help

### Documentation Links

- [Dev Container Docs](https://code.visualstudio.com/docs/devcontainers/containers)
- [GitHub Codespaces Docs](https://docs.github.com/en/codespaces)
- [Azure CLI Docs](https://learn.microsoft.com/en-us/cli/azure/)
- [PowerShell Docs](https://learn.microsoft.com/en-us/powershell/)
- [Terraform Docs](https://www.terraform.io/docs)

### Support Channels

- Project Issues: GitHub Issues
- Azure Support: Azure Portal
- Community: Stack Overflow

### Debugging Commands

```bash
# Enable verbose output
export TF_LOG=DEBUG
export AZ_CLI_DEBUG=1

# PowerShell verbose
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

# View logs
tail -f /tmp/*.log
journalctl -f
```

## 🎯 Common Workflows

### First Time Setup

```bash
1. Open in container
2. Wait for automatic setup
3. az login --use-device-code
4. az account set --subscription "<sub-id>"
5. pre-commit install
6. ./scripts/Invoke-PolicyTests.ps1 -TestPath "tests/storage"
```

### Daily Development

```bash
1. Pull latest changes: git pull
2. Make changes to policies
3. Run tests: ./scripts/Invoke-PolicyTests.ps1
4. Commit: git commit (pre-commit runs automatically)
5. Push: git push
```

### Deploying Changes

```bash
1. Validate: terraform validate
2. What-if: ./scripts/Deploy-PolicyDefinitions.ps1 -WhatIf
3. Deploy: ./scripts/Deploy-PolicyDefinitions.ps1
4. Verify: ./scripts/Test-PolicyCompliance.ps1
5. Report: ./scripts/Generate-PolicyReports.ps1
```

---

**Last Updated**: October 2025
**Maintainer**: Azure Policy Team
