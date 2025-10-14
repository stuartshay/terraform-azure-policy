# NuGet CLI Setup Guide

Complete guide for setting up NuGet CLI in all project environments for Azure Policy bundle management.

## Overview

NuGet CLI is required for building and publishing Azure Policy bundles to MyGet. This guide covers setup for:

- **GitHub Actions** (CI/CD)
- **DevContainer** (Development)
- **Local Environment** (macOS/Linux)

## Quick Status Check

```bash
# Check if NuGet is available
dotnet nuget --version

# Alternative: Check for standalone NuGet
nuget help
```

## Environment Setup

### 1. GitHub Actions ✅

**Status:** Pre-configured and working

GitHub Actions uses Windows runners which have NuGet pre-installed.

**Configuration in `.github/workflows/storage-bundle-release.yml`:**

```yaml
- name: Setup NuGet
  uses: nuget/setup-nuget@v1
  with:
    nuget-version: 'latest'

- name: Pack NuGet package
  run: |
    nuget pack storage-policies.nuspec -Version $version
```

**No action required** - GitHub Actions are ready to build and publish packages.

### 2. DevContainer 🔧

**Status:** Configured via .NET SDK feature

The DevContainer includes .NET SDK 9.0 (with 8.0 compatibility) which provides `dotnet nuget` commands.

**Configuration in `.devcontainer/devcontainer.json`:**

```json
"ghcr.io/devcontainers/features/dotnet:2": {
    "version": "9.0",
    "installUsingApt": true
}
```

**Verification:**

When you rebuild your DevContainer:

```bash
# Check .NET SDK
dotnet --version

# Check NuGet
dotnet nuget --version
```

**To rebuild DevContainer:**

1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
2. Select "Dev Containers: Rebuild Container"
3. Wait for rebuild to complete

### 3. Local Environment (macOS/Linux) 🛠️

**Status:** Installation script provided

Use the provided installation script to set up NuGet on your local machine.

#### Quick Install

```bash
# Run the installation script
./scripts/Install-NuGet.sh
```

The script will:

- Detect your operating system
- Install .NET SDK 8.0
- Verify NuGet functionality
- Provide usage examples

#### Manual Installation

**macOS (via Homebrew):**

```bash
# Install .NET SDK
brew install dotnet

# Verify installation
dotnet --version
dotnet nuget --version
```

**Linux (Ubuntu/Debian):**

```bash
# Add Microsoft repository
wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Install .NET SDK
sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0

# Verify installation
dotnet --version
dotnet nuget --version
```

**Linux (Fedora/RHEL/CentOS):**

```bash
# Install .NET SDK
sudo dnf install -y dotnet-sdk-8.0

# Verify installation
dotnet --version
dotnet nuget --version
```

## NuGet Usage

### Common Commands

```bash
# Check version
dotnet nuget --version

# Add MyGet source
dotnet nuget add source https://www.myget.org/F/azure-policy-compliance/api/v3/index.json \
  --name MyGet

# List configured sources
dotnet nuget list source

# Remove a source
dotnet nuget remove source MyGet

# Pack a NuGet package
cd policies/storage
dotnet pack storage-policies.nuspec -p:PackageVersion=1.0.1

# Push to MyGet (with API key from environment)
dotnet nuget push AzurePolicy.Storage.SecurityBundle.1.0.1.nupkg \
  --source MyGet \
  --api-key $MYGET_API_KEY
```

### Using with MyGet

#### Configure MyGet Source

```bash
# Add your MyGet feed
dotnet nuget add source https://www.myget.org/F/azure-policy-compliance/api/v3/index.json \
  --name MyGet \
  --username YOUR_USERNAME \
  --password YOUR_API_KEY
```

#### Environment Variables

Set these in your `.env` file:

```bash
# MyGet Configuration
MYGET_FEED_URL=https://www.myget.org/F/azure-policy-compliance/api/v3/index.json
MYGET_API_KEY=your-api-key-here
```

#### Push Package to MyGet

```bash
# Load environment variables
source .env

# Push package
dotnet nuget push packages/AzurePolicy.Storage.SecurityBundle.1.0.1.nupkg \
  --source $MYGET_FEED_URL \
  --api-key $MYGET_API_KEY
```

## Building Policy Bundles

### Manual Build Process

