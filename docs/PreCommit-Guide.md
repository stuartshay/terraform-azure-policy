# Pre-commit Hooks Configuration

This document explains the pre-commit hooks setup for the Azure Policy Testing project, which helps maintain code quality and consistency across all commits.

## 🎯 **Overview**

Pre-commit hooks automatically run checks before each commit to:

- **Validate code syntax** and formatting
- **Check Azure Policy JSON** structure
- **Run quick tests** to catch issues early
- **Format code consistently** across the project
- **Scan for security issues** and secrets
- **Maintain documentation** standards

## 🚀 **Quick Setup**

### **1. Install Pre-commit**

```bash
# Using the setup script (recommended)
./scripts/Setup-PreCommit.ps1

# Or manually
pip install pre-commit
pre-commit install
```

### **2. VS Code Task (Alternative)**

- Open Command Palette (`Ctrl+Shift+P`)
- Run "Tasks: Run Task" → "Setup Pre-commit Hooks"

### **3. Test the Setup**

```bash
# Run all hooks manually
pre-commit run --all-files

# Make a test commit
git add .
git commit -m "test: testing pre-commit hooks"
```

## 🔍 **Configured Hooks**

### **📝 General File Checks**

- **trailing-whitespace** - Removes trailing spaces
- **end-of-file-fixer** - Ensures files end with newline
- **check-yaml** - Validates YAML syntax
- **check-json** - Validates JSON files (excludes VS Code configs)
- **check-added-large-files** - Prevents large files (>1MB)
- **detect-private-key** - Scans for private keys
- **mixed-line-ending** - Enforces LF line endings

### **💻 PowerShell Hooks**

- **powershell-syntax-check** - Validates PowerShell syntax
- **powershell-script-analyzer** - Runs PSScriptAnalyzer for code quality
- **pester-tests-quick** - Runs fast policy validation tests

### **🏗️ Terraform Hooks**

- **terraform_fmt** - Formats Terraform files
- **terraform_validate** - Validates Terraform configuration
- **terraform_docs** - Updates Terraform documentation
- **terraform_tflint** - Lints Terraform files for best practices

### **📚 Documentation Hooks**

- **markdownlint** - Formats and validates Markdown files
- **yamllint** - Validates YAML files

### **🔒 Security Hooks**

- **detect-secrets** - Scans for hardcoded secrets and credentials
- **commitizen** - Enforces conventional commit message format

### **🎯 Azure Policy Specific Hooks**

- **azure-policy-validation** - Validates Azure Policy JSON structure
- **terraform-policy-syntax** - Checks Terraform policy configurations
- **check-large-policy-files** - Ensures policy files aren't too large (>50KB)
- **check-test-file-naming** - Enforces `.Tests.ps1` naming convention

## 📋 **Hook Execution Order**

### **Fast Hooks** (run on every commit)

1. File formatting and syntax checks
2. PowerShell syntax validation
3. JSON/YAML validation
4. Azure Policy structure validation

### **Slower Hooks** (run as needed)

1. PSScriptAnalyzer code quality checks
2. Quick Pester tests (policy validation)
3. Terraform validation and linting
4. Security scanning

### **Skipped in CI** (resource intensive)

- PSScriptAnalyzer (runs locally only)
- Pester tests (runs locally only)
- TFLint (runs locally only)

## 🎮 **Usage Examples**

### **Normal Git Workflow**

```bash
# Make your changes
git add .

# Commit - hooks run automatically
git commit -m "feat: add new storage policy"

# If hooks fail, fix issues and retry
git add .
git commit -m "feat: add new storage policy"
```

### **Skip Hooks (Emergency)**

```bash
# Skip all hooks (not recommended)
git commit --no-verify -m "emergency fix"
```

### **Run Specific Hooks**

```bash
# Run only PowerShell checks
pre-commit run powershell-syntax-check --all-files

# Run only policy validation
pre-commit run azure-policy-validation --all-files

# Run only formatting hooks
pre-commit run trailing-whitespace end-of-file-fixer --all-files
```

### **Manual Hook Management**

```bash
# Update hook versions
pre-commit autoupdate

# Clear hook cache
pre-commit clean

# Uninstall hooks
pre-commit uninstall
```

## 🛠️ **VS Code Integration**

### **Available Tasks**

