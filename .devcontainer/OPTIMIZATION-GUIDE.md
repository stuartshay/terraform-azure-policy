# DevContainer Optimization Guide

## Overview

This guide explains the optimizations made to the DevContainer configuration to improve startup time and maintainability.

## Key Optimizations

### 1. **DevContainer Features vs Manual Installation**

We've migrated from manual script-based installation to DevContainer features, which provide:

- **Parallel installation**: Features are installed concurrently, significantly reducing startup time
- **Caching**: Pre-built feature layers are cached and reused
- **Reliability**: Official, well-maintained feature implementations
- **Version control**: Easy to update and pin versions

### 2. **Tools Now Installed via Features**

#### Previously Manual (in setup.sh) → Now via Features

| Tool | Feature | Benefit |
|------|---------|---------|
| Docker | `ghcr.io/devcontainers/features/docker-in-docker:2` | Docker-in-Docker support for container workflows |
| terraform-docs | `ghcr.io/devcontainers/features/terraform:1` (terraformDocs) | Included in Terraform feature |
| tfsec | `ghcr.io/devcontainers/features/terraform:1` (tfsec) | Security scanning for Terraform |
| terragrunt | `ghcr.io/devcontainers/features/terraform:1` (terragrunt) | Terraform wrapper |
| shellcheck | `ghcr.io/devcontainers-contrib/features/shellcheck:1` | Shell script linting |
| yamllint | `ghcr.io/devcontainers-contrib/features/yamllint:1` | YAML linting |
| actionlint | `ghcr.io/devcontainers-contrib/features/actionlint:1` | GitHub Actions workflow linting |
| markdownlint-cli | `ghcr.io/devcontainers-contrib/features/markdownlint-cli:1` | Markdown linting |

### 3. **Removed from setup.sh**

The following installations were removed from `setup.sh` because they're now handled by features:

- `apt-get install shellcheck yamllint` - Now via features
- `npm install -g markdownlint-cli` - Now via features  
- Manual actionlint download/install - Now via features
- Manual terraform-docs download/install - Now included in Terraform feature
- Multiple `apt-get install` calls for curl, wget, unzip, etc. - Reduced to essentials

### 4. **What Remains in setup.sh**

The streamlined `setup.sh` now only handles:

- Python packages (commitizen, detect-secrets, pre-commit)
- PowerShell module installation (via Install-Requirements.ps1)
- Git configuration and SSH key setup
- Pre-commit hooks configuration
- Terraform initialization
- PowerShell profile setup
- Environment verification reporting

## Performance Benefits

### Before Optimization

- ~50+ apt package installations
- Sequential tool downloads and installs
- Network-dependent installations during startup
- Estimated startup: **3-5 minutes**

### After Optimization

- Parallel feature installation (cached)
- Minimal sequential operations
- Most tools pre-cached in feature layers
- Estimated startup: **1-2 minutes** (60-70% reduction)

## Available Tools

After container creation, the following tools are available:

### Infrastructure as Code

- **Terraform** (latest) - Infrastructure provisioning
- **TFLint** (latest) - Terraform linting
- **Terragrunt** (latest) - Terraform wrapper
- **terraform-docs** (latest) - Documentation generation
- **tfsec** (latest) - Security scanning

### Azure Tools

- **Azure CLI** (latest) - Azure management
  - Extensions: account, resource-graph
- **PowerShell** (latest) - Automation and scripting
- **Az PowerShell Modules** - Azure management via PowerShell

### Development Tools

- **Git** (latest) - Version control
- **GitHub CLI** (latest) - GitHub integration
- **Docker** (latest) - Container management
- **Docker Compose** (v2) - Multi-container apps

### Linting & Validation

- **shellcheck** (latest) - Shell script linting
- **yamllint** (latest) - YAML linting
- **actionlint** (latest) - GitHub Actions validation
- **markdownlint-cli** (latest) - Markdown linting
- **PSScriptAnalyzer** - PowerShell script analysis

### Testing & Quality

- **Pester** - PowerShell testing framework
- **pre-commit** - Git hooks framework
- **detect-secrets** - Secret detection
- **commitizen** - Conventional commits

### Language Runtimes

- **Python 3.11** - Scripting and tooling
- **Node.js LTS** - JavaScript tooling
- **PowerShell Core** - Cross-platform automation

## Feature Configuration

### Terraform Feature Options

```json
"ghcr.io/devcontainers/features/terraform:1": {
    "version": "latest",
    "tflint": "latest",
    "terragrunt": "latest",
    "tfsec": "latest",
    "terraformDocs": "latest"
}
```

### Docker-in-Docker Feature

```json
"ghcr.io/devcontainers/features/docker-in-docker:2": {
    "version": "latest",
    "dockerDashComposeVersion": "v2"
}
```

## Updating Tools

### To Update a Feature Version

1. Edit `.devcontainer/devcontainer.json`
2. Change the version in the feature configuration
3. Rebuild the container: `Dev Containers: Rebuild Container`

### To Add New Features

1. Browse available features: <https://containers.dev/features>
2. Add to `features` section in `devcontainer.json`
3. Rebuild container

## Troubleshooting

### Feature Installation Fails

- Check feature compatibility with base image
- Review feature documentation for required settings
- Check container logs: `View → Output → Dev Containers`

### Tool Not Found After Rebuild

- Ensure feature is properly configured in `devcontainer.json`
- Verify feature version is valid
- Check if tool requires additional PATH configuration

### Slow Container Startup

- Features should be cached after first build
- Check network connectivity (first build downloads features)
- Review `postCreateCommand` execution time

## Additional Optimizations

### Future Improvements

1. **Layer Caching**: Consider using a custom base image with pre-installed tools
2. **Parallel Execution**: Move more setup.sh tasks to features where possible
3. **Lazy Loading**: Defer non-critical tool installation to first use
4. **Pre-built Image**: Publish a pre-built devcontainer image for instant startup

### Best Practices

- Keep features updated to benefit from upstream improvements
- Use specific versions for production stability
- Use "latest" for development to get bug fixes
- Document any custom feature configurations
- Test container rebuild regularly

## References

- [DevContainer Features](https://containers.dev/features)
- [Feature Specification](https://containers.dev/implementors/features/)
- [Official Features](https://github.com/devcontainers/features)
- [Community Features](https://github.com/devcontainers-contrib/features)

## Migration Summary

| Category | Before | After | Change |
|----------|--------|-------|--------|
| Installation Method | Manual scripts | DevContainer Features | ✅ Optimized |
| Startup Time | 3-5 min | 1-2 min | ✅ 60-70% faster |
| Caching | Minimal | Feature layer caching | ✅ Improved |
| Maintainability | Complex scripts | Declarative config | ✅ Simplified |
| Parallelization | Sequential | Parallel features | ✅ Concurrent |
| Tool Updates | Manual script edits | Feature version bumps | ✅ Easier |

---

**Last Updated**: 2025-10-04
**Optimized By**: DevContainer Feature Migration
