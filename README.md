# Terraform Azure Policy Project

[![CI](https://github.com/stuartshay/terraform-azure-policy/actions/workflows/ci.yml/badge.svg)](https://github.com/stuartshay/terraform-azure-policy/actions/workflows/ci.yml)

A comprehensive Azure Policyframework using PowerShell, Terraform, and Pester for validating Azure governance policies.

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

## 📚 **Documentation**

- **[Pre-commit Guide](docs/PreCommit-Guide.md)** - Code quality and validation hooks
- **[Test Panel Guide](docs/TestPanel-Guide.md)** - VS Code Test Panel integration
- **[Testing Documentation](tests/README.md)** - Comprehensive testing guide

## 🎯 **Features**

- ✅ **Pre-commit Hooks** - Automatic code quality checks
- ✅ **Policy Validation** - JSON structure and logic validation
- ✅ **Integration Testing** - Real Azure resource compliance testing
- ✅ **VS Code Integration** - Test Panel and debugging support
- ✅ **Terraform Deployment** - Infrastructure as code for policies
- ✅ **Comprehensive Reporting** - Multiple output formats (JSON, CSV, HTML)

## 🛠️ **Development Workflow**

1. **Make changes** to policy definitions or tests
2. **Pre-commit hooks** automatically validate code quality
3. **Run quick tests** for immediate feedback
4. **Run integration tests** before commits
5. **Deploy via Terraform** to Azure environment

This project provides a complete framework for Azure Policy development with automated quality checks and comprehensive testing capabilities.
