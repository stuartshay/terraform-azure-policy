# Publishing Guide - Terraform Registry & MyGet

Complete guide for publishing Terraform modules to Terraform Registry and Azure Policy bundles to MyGet.

## 📋 Overview

This guide covers:

- Publishing Terraform modules to Terraform Cloud Private Registry
- Publishing NuGet packages to MyGet
- CLI commands for both platforms

## ✅ Prerequisites

### Environment Configuration

Your `.env` file should contain:

```bash
# Terraform Cloud
TF_API_TOKEN=<your_token>
TF_CLOUD_ORGANIZATION=azure-policy-compliance

# MyGet
MYGET_FEED_URL=https://www.myget.org/F/azure-policy-compliance/api/v3/index.json
MYGET_API_KEY=<your_api_key>

# Azure (for module testing)
ARM_CLIENT_ID=<your_client_id>
ARM_CLIENT_SECRET=<your_client_secret>
ARM_SUBSCRIPTION_ID=<your_subscription_id>
ARM_TENANT_ID=<your_tenant_id>
```

### Tools Required

✅ All tools are pre-installed in the DevContainer:

- Terraform CLI (v1.13.3)
- .NET SDK (8.0 & 9.0)
- NuGet CLI (via `dotnet nuget` or standalone `nuget`)
- Azure CLI
- Git

## 🚀 Publishing to MyGet (NuGet Packages)

### 1. Verify MyGet Configuration

```bash
# Load environment variables
source .env

# Verify configuration
echo "MyGet Feed: $MYGET_FEED_URL"
echo "API Key configured: $([ -n "$MYGET_API_KEY" ] && echo "Yes" || echo "No")"

# List NuGet sources
dotnet nuget list source
```

### 2. Add MyGet Source (One-time setup)

```bash
source .env
dotnet nuget add source $MYGET_FEED_URL --name MyGet
```

### 3. Build NuGet Package

```bash
# Navigate to storage policies
cd policies/storage

# Update version in storage-policies.nuspec if needed
# Edit the <version> tag in the file

# Build package (example with version 1.0.1)
dotnet pack -p:NuspecFile=storage-policies.nuspec -p:PackageVersion=1.0.1

# Or if using standalone nuget (after DevContainer rebuild)
# nuget pack storage-policies.nuspec -Version 1.0.1
```

### 4. Push to MyGet

```bash
# Load environment variables
source .env

# Push package
dotnet nuget push *.nupkg \
  --source MyGet \
  --api-key $MYGET_API_KEY

# Clean up after successful push
rm -f *.nupkg
```

### Complete MyGet Publishing Workflow

```bash
#!/bin/bash
# Complete workflow for publishing to MyGet

# 1. Load environment
source .env

# 2. Navigate to package directory
cd policies/storage

# 3. Set version
VERSION="1.0.1"

# 4. Build package
dotnet pack -p:NuspecFile=storage-policies.nuspec -p:PackageVersion=$VERSION

# 5. Push to MyGet
dotnet nuget push *.nupkg \
  --source MyGet \
  --api-key $MYGET_API_KEY

# 6. Clean up
rm -f *.nupkg

echo "Package published to MyGet successfully!"
```

## 🏗️ Publishing to Terraform Cloud Private Registry

### 1. Verify Terraform Cloud Access

```bash
# Load environment variables
source .env

# Test API access
curl -s -H "Authorization: Bearer $TF_API_TOKEN" \
  https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION \
  | jq '{name: .data.attributes.name, email: .data.attributes.email}'
```

### 2. Publish Terraform Module via API

#### Option A: Using Git Tags (Recommended)

Terraform Cloud can automatically detect and publish modules from Git releases:

```bash
# 1. Ensure your module is in Git
cd modules/azure-policy

# 2. Create a semantic version tag
git tag -a "v1.0.0" -m "Release version 1.0.0 of azure-policy module"

# 3. Push tag to GitHub
git push origin v1.0.0

# 4. Register module in Terraform Cloud (one-time)
# This can be done via UI or API
```

#### Option B: Manual API Registration

```bash
source .env

# Create module in private registry
curl -X POST \
  -H "Authorization: Bearer $TF_API_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/registry-modules \
  -d '{
    "data": {
      "type": "registry-modules",
      "attributes": {
        "name": "azure-policy",
        "provider": "azurerm",
        "registry-name": "private"
      }
    }
  }'
```

### 3. Publish Module Version

