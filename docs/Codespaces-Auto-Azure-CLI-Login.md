# GitHub Codespaces - Automatic Azure CLI Authentication

This guide explains how automatic Azure CLI authentication works in GitHub Codespaces using Service Principal credentials.

## Overview

When you start a Codespace, the devcontainer automatically authenticates to Azure CLI using Service Principal credentials stored in GitHub Codespaces secrets. This provides immediate access to Azure resources without manual login.

## Setup Instructions

### 1. Set GitHub Codespaces Secrets

Navigate to your GitHub Codespaces secrets settings:

- **URL**: <https://github.com/settings/codespaces>
- **Or**: GitHub Settings → Codespaces → Secrets

Add the following secrets:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `ARM_CLIENT_ID` | Service Principal Application (Client) ID | `12345678-1234-1234-1234-123456789012` |
| `ARM_CLIENT_SECRET` | Service Principal Secret/Password | `your-client-secret-value` |
| `ARM_TENANT_ID` | Azure AD Tenant ID | `87654321-4321-4321-4321-210987654321` |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID | `abcdef12-3456-7890-abcd-ef1234567890` |

### 2. Create Azure Service Principal (If Needed)

If you don't have a Service Principal, create one:

```bash
# Login to Azure
az login

# Create Service Principal
az ad sp create-for-rbac \
  --name "github-codespaces-terraform" \
  --role "Contributor" \
  --scopes "/subscriptions/<your-subscription-id>"
```

This command outputs the required credentials:

- `appId` → `ARM_CLIENT_ID`
- `password` → `ARM_CLIENT_SECRET`
- `tenant` → `ARM_TENANT_ID`

### 3. Grant Appropriate Permissions

Ensure the Service Principal has the necessary permissions:

```bash
# For Policy Management
az role assignment create \
  --assignee <ARM_CLIENT_ID> \
  --role "Resource Policy Contributor" \
  --scope "/subscriptions/<ARM_SUBSCRIPTION_ID>"

# For Policy Insights (read compliance)
az role assignment create \
  --assignee <ARM_CLIENT_ID> \
  --role "Policy Insights Data Writer (Preview)" \
  --scope "/subscriptions/<ARM_SUBSCRIPTION_ID>"
```

## How It Works

### Automatic Authentication Flow

1. **Container Creation**: When Codespaces starts, the devcontainer is created
2. **Environment Variables**: GitHub Codespaces secrets are injected as environment variables
3. **Setup Script**: `.devcontainer/setup.sh` runs automatically
4. **Azure Login**: `.devcontainer/azure-cli-login.sh` authenticates to Azure CLI
5. **Ready to Use**: Azure CLI is authenticated and ready

### Configuration Files

#### `.devcontainer/devcontainer.json`

```json
{
  "containerEnv": {
    "ARM_CLIENT_ID": "${localEnv:ARM_CLIENT_ID}",
    "ARM_CLIENT_SECRET": "${localEnv:ARM_CLIENT_SECRET}",
    "ARM_TENANT_ID": "${localEnv:ARM_TENANT_ID}",
    "ARM_SUBSCRIPTION_ID": "${localEnv:ARM_SUBSCRIPTION_ID}"
  }
}
```

#### `.devcontainer/azure-cli-login.sh`

Handles the Azure CLI authentication using service principal credentials.

#### `.devcontainer/setup.sh`

Calls the Azure CLI login script during container setup.

## Verification

After the Codespace starts, verify authentication:

```bash
# Check authentication status
az account show

# List accessible subscriptions
az account list --output table

# Verify the correct subscription is set
az account show --query "{Name:name, ID:id, TenantID:tenantId}" --output table
```

## Manual Authentication (Fallback)

If automatic authentication fails or secrets are not set:

### Option 1: Service Principal (Same as Automatic)

```bash
az login --service-principal \
  --username $ARM_CLIENT_ID \
  --password $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID

az account set --subscription $ARM_SUBSCRIPTION_ID
```

