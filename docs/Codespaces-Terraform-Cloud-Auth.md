# GitHub Codespaces - Automatic Terraform Cloud Authentication

This guide explains how automatic Terraform Cloud/Enterprise authentication works in GitHub Codespaces using API tokens.

## Overview

When you start a Codespace, the devcontainer automatically configures Terraform CLI credentials using your Terraform Cloud API token stored in GitHub Codespaces secrets. This enables seamless integration with Terraform Cloud features like remote state, remote execution, and policy enforcement.

## Setup Instructions

### 1. Create Terraform Cloud API Token

First, generate an API token from Terraform Cloud:

1. Log in to [Terraform Cloud](https://app.terraform.io)
2. Go to **User Settings** → **Tokens**
3. Click **Create an API token**
4. Name it (e.g., "GitHub Codespaces")
5. Copy the token (you won't be able to see it again!)

**Direct Link**: <https://app.terraform.io/app/settings/tokens>

### 2. Set GitHub Codespaces Secrets

Navigate to your GitHub Codespaces secrets settings:

- **URL**: <https://github.com/settings/codespaces>
- **Or**: GitHub Settings → Codespaces → Secrets

Add the following secrets:

| Secret Name | Description | Required | Example Value |
|-------------|-------------|----------|---------------|
| `TF_API_TOKEN` | Terraform Cloud API Token | Yes | `your-token-here` |
| `TF_CLOUD_ORGANIZATION` | Your Terraform Cloud Organization name | No | `my-company` |

> **Note**: `TF_CLOUD_ORGANIZATION` is optional but recommended if you primarily work with one organization.

### 3. Rebuild Your Codespace

After adding the secrets:

1. Press `F1` → `Codespaces: Rebuild Container`
2. Or stop and restart your Codespace
3. The devcontainer setup will automatically configure Terraform CLI

## How It Works

### Automatic Configuration Flow

1. **Container Creation**: Codespaces starts the devcontainer
2. **Environment Variables**: GitHub secrets are injected as environment variables
3. **Setup Script**: `.devcontainer/setup.sh` runs automatically
4. **Terraform Config**: `.devcontainer/terraform-cli-login.sh` creates credentials file
5. **Ready to Use**: Terraform CLI is configured for Terraform Cloud

### What Gets Configured

The setup creates `~/.terraform.d/credentials.tfrc.json`:

```json
{
  "credentials": {
    "app.terraform.io": {
      "token": "your-token-here"
    }
  }
}
```

### Configuration Files

#### `.devcontainer/devcontainer.json`

```json
{
  "containerEnv": {
    "TF_API_TOKEN": "${localEnv:TF_API_TOKEN}",
    "TF_CLOUD_ORGANIZATION": "${localEnv:TF_CLOUD_ORGANIZATION}"
  }
}
```

#### `.devcontainer/terraform-cli-login.sh`

Handles the Terraform CLI credential configuration using the API token.

#### `.devcontainer/setup.sh`

Calls the Terraform CLI login script during container setup.

## Verification

After the Codespace starts, verify the configuration:

### Quick Check

```bash
# Check if credentials file exists
ls -la ~/.terraform.d/credentials.tfrc.json

# View Terraform version
terraform version

# Check environment variables
echo $TF_API_TOKEN  # Should show your token
echo $TF_CLOUD_ORGANIZATION  # Should show your org (if set)
```

### Full Test

Run the comprehensive test script:

```bash
bash .devcontainer/test-terraform-auth.sh
```

This will verify:

- ✅ Terraform installation
- ✅ Environment variables
- ✅ Credentials file configuration
- ✅ API connectivity to Terraform Cloud
- ✅ Organization access (if configured)
- ✅ Workspace listing

## Using Terraform Cloud in Your Code

### Basic Cloud Configuration

```hcl
terraform {
  cloud {
    organization = "my-company"

    workspaces {
      name = "my-workspace"
    }
  }
}
```

### With Environment Variable

```hcl
terraform {
  cloud {
    organization = var.tf_cloud_organization

    workspaces {
      name = "azure-policy-${var.environment}"
    }
  }
}

variable "tf_cloud_organization" {
  type    = string
  default = env("TF_CLOUD_ORGANIZATION")
}
```

### Initialize and Use

```bash
# Initialize with Terraform Cloud backend
terraform init

# Plan (runs remotely in Terraform Cloud)
terraform plan

# Apply (runs remotely)
terraform apply
```

## Features Available with Terraform Cloud

Once configured, you can use:

### ✅ Remote State Management

- Automatic state locking
- State versioning and history
- Team collaboration
- Secure state storage

### ✅ Remote Execution

- Run Terraform in Terraform Cloud infrastructure
- Consistent environment for all team members
- Build artifacts and logs stored centrally

### ✅ Policy as Code (Sentinel)

- Enforce organizational policies
- Cost controls
- Security compliance
- Deployment gates

### ✅ Private Registry

- Share Terraform modules privately
- Version control for modules
- Module documentation

### ✅ Cost Estimation

- Estimate infrastructure costs before apply
- Budget tracking
- Cost analysis

## Troubleshooting

### Issue: Token Not Working

**Symptom**: Authentication fails or token is invalid

**Solution**:

1. Verify the token is correct:

   ```bash
   # Test API access
   curl -s -H "Authorization: Bearer $TF_API_TOKEN" \
     https://app.terraform.io/api/v2/account/details
   ```

2. Check token expiration in Terraform Cloud UI
3. Generate a new token if needed
4. Update GitHub Codespaces secret
5. Rebuild the container

### Issue: Credentials File Not Created

**Symptom**: `~/.terraform.d/credentials.tfrc.json` doesn't exist

**Solution**:

1. Check environment variable:

   ```bash
   echo $TF_API_TOKEN
   ```

2. If empty, verify GitHub Codespaces secret is set
3. Rebuild container
4. Manually run the login script:

   ```bash
   bash .devcontainer/terraform-cli-login.sh
   ```

### Issue: Wrong Organization

**Symptom**: Can't access organization or workspaces

**Solution**:

1. Verify organization name:

   ```bash
   echo $TF_CLOUD_ORGANIZATION
   ```

2. Check token has access to organization:

   ```bash
   curl -s -H "Authorization: Bearer $TF_API_TOKEN" \
     "https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION"
   ```

3. Update the `TF_CLOUD_ORGANIZATION` secret in GitHub

### Issue: Permission Denied

**Symptom**: Cannot access workspaces or run operations

**Solution**:

1. Check token permissions in Terraform Cloud
2. Ensure you're a member of the organization
3. Verify workspace permissions
4. Token may need to be an organization token (not user token)

### Issue: Terraform Init Fails

**Symptom**: `terraform init` doesn't connect to Terraform Cloud

**Solution**:

1. Verify credentials file exists and is valid:

   ```bash
   cat ~/.terraform.d/credentials.tfrc.json
   ```

2. Check Terraform configuration has cloud block:

   ```hcl
   terraform {
     cloud {
       organization = "my-org"
       workspaces {
         name = "my-workspace"
       }
     }
   }
   ```

3. Ensure workspace exists in Terraform Cloud
4. Try running with debug logging:

   ```bash
   TF_LOG=DEBUG terraform init
   ```

## Security Best Practices

### ✅ Do's

- ✅ Use user-specific tokens for development
- ✅ Use team/organization tokens for CI/CD
- ✅ Store tokens only in GitHub Codespaces Secrets
- ✅ Rotate tokens regularly (every 90 days)
- ✅ Use descriptive token names to track usage
- ✅ Set token expiration dates
- ✅ Delete tokens when no longer needed

### ❌ Don'ts

- ❌ Never commit tokens to repository
- ❌ Don't share tokens between team members
- ❌ Avoid using tokens with overly broad permissions
- ❌ Don't log or print token values
- ❌ Never store tokens in plain text files in the repository

## Token Types and Permissions

### User Tokens

- **Use for**: Personal development, testing
- **Access**: Your personal workspaces and organizations you belong to
- **Scope**: Limited to your permissions

### Team Tokens

- **Use for**: Shared team workflows
- **Access**: Team-specific workspaces
- **Scope**: Team permissions

### Organization Tokens

- **Use for**: CI/CD pipelines, automation
- **Access**: Organization-wide
- **Scope**: Can be scoped to specific workspaces

## Integration with Azure Authentication

Both Azure and Terraform Cloud authentication work together:

```bash
# Azure credentials (for provider authentication)
ARM_CLIENT_ID
ARM_CLIENT_SECRET
ARM_TENANT_ID
ARM_SUBSCRIPTION_ID

# Terraform Cloud (for backend/state)
TF_API_TOKEN
TF_CLOUD_ORGANIZATION
```

### Example Configuration

```hcl
terraform {
  # Backend/State in Terraform Cloud
  cloud {
    organization = "my-company"
    workspaces {
      name = "azure-production"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  # Automatically uses ARM_* environment variables
}
```

## CI/CD Integration

The same secrets work in GitHub Actions:

```yaml
name: Terraform

on:
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    env:
      TF_API_TOKEN: ${{ secrets.TF_API_TOKEN }}
      TF_CLOUD_ORGANIZATION: ${{ secrets.TF_CLOUD_ORGANIZATION }}
      ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
      ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}

    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        run: terraform plan
```

## Additional Resources

- [Terraform Cloud Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [CLI Configuration](https://developer.hashicorp.com/terraform/cli/config/config-file)
- [API Tokens](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens)
- [Remote State](https://developer.hashicorp.com/terraform/language/state/remote)
- [Terraform Cloud Workspaces](https://developer.hashicorp.com/terraform/cloud-docs/workspaces)

## Quick Reference

```bash
# Check configuration
cat ~/.terraform.d/credentials.tfrc.json

# Test API connection
curl -H "Authorization: Bearer $TF_API_TOKEN" \
  https://app.terraform.io/api/v2/account/details

# Re-configure credentials
bash .devcontainer/terraform-cli-login.sh

# Run comprehensive test
bash .devcontainer/test-terraform-auth.sh

# List workspaces in organization
curl -H "Authorization: Bearer $TF_API_TOKEN" \
  "https://app.terraform.io/api/v2/organizations/$TF_CLOUD_ORGANIZATION/workspaces" \
  | jq '.data[].attributes.name'

# Initialize with Terraform Cloud
terraform init

# Check Terraform Cloud status
terraform workspace list
```

---

**Last Updated**: October 2025  
**Maintainer**: DevOps Team  
**Related Files**:

- `.devcontainer/devcontainer.json`
- `.devcontainer/terraform-cli-login.sh`
- `.devcontainer/setup.sh`
- `.devcontainer/test-terraform-auth.sh`