```bash
source .env

# Upload module version
curl -X POST \
  -H "Authorization: Bearer $TF_API_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/registry-modules/private/$TF_CLOUD_ORGANIZATION/azure-policy/azurerm/versions \
  -d '{
    "data": {
      "type": "registry-module-versions",
      "attributes": {
        "version": "1.0.0"
      }
    }
  }'
```

### 4. Using Published Modules

Once published, you can reference the module in your Terraform code:

```hcl
module "azure_policy" {
  source  = "app.terraform.io/azure-policy-compliance/azure-policy/azurerm"
  version = "1.0.0"

  # Module inputs
  policy_name        = "my-policy"
  policy_description = "My custom policy"
  # ... other variables
}
```

## 📦 Package Versioning

### Semantic Versioning

Both Terraform modules and NuGet packages should follow semantic versioning:

- **MAJOR** version (1.x.x): Incompatible API changes
- **MINOR** version (x.1.x): Backward-compatible functionality
- **PATCH** version (x.x.1): Backward-compatible bug fixes

### Pre-release Versions

For testing:

```bash
# NuGet pre-release
dotnet pack -p:PackageVersion=1.0.0-alpha1

# Terraform pre-release
git tag -a "v1.0.0-beta1" -m "Beta release"
```

## 🔍 Verification

### Verify MyGet Package

```bash
# Search for package on MyGet
curl -s "$MYGET_FEED_URL" | jq '.resources[] | select(.["@type"] == "SearchQueryService")'

# Or visit MyGet feed in browser
echo "https://www.myget.org/feed/Packages/azure-policy-compliance"
```

### Verify Terraform Module

```bash
source .env

# List modules in private registry
curl -s -H "Authorization: Bearer $TF_API_TOKEN" \
  "https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/registry-modules" \
  | jq '.data[] | {name: .attributes.name, provider: .attributes.provider}'
```

## 🛠️ Troubleshooting

### NuGet Issues

#### Package Already Exists

MyGet doesn't allow overwriting existing versions:

```bash
# Solution 1: Delete from MyGet UI
# Solution 2: Increment version number
VERSION="1.0.2"  # Use new version
```

#### Authentication Failed

```bash
# Verify API key
echo $MYGET_API_KEY

# Re-add source with credentials
dotnet nuget remove source MyGet
source .env
dotnet nuget add source $MYGET_FEED_URL --name MyGet
```

### Terraform Cloud Issues

#### 401 Unauthorized

```bash
# Verify token
curl -H "Authorization: Bearer $TF_API_TOKEN" \
  https://app.terraform.io/api/v2/account/details

# Re-login if needed
terraform login
```

#### Module Not Found

Ensure:

1. Module is registered in private registry
2. Organization name is correct
3. Module name follows naming convention

## 📝 DevContainer Integration

### NuGet CLI Installation

The DevContainer now automatically installs NuGet CLI on rebuild:

```bash
# After DevContainer rebuild, verify:
nuget help

# If not available, manually run:
bash .devcontainer/setup.sh
```

### Environment Variables

DevContainer automatically loads from `.env`:

```json
// In .devcontainer/devcontainer.json
"containerEnv": {
  "TF_API_TOKEN": "${localEnv:TF_API_TOKEN}",
  "MYGET_API_KEY": "${localEnv:MYGET_API_KEY}"
}
```

## 🔐 Security Best Practices

1. **Never commit secrets** - Use `.env` file (already in `.gitignore`)
2. **Use GitHub Secrets** - For CI/CD workflows
3. **Rotate API keys** - Regularly update tokens
4. **Limit permissions** - Use least-privilege tokens

## 📚 Additional Resources

- [Terraform Cloud API Docs](https://developer.hashicorp.com/terraform/cloud-docs/api-docs)
- [MyGet Documentation](https://docs.myget.org/)
- [NuGet CLI Reference](https://learn.microsoft.com/en-us/nuget/reference/nuget-exe-cli-reference)
- [Semantic Versioning](https://semver.org/)

## 🎯 Quick Reference

### MyGet - Publish Storage Bundle

```bash
cd policies/storage && \
source ../../.env && \
dotnet pack -p:NuspecFile=storage-policies.nuspec -p:PackageVersion=1.0.1 && \
dotnet nuget push *.nupkg --source MyGet --api-key $MYGET_API_KEY && \
rm -f *.nupkg
```

### Terraform Cloud - Check Module Status

```bash
source .env && \
curl -s -H "Authorization: Bearer $TF_API_TOKEN" \
  "https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/registry-modules" \
  | jq '.data[] | {name: .attributes.name, versions: .attributes["version-statuses"]}'
```

---

**Last Updated:** October 14, 2025
**Maintained by:** Azure Policy DevOps Team