### Option 2: Interactive Login

```bash
# Device code flow (works in Codespaces)
az login --use-device-code

# Set subscription
az account set --subscription <subscription-id>
```

## Troubleshooting

### Issue: Secrets Not Available

**Symptom**: Environment variables are not set

```bash
echo $ARM_CLIENT_ID  # Returns empty
```

**Solution**:

1. Verify secrets are set at <https://github.com/settings/codespaces>
2. Rebuild the Codespace: `Codespaces: Rebuild Container`
3. Check the repository has access to the secrets

### Issue: Authentication Fails

**Symptom**: Azure CLI login fails with authentication error

**Solution**:

1. Verify Service Principal credentials:

   ```bash
   # Test credentials locally first
   az login --service-principal \
     --username <ARM_CLIENT_ID> \
     --password <ARM_CLIENT_SECRET> \
     --tenant <ARM_TENANT_ID>
   ```

2. Check Service Principal permissions:

   ```bash
   az role assignment list --assignee <ARM_CLIENT_ID> --output table
   ```

3. Ensure the secret hasn't expired:

   ```bash
   az ad sp credential list --id <ARM_CLIENT_ID>
   ```

### Issue: Wrong Subscription

**Symptom**: Authenticated but using wrong subscription

**Solution**:

```bash
# List available subscriptions
az account list --output table

# Set correct subscription
az account set --subscription <correct-subscription-id>
```

### Issue: Script Not Executing

**Symptom**: Azure CLI login script doesn't run

**Solution**:

1. Check script exists and is executable:

   ```bash
   ls -la .devcontainer/azure-cli-login.sh
   ```

2. Make executable if needed:

   ```bash
   chmod +x .devcontainer/azure-cli-login.sh
   ```

3. Run manually:

   ```bash
   bash .devcontainer/azure-cli-login.sh
   ```

## Security Best Practices

### ✅ Do's

- ✅ Use Service Principal with least-privilege permissions
- ✅ Store credentials only in GitHub Codespaces Secrets
- ✅ Rotate Service Principal secrets regularly
- ✅ Use repository-specific secrets when possible
- ✅ Monitor Service Principal usage via Azure AD logs

### ❌ Don'ts

- ❌ Never commit credentials to repository
- ❌ Don't share Service Principal credentials
- ❌ Avoid granting Owner role unless necessary
- ❌ Don't use personal account credentials
- ❌ Never log the `ARM_CLIENT_SECRET` value

## Integration with Other Tools

### Terraform

Terraform automatically uses the same environment variables:

```bash
# No additional configuration needed
terraform plan
terraform apply
```

### PowerShell (Az Module)

The existing `Connect-AzureServicePrincipal.ps1` script also uses these variables:

```powershell
# Authenticate PowerShell Az module
./scripts/Connect-AzureServicePrincipal.ps1
```

### CI/CD Pipelines

The same secrets work in GitHub Actions:

```yaml
env:
  ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
  ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
```

## Additional Resources

- [GitHub Codespaces Secrets Documentation](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-encrypted-secrets-for-your-codespaces)
- [Azure Service Principal Documentation](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)
- [Azure CLI Login Methods](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli)
- [Terraform Azure Provider Authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure)

## Quick Reference

```bash
# Check if authenticated
az account show

# Re-authenticate manually
bash .devcontainer/azure-cli-login.sh

# View current environment variables (safe - secrets hidden)
env | grep ARM_ | grep -v SECRET

# Test Azure access
az group list --output table

# Get token for debugging
az account get-access-token
```

---

**Last Updated**: October 2025  
**Maintainer**: DevOps Team  
**Related Files**:

- `.devcontainer/devcontainer.json`
- `.devcontainer/azure-cli-login.sh`
- `.devcontainer/setup.sh`
- `scripts/Connect-AzureServicePrincipal.ps1`
