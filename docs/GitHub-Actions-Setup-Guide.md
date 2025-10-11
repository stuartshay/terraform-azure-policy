# GitHub Actions Setup Steps & Troubleshooting Guide

This document describes the setup steps configured in GitHub Actions workflows to handle package installation, especially for environments with firewall restrictions.

## Overview

GitHub Actions workflows in this repository are configured with robust setup steps to handle:

- PowerShell Gallery connectivity issues
- Firewall-blocked package sources
- Network timeouts and intermittent failures
- Module installation retries

## Configured Setup Steps

### 1. PowerShell Installation

All workflows that require PowerShell modules follow this setup sequence:

```yaml
- name: Setup PowerShell
  shell: bash
  run: |
    sudo apt-get update
    sudo apt-get install -y wget apt-transport-https software-properties-common
    wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
    sudo dpkg -i packages-microsoft-prod.deb
    sudo apt-get update
    sudo apt-get install -y powershell
    pwsh --version
```

### 2. Network Diagnostics

Before installing PowerShell modules, workflows run network diagnostics to identify connectivity issues:

```yaml
- name: Network diagnostics for package sources
  run: |
    echo "Testing PowerShell Gallery (www.powershellgallery.com)..."
    curl -I https://www.powershellgallery.com --max-time 10 || echo "⚠ PowerShell Gallery not accessible"

    echo "Testing PowerShell Gallery API..."
    curl -I https://www.powershellgallery.com/api/v2 --max-time 10 || echo "⚠ PowerShell Gallery API not accessible"

    echo "Testing DNS resolution..."
    nslookup www.powershellgallery.com || echo "⚠ DNS resolution failed"
```

### 3. PowerShell Gallery Connectivity Validation

Validates that PowerShell can access the PowerShell Gallery:

```yaml
- name: Validate PowerShell Gallery connectivity
  run: |
    pwsh -Command "
      try {
        \$response = Invoke-WebRequest -Uri 'https://www.powershellgallery.com' -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        Write-Host '✓ PowerShell Gallery is accessible (Status: '\$response.StatusCode')'
      }
      catch {
        Write-Warning 'PowerShell Gallery connectivity check failed'
      }
    "
```

### 4. Module Installation with Retry Logic

Uses the centralized `Install-ModulesForCI.ps1` script with built-in retry logic:

```yaml
- name: Install PowerShell modules for testing
  run: |
    pwsh -ExecutionPolicy Bypass -File ./scripts/Install-ModulesForCI.ps1 \
      -RequiredModules @('Pester', 'PSScriptAnalyzer') \
      -MaxRetries 3 \
      -RetryDelaySeconds 10
```

## Install-ModulesForCI.ps1 Script

This script provides robust module installation with the following features:

### Features

1. **Retry Logic**: Automatically retries failed module installations (default: 3 attempts)
2. **Connectivity Testing**: Tests PowerShell Gallery connectivity before installation
3. **TLS Configuration**: Ensures TLS 1.2 is enabled for secure connections
4. **Detailed Logging**: Provides verbose output for troubleshooting
5. **Verification**: Confirms module installation and import capability

### Usage

```powershell
# Install specific modules with default settings
./scripts/Install-ModulesForCI.ps1 -RequiredModules @('Pester', 'PSScriptAnalyzer')

# Install with custom retry settings
./scripts/Install-ModulesForCI.ps1 `
    -RequiredModules @('Pester', 'PSScriptAnalyzer', 'Az.Accounts') `
    -MaxRetries 5 `
    -RetryDelaySeconds 10
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `RequiredModules` | string[] | `@('Pester', 'PSScriptAnalyzer', 'Az.Accounts', 'Az.Resources')` | Array of module names to install |
| `MaxRetries` | int | 3 | Maximum number of retry attempts per module |
| `RetryDelaySeconds` | int | 5 | Delay in seconds between retry attempts |

### Output Example

```text
═══════════════════════════════════════════════════════
  PowerShell Module Installation for CI/CD
═══════════════════════════════════════════════════════

Environment Information:
  PowerShell Version: 7.4.0
  OS: Linux 5.15.0-1052-azure #60-Ubuntu SMP
  Platform: Unix

Testing PowerShell Gallery connectivity...
  ✓ PowerShell Gallery is accessible (Status: 200)

Configuring PSGallery repository...
  ✓ PSGallery repository configured
    Source Location: https://www.powershellgallery.com/api/v2
    Installation Policy: Trusted

Installing 2 required module(s)...

Processing: Pester
  Attempt 1 of 3: Installing Pester...
    ✓ Successfully installed Pester (Version: 5.6.1)

Processing: PSScriptAnalyzer
  Attempt 1 of 3: Installing PSScriptAnalyzer...
    ✓ Successfully installed PSScriptAnalyzer (Version: 1.23.0)

═══════════════════════════════════════════════════════
  Installation Summary
═══════════════════════════════════════════════════════

Module            Success Action           Version
------            ------- ------           -------
Pester            True    Newly Installed  5.6.1
PSScriptAnalyzer  True    Newly Installed  1.23.0

Total Modules: 2
Successful: 2
Failed: 0

✓ All modules installed successfully!

Testing module imports...
  ✓ Pester imported successfully
  ✓ PSScriptAnalyzer imported successfully
```

