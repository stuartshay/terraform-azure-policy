# Azure Policy Testing Documentation

This directory contains comprehensive documentation for the Azure Policy Testing project.

## 📚 **Documentation Files**

### **Development Environment**

#### **[DevContainer-Quick-Reference.md](DevContainer-Quick-Reference.md)**

Quick reference for working with the development container:

- Container management commands
- Azure authentication
- Troubleshooting common issues
- Environment variables
- GitHub Codespaces tips

See [../.devcontainer/README.md](../.devcontainer/README.md) for complete setup instructions.

#### **[AZURE-AUTH-QUICK-START.md](AZURE-AUTH-QUICK-START.md)**

Quick 3-step guide for authenticating with Azure to run integration tests:

- Azure CLI login
- Subscription setup
- Resource group verification
- Running integration tests

#### **[AZURE-CONNECTION-PERSISTENCE-FIX.md](AZURE-CONNECTION-PERSISTENCE-FIX.md)**

Complete guide for fixing Azure connection persistence in devcontainers:

- Why connections don't persist
- Automated and manual fix methods
- Troubleshooting connection issues
- Understanding Azure CLI vs PowerShell Az modules

#### **[DEVCONTAINER-TESTING-FIX.md](DEVCONTAINER-TESTING-FIX.md)**

Comprehensive troubleshooting guide for test setup in devcontainers:

- Installing missing PowerShell modules
- VS Code settings configuration
- Verification steps
- Common issues and solutions

#### **[DEVCONTAINER-TEST-FIX-SUMMARY.md](DEVCONTAINER-TEST-FIX-SUMMARY.md)**

Quick reference summary for devcontainer test setup:

- One-liner commands
- Essential steps
- Quick verification

#### **[DevContainer-PreCommit-Setup.md](DevContainer-PreCommit-Setup.md)**

Complete guide for pre-commit hooks automatically installed in devcontainer:

- Automatic installation process
- Available hooks (PowerShell, Terraform, Markdown, YAML, Security)
- Usage and manual execution
- Troubleshooting and customization
- Best practices

#### **[PreCommit-Guide.md](PreCommit-Guide.md)**

Comprehensive pre-commit hooks documentation:

- Hook configuration and setup
- Available hooks and what they check
- Customizing hook behavior
- CI/CD integration

#### **[Secrets-Baseline-Management.md](Secrets-Baseline-Management.md)**

Managing detect-secrets baseline for false positive handling:

- Understanding the secrets baseline
- Adding and updating false positives
- Auditing and troubleshooting
- Best practices for secret management

### **Testing Documentation**

### **Testing & Quality**

#### **[TestPanel-Guide.md](TestPanel-Guide.md)**

Complete guide for using VS Code Test Panel with Pester tests:

- Setting up the Pester Test extension
- Running tests through the Test Panel interface
- Debugging tests with breakpoints
- Test categorization and filtering
- CI/CD integration and reporting

## 🚀 **Quick Start**

### **Setup Development Environment**

1. **Use Dev Container** (Recommended): Open in VS Code → "Reopen in Container"
   - See [../.devcontainer/README.md](../.devcontainer/README.md)
   - Or use GitHub Codespaces for instant setup

2. **Local Setup**: Follow [../README.md](../README.md) for manual installation

### **Run Tests**

1. **Install the Pester Test extension**: `pspester.pester-test`
2. **Open Test Panel**: `View` → `Testing` or `Ctrl+Shift+P` → "Test: Focus on Test Explorer View"
3. **Run fast tests**: Click ▶️ next to `Storage.Unit-DenyStorageAccountPublicAccess.Tests.ps1`
4. **Run integration tests**: Click ▶️ next to `Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1` (requires Azure auth)

## 🎯 **Test Categories**

- **🚀 Fast Tests** (`Unit`, `Fast`) - JSON validation, no Azure required
- **🔗 Integration Tests** (`Integration`) - Real Azure policy testing
- **🐌 Slow Tests** (`Slow`) - Resource creation and cleanup

## 📖 **Additional Resources**

- **[../tests/README.md](../tests/README.md)** - Complete testing documentation
- **[../README.md](../README.md)** - Project overview and setup
- **VS Code Extensions**: See `.vscode/extensions.json` for recommended extensions

## 🛠️ **Configuration Files**

The project includes several configuration files for optimal Test Panel experience:

- **`.vscode/settings.json`** - VS Code and Pester extension configuration
- **`.vscode/launch.json`** - Debug configurations for tests

## 🎮 **Using the Test Panel**

The VS Code Test Panel provides a visual interface for:

- **Viewing all tests** in a hierarchical tree
- **Running individual tests** or test groups with one click
- **Debugging tests** with full breakpoint support
- **Viewing results** with detailed error information
- **Generating reports** in multiple formats

Perfect for Azure Policy development and validation! 🎉
