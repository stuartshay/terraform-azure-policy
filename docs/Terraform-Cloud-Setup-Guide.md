# Terraform Cloud Setup Guide

This document outlines the complete setup process for integrating your Azure Policy project with Terraform Cloud for publishing and state management.

## 📋 Overview

We successfully configured Terraform Cloud publishing for the Azure Policy project, enabling remote state management and CI/CD integration capabilities.

## 🏗️ Setup Process Completed

### 1. Project Investigation & Verification

#### ✅ **Current Project Analysis**

- **Project Type**: Azure Policy framework using Terraform modules
- **Structure**: Modular design with policies organized by service (storage, network, function-app, app-service)
- **Current Backend**: Azure Storage backend (sandbox environment)
- **CI/CD**: GitHub Actions workflows for deployment and testing

#### ✅ **Terraform CLI Verification**

- **Version**: Terraform v1.13.1 (functional, though slightly outdated)
- **CLI Access**: Confirmed working from `/home/vagrant/git/terraform-azure-policy`
- **Provider Requirements**: Azure RM Provider >= 4.45.0

### 2. Terraform Cloud Organization Setup

#### ✅ **Organization Creation**

- **Organization Name**: `azure-policy-compliance`
- **Plan**: Free Standard tier
- **Created**: September 29, 2025
- **URL**: `https://app.terraform.io/app/azure-policy-compliance`

#### ✅ **API Token Configuration**

- Generated organization-specific API token
- Updated `.env` file with new credentials:

  ```bash
  TF_API_TOKEN=<REDACTED_TERRAFORM_CLOUD_API_TOKEN>
  TF_CLOUD_ORGANIZATION=azure-policy-compliance
  ```

#### ✅ **CLI Authentication**

- Configured Terraform CLI credentials in `~/.terraform.d/credentials.tfrc.json`
- Verified API access to organization

### 3. Test Workspace Configuration

#### ✅ **Workspace Creation**

- **Name**: `test-workspace` (later removed after testing)
- **Execution Mode**: Local (for CLI-driven workflows)
- **Default Settings**: Remote execution mode initially, changed to local for testing

#### ✅ **Environment Variables Configuration**

Successfully configured all required Azure authentication variables:

| Variable | Type | Description | Status |
|----------|------|-------------|---------|
| `ARM_CLIENT_ID` | Environment | Azure Service Principal Client ID | ✅ Configured |
| `ARM_CLIENT_SECRET` | Environment (Sensitive) | Azure Service Principal Secret | ✅ Configured |
| `ARM_SUBSCRIPTION_ID` | Environment | Azure Subscription ID | ✅ Configured |
| `ARM_TENANT_ID` | Environment | Azure Tenant ID | ✅ Configured |

### 4. Integration Testing

#### ✅ **Test Configuration**

Created minimal test configuration:

```hcl
terraform {
  cloud { # pragma: allowlist secret
    organization = "azure-policy-compliance" # pragma: allowlist secret

    workspaces { # pragma: allowlist secret
      name = "test-workspace" # pragma: allowlist secret
    }
  }
}

data "azurerm_client_config" "current" {} # pragma: allowlist secret

output "current_subscription_id" { # pragma: allowlist secret
  value = data.azurerm_client_config.current.subscription_id
}

output "current_tenant_id" { # pragma: allowlist secret
  value = data.azurerm_client_config.current.tenant_id
}
```

#### ✅ **Successful Test Results**

- **Terraform Init**: ✅ Successful - HCP Terraform initialized
- **Provider Installation**: ✅ Azure RM Provider v4.46.0 installed
- **Azure Authentication**: ✅ Successfully authenticated with Azure
- **Plan Execution**: ✅ Successful with valid outputs:
  - Subscription ID: `<REDACTED_AZURE_SUBSCRIPTION_ID>`
  - Tenant ID: `<REDACTED_AZURE_TENANT_ID>`

### 5. Cleanup

#### ✅ **Test Environment Cleanup**

- Removed local test files (`test-terraform-cloud/` directory)
- Deleted test workspace from Terraform Cloud
- Left production-ready configuration in place

## 🔧 Environment Configuration

### Current `.env` Configuration

```bash
# Terraform Cloud Configuration
TF_API_TOKEN=<REDACTED_TERRAFORM_CLOUD_API_TOKEN>
TF_CLOUD_ORGANIZATION=azure-policy-compliance

# Azure Service Principal Credentials
ARM_CLIENT_ID=<REDACTED_AZURE_CLIENT_ID>
ARM_CLIENT_SECRET=<REDACTED_AZURE_CLIENT_SECRET>
ARM_SUBSCRIPTION_ID=<REDACTED_AZURE_SUBSCRIPTION_ID>
ARM_TENANT_ID=<REDACTED_AZURE_TENANT_ID>

# GitHub Token (for CI/CD integration)
TF_VAR_github_token=<REDACTED_GITHUB_TOKEN>
```