## Troubleshooting

### Issue: PowerShell Gallery Unreachable

**Symptoms:**

- `curl -I https://www.powershellgallery.com` fails
- Network diagnostics show connectivity issues

**Solutions:**

1. **Check firewall rules**: Ensure GitHub Actions runners can access:
   - `https://www.powershellgallery.com`
   - `https://www.powershellgallery.com/api/v2`
   - `https://psg-prod-eastus.azureedge.net` (CDN endpoint)

2. **Retry with longer delays**: Increase retry delays in the workflow:

   ```yaml
   - name: Install PowerShell modules
     run: |
       pwsh -File ./scripts/Install-ModulesForCI.ps1 \
         -MaxRetries 5 \
         -RetryDelaySeconds 15
   ```

3. **Use alternative installation method**: Install from local cache or pre-downloaded packages:

   ```yaml
   - name: Cache PowerShell modules
     uses: actions/cache@v4
     with:
       path: ~/.local/share/powershell/Modules
       key: ${{ runner.os }}-psmodules-${{ hashFiles('requirements.psd1') }}
   ```

### Issue: Module Installation Timeouts

**Symptoms:**

- Installation hangs or times out
- Network diagnostics pass but module installation fails

**Solutions:**

1. **Increase timeout values**: Modify the script to use longer timeouts
2. **Install modules sequentially**: Reduce concurrent installations
3. **Use module cache**: Cache installed modules between workflow runs

### Issue: TLS/SSL Errors

**Symptoms:**

- SSL handshake failures
- Certificate validation errors

**Solutions:**

1. **Ensure TLS 1.2 is enabled**: The script automatically configures this:

   ```powershell
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
   ```

2. **Update PowerShell**: Ensure you're using PowerShell 7.0+

### Issue: Repository Not Trusted

**Symptoms:**

- Prompts for untrusted repository confirmation
- Installation fails in non-interactive mode

**Solutions:**

The script automatically sets PSGallery as trusted:

```powershell
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
```

## Workflow Integration Examples

### CI Workflow (ci.yml)

```yaml
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v5

      - name: Setup PowerShell
        # ... (see setup steps above)

      - name: Network diagnostics
        # ... (see diagnostics above)

      - name: Install PowerShell modules
        run: |
          pwsh -ExecutionPolicy Bypass -File ./scripts/Install-ModulesForCI.ps1 \
            -RequiredModules @('Pester', 'PSScriptAnalyzer')
```

### DevContainer Workflow (devcontainer.yml)

The DevContainer workflow uses the setup script during container build:

```yaml
- name: Build and test devcontainer
  uses: devcontainers/ci@v0.3
  with:
    configFile: .devcontainer/devcontainer.json
    runCmd: |
      pwsh -Command "Get-Module -ListAvailable"
```

## Best Practices

1. **Always use retry logic**: Network issues can be intermittent
2. **Add connectivity checks**: Validate access to package sources before installation
3. **Cache modules when possible**: Reduces installation time and network dependency
4. **Use centralized scripts**: Maintain consistency across workflows
5. **Monitor workflow runs**: Watch for patterns in failures
6. **Document firewall requirements**: List all required endpoints

## Required Network Endpoints

Ensure GitHub Actions runners have access to:

| Endpoint | Purpose | Protocol |
|----------|---------|----------|
| `www.powershellgallery.com` | PowerShell Gallery main site | HTTPS |
| `www.powershellgallery.com/api/v2` | PowerShell Gallery API | HTTPS |
| `psg-prod-eastus.azureedge.net` | PowerShell Gallery CDN | HTTPS |
| `packages.microsoft.com` | Microsoft package repository | HTTPS |
| `github.com` | GitHub API and packages | HTTPS |

## Related Files

- `.github/workflows/ci.yml` - Main CI workflow with comprehensive setup
- `scripts/Install-ModulesForCI.ps1` - Centralized module installation script
- `scripts/Install-Requirements.ps1` - Development environment setup
- `requirements.psd1` - PowerShell module requirements

## Additional Resources

- [PowerShell Gallery](https://www.powershellgallery.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [PowerShell Module Installation](https://docs.microsoft.com/en-us/powershell/scripting/gallery/how-to/working-with-packages/manual-download)
- [Troubleshooting PowerShell Gallery](https://docs.microsoft.com/en-us/powershell/scripting/gallery/getting-started#troubleshooting)

## Support

For issues related to:

- **Workflow failures**: Check GitHub Actions logs and this troubleshooting guide
- **Module installation**: Review `Install-ModulesForCI.ps1` output
- **Network connectivity**: Run network diagnostics step manually
- **Firewall configuration**: Contact your network administrator

---

**Last Updated**: December 2024  
**Maintainer**: DevOps Team  
**Related Issue**: #18 - Configure Actions setup steps
