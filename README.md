# Terraform Azure Policy Project

[![CI](https://github.com/stuartshay/terraform-azure-policy/actions/workflows/ci.yml/badge.svg)](https://github.com/stuartshay/terraform-azure-policy/actions/workflows/ci.yml)

A comprehensive Azure Policy framework using PowerShell, Terraform, and Pester for validating Azure governance policies. **The policies in this project are derived from Checkov security rules**, providing runtime enforcement of infrastructure security best practices.

## 🚀 **Quick Start**

### **1. Setup Pre-commit Hooks** (Recommended)

```bash
# Install and configure pre-commit hooks
./scripts/Setup-PreCommit.ps1
```

### **2. Install Requirements**

```powershell
# Install PowerShell modules and dependencies
./scripts/Install-Requirements.ps1 -IncludeOptional
```

### **3. Run Tests**

```bash
# Quick policy validation (no Azure auth required)
pre-commit run pester-tests-quick --all-files

# Full integration tests (requires Azure authentication)
./scripts/Invoke-PolicyTests.ps1 -TestPath "tests/storage"
```

### **4. Create & Deploy Versioned Package**

```bash
# Create a new release
gh workflow run release.yml -f version_type=patch

# Deploy to Azure Resource Group
gh workflow run deploy.yml \
  -f version="1.0.0" \
  -f resource_group="rg-azure-policy-prod" \
  -f subscription_id="your-subscription-id" \
  -f environment="production" \
  -f policy_effect="Deny"
```

## � **Checkov-Derived Security Policies**

This project implements Azure Policies based on [Checkov](https://www.checkov.io/) security rules, bridging the gap between static analysis and runtime enforcement:

- **Static Analysis (Checkov)** - Scans infrastructure code during CI/CD
- **Runtime Enforcement (Azure Policy)** - Prevents non-compliant resource creation in Azure
- **Comprehensive Coverage** - Policies align with Checkov's security best practices

### **Policy Categories**

| Category | Policies | Checkov Rules |
|----------|----------|---------------|
| **Storage** | 4 policies | CKV_AZURE_3, CKV_AZURE_190+ |
| **Network** | 2 policies | CKV_AZURE_9, CKV_AZURE_28+ |
| **Function App** | 2 policies | CKV_AZURE_70+ |
| **App Service** | 1 policy | CKV_AZURE_225 |

Each policy includes detailed documentation showing the corresponding Checkov rule alignment and implementation differences.

## 📚 **Documentation**

- **[Deployment Guide](docs/Deployment-Guide.md)** - 🚀 Versioned package deployment to Azure
- **[Pre-commit Guide](docs/PreCommit-Guide.md)** - Code quality and validation hooks
- **[Test Panel Guide](docs/TestPanel-Guide.md)** - VS Code Test Panel integration
- **[Testing Documentation](tests/README.md)** - Comprehensive testing guide

## 🎯 **Features**

- ✅ **Checkov-Derived Policies** - Security rules based on industry-standard static analysis
- ✅ **Versioned Package Releases** - Semantic versioning with GitHub releases
- ✅ **Automated Deployment** - GitHub Actions workflow for Azure Resource Group deployment
- ✅ **Pre-commit Hooks** - Automatic code quality checks
- ✅ **Policy Validation** - JSON structure and logic validation
- ✅ **Integration Testing** - Real Azure resource compliance testing
- ✅ **VS Code Integration** - Test Panel and debugging support
- ✅ **Terraform Deployment** - Infrastructure as code for policies
- ✅ **Comprehensive Reporting** - Multiple output formats (JSON, CSV, HTML)
- ✅ **Runtime Enforcement** - Prevent non-compliant resource creation in Azure

## 🛠️ **Development Workflow**

1. **Identify Checkov rule** to implement as Azure Policy
2. **Create policy definition** aligned with Checkov's security logic
3. **Make changes** to policy definitions or tests
4. **Pre-commit hooks** automatically validate code quality
5. **Run quick tests** for immediate feedback
6. **Run integration tests** before commits
7. **Deploy via Terraform** to Azure environment

## 🌟 **Why Checkov + Azure Policy?**

| Approach | Checkov (Static) | Azure Policy (Runtime) | Combined Benefit |
|----------|------------------|------------------------|------------------|
| **Coverage** | Pre-deployment scanning | Post-deployment enforcement | Complete lifecycle security |
| **Speed** | Fast CI/CD feedback | Real-time blocking | Shift-left + runtime protection |
| **Scope** | Infrastructure code | All Azure resources | Comprehensive governance |

This project provides a complete framework for Azure Policy development with automated quality checks, comprehensive testing capabilities, and alignment with Checkov's proven security rules.