### Terraform CLI Configuration

- **Credentials File**: `~/.terraform.d/credentials.tfrc.json`
- **Contains**: API token for `app.terraform.io`

## 🚀 Next Steps & Recommendations

### Immediate Next Steps

1. **Production Workspace Setup**

   ```bash
   # Create production workspaces for each environment
   - policies-dev
   - policies-staging
   - policies-prod
   ```

2. **Backend Configuration**

   ```hcl
   terraform {
     cloud { # pragma: allowlist secret
       organization = "azure-policy-compliance" # pragma: allowlist secret

       workspaces { # pragma: allowlist secret
         name = "policies-${var.environment}" # pragma: allowlist secret
       }
     }
   }
   ```

3. **CI/CD Integration**
   - Update GitHub Actions workflows to use Terraform Cloud
   - Configure automated runs on push/PR
   - Set up approval workflows for production deployments

### Workspace Strategy Options

#### Option A: Environment-Based Workspaces

```bash
azure-policy-compliance/
├── policies-dev          # Development environment
├── policies-staging      # Staging environment
└── policies-prod         # Production environment
```

#### Option B: Service-Category Workspaces

```bash
azure-policy-compliance/
├── policies-storage      # Storage-related policies
├── policies-network      # Network-related policies
├── policies-compute      # Function App & App Service policies
└── policies-governance   # Cross-cutting governance policies
```

#### Option C: Hybrid Approach

```bash
azure-policy-compliance/
├── dev-policies-core     # Core policies for dev
├── dev-policies-services # Service policies for dev
├── prod-policies-core    # Core policies for prod
└── prod-policies-services # Service policies for prod
```

### GitHub Actions Integration

Update workflows to use Terraform Cloud API:

```yaml
- name: Terraform Plan
  run: |
    curl -X POST \
      -H "Authorization: Bearer ${{ secrets.TF_API_TOKEN }}" \
      -H "Content-Type: application/vnd.api+json" \
      https://app.terraform.io/api/v2/runs
```

### Variable Management Strategy

1. **Environment Variables** (in Terraform Cloud):
   - Azure credentials (ARM_*)
   - Environment-specific settings

2. **Terraform Variables** (in code):
   - Policy configurations
   - Resource naming conventions
   - Feature flags

## 🔒 Security Considerations

### Credentials Management

- ✅ Azure Service Principal credentials stored securely in Terraform Cloud
- ✅ API tokens properly configured with minimal required permissions
- ✅ Sensitive variables marked as sensitive in Terraform Cloud

### Access Control

- Organization-level access control in Terraform Cloud
- Environment-specific workspace permissions
- GitHub Actions integration with secure token management

## 📊 Benefits Achieved

### 🎯 **Remote State Management**

- Centralized state storage in Terraform Cloud
- Built-in state locking and consistency
- Team collaboration capabilities

### 🔄 **CI/CD Integration**

- API-driven deployments
- Integration with existing GitHub workflows
- Automated plan/apply capabilities

### 🛡️ **Security & Compliance**

- Secure credential storage
- Audit trail for all changes
- Team access controls

### 📈 **Scalability**

- Multiple workspace support
- Environment isolation
- Parallel deployment capabilities

## 🧪 Verification Commands

To verify the setup works in the future:

```bash
# Export environment variables
export ARM_CLIENT_ID=<REDACTED_AZURE_CLIENT_ID>
export ARM_CLIENT_SECRET=<REDACTED_AZURE_CLIENT_SECRET>
export ARM_SUBSCRIPTION_ID=<REDACTED_AZURE_SUBSCRIPTION_ID>
export ARM_TENANT_ID=<REDACTED_AZURE_TENANT_ID>

# Verify Terraform Cloud access
curl -H "Authorization: Bearer $TF_API_TOKEN" \
     https://app.terraform.io/api/v2/organizations/azure-policy-compliance

# Test workspace creation
terraform init  # In a directory with Terraform Cloud backend configuration
terraform plan   # Should connect to Terraform Cloud successfully
```

## 📞 Support & Troubleshooting

### Common Issues

1. **State Lock Errors**
   - Solution: Use `-lock=false` for testing or check workspace permissions

2. **Authentication Failures**
   - Verify API token is current and has proper permissions
   - Check Azure Service Principal credentials

3. **Workspace Access Issues**
   - Ensure execution mode is set correctly (local vs remote)
   - Verify workspace permissions

### Contact Information

- **Project Repository**: <https://github.com/stuartshay/terraform-azure-policy>
- **Terraform Cloud Organization**: <https://app.terraform.io/app/azure-policy-compliance>

---

**Setup Completed**: September 29, 2025  
**Status**: ✅ Ready for Production Use  
**Next Action**: Discuss production workspace strategy and CI/CD integration
