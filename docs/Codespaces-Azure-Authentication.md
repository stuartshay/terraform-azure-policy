# Azure Authentication for Codespaces

This guide explains how to authenticate to Azure in GitHub Codespaces using Service Principal credentials.

## Quick Start

Run the authentication script:

```powershell
./scripts/Connect-AzureServicePrincipal.ps1
```

## Setup Instructions

### 1. Create a Service Principal

If you don't already have a Service Principal, create one:

```bash
az ad sp create-for-rbac --name "terraform-azure-policy-sp" \
  --role "Contributor" \
  --scopes /subscriptions/<SUBSCRIPTION_ID>
```

This will output:

```json
{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "terraform-azure-policy-sp",
  "password": "your-client-secret",
  "tenant": "00000000-0000-0000-0000-000000000000"
}
```

### 2. Configure Codespaces Secrets

Add the following secrets to your GitHub Codespaces:

**Option A: Repository Secrets** (for all codespaces from this repo)

1. Go to: `https://github.com/<owner>/<repo>/settings/secrets/codespaces`
2. Add the following secrets:
   - `ARM_CLIENT_ID` → `appId` from above
   - `ARM_CLIENT_SECRET` → `password` from above
   - `ARM_TENANT_ID` → `tenant` from above
   - `ARM_SUBSCRIPTION_ID` → Your Azure subscription ID

**Option B: User Secrets** (for all your codespaces)

1. Go to: `https://github.com/settings/codespaces`
2. Click "New secret" and add the same secrets as above
3. Select which repositories can access these secrets

### 3. Authenticate in Codespaces

Once your Codespaces starts with the secrets configured:

```powershell
# Run the authentication script
./scripts/Connect-AzureServicePrincipal.ps1

# Verify authentication
Get-AzContext

# Now you can run any Azure scripts
./scripts/Run-StorageTest.ps1
./scripts/Test-PolicyCompliance.ps1
```

## Script Features

The `Connect-AzureServicePrincipal.ps1` script provides:

- ✅ **Environment validation** - Checks all required variables are set
- ✅ **Smart authentication** - Skips if already connected (unless `-Force` is used)
- ✅ **Permission verification** - Confirms access to Azure resources
- ✅ **Clear feedback** - Shows connection details and available resource groups
- ✅ **Error handling** - Provides helpful troubleshooting tips

## Script Options

### Basic Usage

```powershell
# Authenticate (skips if already connected)
./scripts/Connect-AzureServicePrincipal.ps1
```

### Force Re-authentication

```powershell
# Force re-authentication even if already connected
./scripts/Connect-AzureServicePrincipal.ps1 -Force
```

## Automatic Authentication

### Option 1: Add to PowerShell Profile

To automatically authenticate when opening a new terminal:

1. Edit the PowerShell profile:

   ```powershell
   code ~/PowerShell/Microsoft.PowerShell_profile.ps1
   ```

2. Add this line:

   ```powershell
   # Auto-authenticate to Azure if in Codespaces
   if ($env:CODESPACES -eq 'true' -and $env:ARM_CLIENT_ID) {
       & /workspaces/terraform-azure-policy/scripts/Connect-AzureServicePrincipal.ps1
   }
   ```

### Option 2: Add to devcontainer postStartCommand

Add this to `.devcontainer/devcontainer.json` or `.devcontainer/devcontainer.codespaces.json`:

```json
{
  "postStartCommand": "pwsh -Command './scripts/Connect-AzureServicePrincipal.ps1'"
}
```

## Troubleshooting

### Missing Environment Variables

If you see:

```text
❌ Missing required environment variables:
   - ARM_CLIENT_ID
```

**Solution:**

- Ensure secrets are configured in GitHub Codespaces settings
- Rebuild the codespace: `Codespaces: Rebuild Container`

### Authentication Fails

If you see `AADSTS` errors:

1. **Verify credentials** - Check that the Service Principal credentials are correct
2. **Check expiration** - Service Principal secrets can expire
3. **Verify permissions** - Ensure the SP has access to the subscription
4. **Confirm tenant** - Make sure the Tenant ID is correct

### Already Connected Warning

If you see:

```text
✅ Already connected to Azure
Use -Force parameter to re-authenticate
```

This is normal! The script detected an existing connection. Use `-Force` to re-authenticate if needed.

## Required Permissions

The Service Principal needs the following permissions:

- **Reader** role (minimum) - To read resource groups and policies
- **Contributor** role (recommended) - To deploy and test policies
- **Policy Contributor** role - For policy-specific operations

Grant permissions:

```bash
az role assignment create \
  --assignee <APP_ID> \
  --role "Policy Contributor" \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

## Security Best Practices

1. **Use repository-specific secrets** - Don't share secrets across all repositories
2. **Rotate secrets regularly** - Create new Service Principal secrets periodically
3. **Limit scope** - Grant minimum required permissions to the Service Principal
4. **Monitor usage** - Review Azure sign-in logs for the Service Principal
5. **Use separate SPs** - Different Service Principals for dev/test/prod

## Environment Variables Reference

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `ARM_CLIENT_ID` | Service Principal Application ID | Yes | `50ac2ed1-1ea1-46e6-9992-6c5de5f5da24` |
| `ARM_CLIENT_SECRET` | Service Principal Secret/Password | Yes | `abc123...` |
| `ARM_TENANT_ID` | Azure AD Tenant ID | Yes | `c725ad9b-4d37-4c38-b78d-3859e706283d` |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID | Yes | `09e01a7d-07d4-43ee-80c7-8b2c0d7ec41f` |

## Additional Resources

- [GitHub Codespaces Secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-encrypted-secrets-for-your-codespaces)
- [Azure Service Principal Authentication](https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure)
- [Azure RBAC Roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