```bash
# 1. Navigate to storage policies
cd policies/storage

# 2. Build the NuGet package
dotnet pack storage-policies.nuspec -p:PackageVersion=1.0.1

# 3. Package will be created in current directory
ls -la *.nupkg
```

### Automated Build (GitHub Actions)

Trigger the release workflow:

```bash
# Using GitHub CLI
gh workflow run "Release Storage Policy Bundle" \
  -f version_bump=patch \
  -f release_notes="Your release notes here" \
  -f publish_to_myget=true \
  -f publish_to_terraform_cloud=false
```

## Troubleshooting

### Issue: `dotnet` command not found

**Solution:**

```bash
# Run the installation script
./scripts/Install-NuGet.sh

# Or install manually (see Manual Installation section above)
```

### Issue: NuGet command fails with "No .NET SDKs were found"

**Solution:**

The `dotnet` command exists but SDK is not installed:

```bash
# Check current installation
dotnet --list-sdks

# If empty, install .NET SDK
# macOS:
brew install dotnet

# Linux (Ubuntu/Debian):
sudo apt-get install -y dotnet-sdk-8.0
```

### Issue: Cannot push to MyGet - 401 Unauthorized

**Solution:**

Check your API key:

```bash
# Verify environment variable is set
echo $MYGET_API_KEY

# If not set, add to .env and reload
source .env
```

### Issue: Package already exists on MyGet

**Solution:**

MyGet doesn't allow overwriting existing versions. You must:

1. Delete the existing package version from MyGet UI
2. Or use a new version number

```bash
# Bump to new version
gh workflow run "Release Storage Policy Bundle" \
  -f version_bump=patch \
  -f release_notes="Republish with fixes"
```

## Testing Your Setup

### Quick Test Script

```bash
#!/bin/bash
# Test NuGet setup

echo "=== Testing NuGet Setup ==="
echo ""

# Test 1: Check .NET SDK
if command -v dotnet &> /dev/null; then
    echo "✅ .NET SDK: $(dotnet --version)"
else
    echo "❌ .NET SDK not found"
    exit 1
fi

# Test 2: Check NuGet
if dotnet nuget --version &> /dev/null; then
    echo "✅ NuGet: Available via dotnet CLI"
else
    echo "❌ NuGet not available"
    exit 1
fi

# Test 3: Check MyGet configuration
source .env 2>/dev/null
if [ -n "$MYGET_FEED_URL" ] && [ -n "$MYGET_API_KEY" ]; then
    echo "✅ MyGet: Configured"
else
    echo "⚠️  MyGet: Not configured (optional)"
fi

echo ""
echo "✅ NuGet setup is complete!"
```

### Full End-to-End Test

```bash
# 1. Build a test package
cd policies/storage
dotnet pack storage-policies.nuspec -p:PackageVersion=1.0.0-test

# 2. Verify package was created
ls -la *.nupkg

# 3. Test MyGet connection (without actually pushing)
source ../../.env
echo "MyGet Feed: $MYGET_FEED_URL"
curl -I "$MYGET_FEED_URL"

# 4. Clean up
rm -f *.nupkg
```

## Best Practices

1. **Version Management**
   - Always use semantic versioning (MAJOR.MINOR.PATCH)
   - Let GitHub Actions handle version bumping
   - Don't manually edit version files

2. **API Key Security**
   - Never commit API keys to repository
   - Use `.env` file for local development
   - Use GitHub Secrets for CI/CD
   - Rotate keys regularly

3. **Package Publishing**
   - Test packages locally before publishing
   - Use GitHub Actions for official releases
   - Keep changelog updated with each release

4. **Environment Consistency**
   - Use same .NET SDK version across all environments
   - Verify NuGet availability in all environments
   - Document any environment-specific configurations

## Additional Resources

- [.NET SDK Documentation](https://learn.microsoft.com/en-us/dotnet/core/sdk)
- [NuGet CLI Reference](https://learn.microsoft.com/en-us/nuget/reference/nuget-exe-cli-reference)
- [MyGet Documentation](https://docs.myget.org/)
- [Storage Bundle Versioning Guide](Storage-Bundle-Versioning-Guide.md)

## Support

For issues or questions:

1. Check this guide first
2. Review the troubleshooting section
3. Check GitHub Actions logs for CI/CD issues
4. Verify environment variables are set correctly
5. Ensure .NET SDK is properly installed

---

**Last Updated:** 2025-10-13
**Maintained by:** Azure Policy DevOps Team
