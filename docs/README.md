# Azure Policy Testing Documentation

This directory contains comprehensive documentation for the Azure Policy Testing project.

## 📚 **Documentation Files**

### **[TestPanel-Guide.md](TestPanel-Guide.md)**

Complete guide for using VS Code Test Panel with Pester tests:

- Setting up the Pester Test extension
- Running tests through the Test Panel interface
- Debugging tests with breakpoints
- Test categorization and filtering
- CI/CD integration and reporting

## 🚀 **Quick Start**

1. **Install the Pester Test extension**: `pspester.pester-test`
2. **Open Test Panel**: `View` → `Testing` or `Ctrl+Shift+P` → "Test: Focus on Test Explorer View"
3. **Run fast tests**: Click ▶️ next to `Quick-PolicyValidation.Tests.ps1`
4. **Run integration tests**: Click ▶️ next to `Deny-StorageAccountPublicAccess.Tests.ps1` (requires Azure auth)

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
