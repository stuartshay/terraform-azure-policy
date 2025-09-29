# Versioned Package Deployment Guide

This guide explains how to create versioned packages of the Azure Policy project and deploy them to specific Azure Resource Groups using GitHub Actions.

## 🚀 Quick Start

### 1. Create a New Release

```bash
# Create a patch release (1.0.0 → 1.0.1)
gh workflow run release.yml -f version_type=patch

# Create a minor release (1.0.1 → 1.1.0)
gh workflow run release.yml -f version_type=minor

# Create a major release (1.1.0 → 2.0.0)
gh workflow run release.yml -f version_type=major

# Create a custom version
gh workflow run release.yml -f custom_version=1.5.0
```

### 2. Deploy to Azure Resource Group

```bash
# Deploy latest release to production
gh workflow run deploy.yml \
  -f version="1.0.0" \
  -f resource_group="rg-azure-policy-prod" \
  -f subscription_id="your-subscription-id" \
  -f environment="production" \
  -f policy_effect="Deny"

# Dry run deployment (plan only)
gh workflow run deploy.yml \
  -f version="1.0.0" \
  -f resource_group="rg-azure-policy-test" \
  -f subscription_id="your-subscription-id" \
  -f environment="staging" \
  -f policy_effect="Audit" \
  -f dry_run="true"
```

## 📦 Package Management

### List Available Releases

```bash
gh workflow run package-management.yml -f action=list-releases
```

### Validate a Package

```bash
gh workflow run package-management.yml \
  -f action=validate-package \
  -f version="1.0.0"
```

### Cleanup Old Releases

```bash
gh workflow run package-management.yml \
  -f action=cleanup-old-releases \
  -f keep_releases="10"
```

## 🔧 Configuration

### Azure Credentials

Set up Azure Service Principal credentials in GitHub Secrets:

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-terraform-azure-policy" \
  --role "Policy Contributor" \
  --scopes "/subscriptions/your-subscription-id" \
  --sdk-auth

# Add the JSON output as AZURE_CREDENTIALS secret in GitHub
```

Required Azure permissions:

- **Policy Contributor** - Create and manage policy definitions
- **Resource Policy Contributor** - Assign policies to resources

### Environment Configuration

The deployment workflow supports multiple environments:

- **development** - Audit mode, development resource groups
- **staging** - Audit mode, staging resource groups  
- **production** - Deny mode, production resource groups

## 📋 Package Structure

Each versioned package contains:

```text
terraform-azure-policy-checkov-1.0.0.tar.gz
├── policies/                 # All policy definitions and configurations
├── modules/                  # Terraform modules
├── scripts/                  # PowerShell scripts
├── README.md                 # Project documentation
├── VERSION                   # Version file
├── requirements.psd1         # PowerShell requirements
├── package.yml              # Package configuration
```

## 🎯 Deployment Options

### Policy Effects

Control policy behavior across all policies:

- **Audit** - Log violations, allow resources (recommended for testing)
- **Deny** - Block non-compliant resources (recommended for production)
- **Disabled** - Disable policy evaluation

### Resource Group Targeting

Deploy policies to specific resource groups:

```bash
# Development environment
-f resource_group="rg-azure-policy-dev"
-f environment="development"
-f policy_effect="Audit"

# Production environment  
-f resource_group="rg-azure-policy-prod"
-f environment="production"
-f policy_effect="Deny"
```

### Subscription-wide Deployment

For subscription-wide policies, use subscription scope:

```bash
-f assignment_scope_id="/subscriptions/your-subscription-id"
```

## 🔍 Monitoring Deployments

### View Deployment Status

1. Go to **Actions** tab in GitHub
2. Select the **Deploy to Azure Resource Group** workflow
3. View deployment summary and Terraform outputs

### Terraform State Management

- Terraform state files are uploaded as artifacts for 30 days
- Download state files for troubleshooting or manual operations
- State files include all deployed policy definitions and assignments

### Rollback Procedures

To rollback a deployment:

1. Deploy a previous package version:

   ```bash
   gh workflow run deploy.yml -f version="1.0.0" # previous version
   ```

2. Or disable all policies:

   ```bash
   gh workflow run deploy.yml \
     -f version="current" \
     -f policy_effect="Disabled"
   ```

## 🚨 Troubleshooting

### Common Issues

1. **Package Not Found**
   - Verify the version exists: `gh workflow run package-management.yml -f action=list-releases`
   - Check release was created successfully

2. **Azure Authentication Failed**
   - Verify `AZURE_CREDENTIALS` secret is configured
   - Check service principal has required permissions

3. **Terraform Validation Failed**
   - Check subscription ID format
   - Verify resource group exists
   - Ensure Azure provider version compatibility

4. **Policy Assignment Failed**
   - Check resource group permissions
   - Verify subscription ID is correct
   - Review policy parameters

### Debug Mode

Enable detailed logging by adding debug parameters:

```bash
gh workflow run deploy.yml \
  -f version="1.0.0" \
  -f resource_group="rg-test" \
  -f subscription_id="your-sub-id" \
  -f environment="development" \
  -f dry_run="true"  # Plan only for debugging
```

## 📊 Best Practices

### Version Management

- Use **semantic versioning** (MAJOR.MINOR.PATCH)
- Create **patch releases** for bug fixes
- Create **minor releases** for new policies
- Create **major releases** for breaking changes

### Deployment Strategy

1. **Test in Development**

   ```bash
   gh workflow run deploy.yml \
     -f environment="development" \
     -f policy_effect="Audit" \
     -f dry_run="true"
   ```

2. **Validate in Staging**

   ```bash
   gh workflow run deploy.yml \
     -f environment="staging" \
     -f policy_effect="Audit"
   ```

3. **Deploy to Production**

   ```bash
   gh workflow run deploy.yml \
     -f environment="production" \
     -f policy_effect="Deny"
   ```

### Security Considerations

- Always use **Audit mode** for initial deployments
- Test policy effects in non-production environments
- Review policy exemptions before production deployment
- Monitor policy compliance after deployment

## 🔗 Related Documentation

- [Azure Policy Documentation](https://docs.microsoft.com/en-us/azure/governance/policy/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Checkov Security Rules](https://www.checkov.io/5.Policy%20Index/azure.html)