- **"Setup Pre-commit Hooks"** - Install and configure pre-commit
- **"Run Pre-commit Hooks"** - Run all hooks manually
- **"Update Pre-commit Hooks"** - Update hook versions

### **Running Tasks**

1. `Ctrl+Shift+P` → "Tasks: Run Task"
2. Select the desired pre-commit task
3. View results in the integrated terminal

## ⚙️ **Configuration Files**

### **`.pre-commit-config.yaml`**

Main configuration file defining all hooks and their settings.

### **`.secrets.baseline`**

Baseline file for detect-secrets to avoid false positives.

### **Hook-specific Configurations**

- **PSScriptAnalyzer**: Uses `.vscode/PSScriptAnalyzerSettings.psd1`
- **Markdownlint**: Auto-fixes common formatting issues
- **Terraform**: Uses standard formatting and validation
- **Pester**: Runs quick validation tests only

## 🚨 **Troubleshooting**

### **Common Issues**

#### **"pre-commit command not found"**

```bash
# Install pre-commit
pip install pre-commit

# Or use the setup script
./scripts/Setup-PreCommit.ps1
```

#### **Python not found**

- Install Python 3.8+ from python.org
- Ensure Python is in your PATH

#### **PSScriptAnalyzer missing**

```powershell
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
```

#### **Pester module missing**

```powershell
Install-Module -Name Pester -Scope CurrentUser -Force
```

#### **Terraform hooks failing**

- Install Terraform from terraform.io
- Ensure `terraform` command is in PATH

#### **Hook taking too long**

```bash
# Skip slow hooks temporarily
SKIP=terraform_tflint,powershell-script-analyzer git commit -m "message"
```

### **Performance Issues**

#### **Slow Commits**

- Consider disabling resource-intensive hooks locally
- Use `SKIP` environment variable for specific hooks
- Run full validation only before push

#### **Skip Hooks Selectively**

```bash
# Skip only slow hooks
SKIP=terraform_tflint,pester-tests-quick git commit -m "quick fix"

# Skip all PowerShell hooks
SKIP=powershell-script-analyzer,powershell-syntax-check git commit -m "docs update"
```

## 📊 **Hook Performance**

### **Fast Hooks** (< 5 seconds)

- File formatting checks
- JSON/YAML validation
- Policy structure validation
- Basic syntax checks

### **Medium Hooks** (5-30 seconds)

- PSScriptAnalyzer (depends on file count)
- Terraform validation
- Markdown linting

### **Slow Hooks** (30+ seconds)

- Pester tests (even quick ones)
- Terraform linting with all rules
- Complete security scanning

## 🎯 **Best Practices**

### **Development Workflow**

1. **Make small, focused commits** - hooks run faster
2. **Run hooks manually** during development: `pre-commit run --all-files`
3. **Fix issues incrementally** rather than all at once
4. **Use meaningful commit messages** - commitizen hook will check format

### **Hook Management**

1. **Update hooks regularly**: `pre-commit autoupdate`
2. **Test hook changes** before committing the config
3. **Document any hook skips** in commit messages
4. **Review hook output** for important warnings

### **Team Collaboration**

1. **All team members** should run `./scripts/Setup-PreCommit.ps1`
2. **Consistent tooling** - same versions of PowerShell, Python, etc.
3. **Communicate hook changes** when updating `.pre-commit-config.yaml`
4. **Share hook bypass reasons** when using `--no-verify`

## 📚 **Additional Resources**

- **Pre-commit Documentation**: <https://pre-commit.com/>
- **Hook Repository**: <https://github.com/pre-commit/pre-commit-hooks>
- **Terraform Hooks**: <https://github.com/antonbabenko/pre-commit-terraform>
- **PSScriptAnalyzer Rules**: <https://github.com/PowerShell/PSScriptAnalyzer>
- **Conventional Commits**: <https://www.conventionalcommits.org/>

## 🎉 **Benefits**

With pre-commit hooks configured, you get:

- ✅ **Consistent code formatting** across the team
- ✅ **Early error detection** before code review
- ✅ **Automated policy validation** for Azure policies
- ✅ **Security scanning** for secrets and credentials
- ✅ **Documentation maintenance** through auto-formatting
- ✅ **Faster code reviews** with pre-validated code
- ✅ **Reduced CI/CD failures** by catching issues early

Your Azure Policy development workflow is now enhanced with automatic quality checks! 🚀
