# GitHub Copilot Instructions for Terraform Azure Policy Project

This document provides GitHub Copilot with context-specific instructions for working with this repository.

## 🎯 Project Overview

This is an Azure Policy framework using PowerShell, Terraform, and Pester for validating Azure governance policies. Policies are derived from Checkov security rules, providing runtime enforcement of infrastructure security best practices.

## 🔧 Technology Stack

- **Languages**: PowerShell 7.0+, Terraform (HCL)
- **Testing**: Pester 5.x for PowerShell unit/integration tests
- **Infrastructure**: Azure Resource Manager, Terraform Cloud
- **Quality Tools**: PSScriptAnalyzer, TFLint, pre-commit hooks
- **Documentation**: Markdown with strict linting rules

## ⚠️ Critical Requirements

### Pre-commit Validation (MANDATORY)

**Before all changes are completed, always run pre-commit to check and validate:**

```bash
# Install pre-commit hooks (first time only)
./scripts/Setup-PreCommit.ps1

# Run all pre-commit checks
pre-commit run --all-files

# Or let them run automatically on commit
git add .
git commit -m "type: description"
```

**Never skip pre-commit checks unless absolutely necessary.** The hooks enforce:
- Code formatting and syntax validation
- Security scanning (secrets detection)
- Test execution
- Documentation standards
- Conventional commit message format

### Environment Configuration

Before running tests or making Azure-related changes:

```powershell
# Validate GitHub Copilot environment configuration
./scripts/Validate-GitHubCopilotEnvironment.ps1

# Required environment variables:
# - ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
# - TF_API_TOKEN, TF_CLOUD_ORGANIZATION (optional)
```

See [GitHub Copilot Environment Validation Guide](../docs/GitHub-Copilot-Environment-Validation.md).

## 📝 Code Standards

### PowerShell

- Use PowerShell 7.0+ syntax
- Follow [PowerShell Best Practices](https://poshcode.gitbook.io/powershell-practice-and-style/)
- Use approved verbs for function names (`Get-`, `Set-`, `Test-`, etc.)
- Include comment-based help for all functions
- Use proper error handling with `try/catch` blocks
- Variables should use `$PascalCase` for parameters, `$camelCase` for local variables

### Terraform

- Use Terraform 1.0+ syntax
- Follow HashiCorp style guide
- Run `terraform fmt` before committing
- Validate with `terraform validate` and `tflint`
- Document modules with `terraform-docs`

### Testing

- **Unit tests**: Use Pester 5.x with `.Tests.ps1` suffix
- **Integration tests**: Mark with appropriate tags (`[Tag('Integration')]`)
- **Quick validation**: Fast tests for pre-commit hooks
- Target coverage: 75% unit, 80% integration, 85% for releases

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
type(scope): brief description

[optional body]
[optional footer]
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `ci`, `perf`

## 🏗️ Repository Structure

```
.
├── .devcontainer/        # Dev container configuration
├── .github/              # GitHub Actions workflows and configs
├── docs/                 # Comprehensive documentation
├── policies/             # Azure Policy definitions by category
│   ├── network/
│   ├── storage/
│   ├── app-service/
│   └── function-app/
├── scripts/              # PowerShell automation scripts
├── tests/                # Pester test suites
├── modules/              # Terraform modules
└── initiatives/          # Azure Policy Initiatives
```

## 🔄 Common Workflows

### Development Workflow

1. **Setup environment**:
   ```powershell
   ./scripts/Install-Requirements.ps1 -IncludeOptional
   ./scripts/Setup-PreCommit.ps1
   ```

2. **Validate changes**:
   ```powershell
   ./scripts/Validate-PolicyDefinitions.ps1 -PolicyPath ./policies
   ```

3. **Run tests**:
   ```powershell
   # Quick validation
   ./scripts/Invoke-PolicyTests.ps1 -Tag 'Quick'
   
   # Full test suite
   ./scripts/Invoke-PolicyTests.ps1 -TestPath ./tests
   ```

4. **Pre-commit validation** (REQUIRED):
   ```bash
   pre-commit run --all-files
   ```

### CI/CD Integration

- GitHub Actions workflows in `.github/workflows/`
- `ci.yml`: Runs on PRs and commits
- `deploy.yml`: Deploys to Azure environments
- `release.yml`: Creates versioned releases
- `package-management.yml`: Manages Azure Policy packages

## 📚 Key Documentation

When making changes, refer to these documents:

- **[Pre-commit Guide](../docs/PreCommit-Guide.md)** - Code quality hooks (CRITICAL)
- **[DevContainer Setup](../docs/DevContainer-PreCommit-Setup.md)** - Automated setup
- **[Testing Documentation](../tests/README.md)** - Comprehensive testing guide
- **[Deployment Guide](../docs/Deployment-Guide.md)** - Azure deployment process
- **[Scripts README](../scripts/README.md)** - Script documentation
- **[GitHub Copilot Environment Validation](../docs/GitHub-Copilot-Environment-Validation.md)** - Environment setup

## 🚨 Important Constraints

1. **Always validate environment** before Azure operations
2. **Run pre-commit hooks** before finalizing changes (MANDATORY)
3. **Follow naming conventions**: `.Tests.ps1` for test files
4. **Keep policy files under 50KB**
5. **Use LF line endings** (enforced by pre-commit)
6. **No hardcoded secrets** (detected by pre-commit)
7. **Conventional commits required** (enforced by commitizen hook)

## 🔍 Troubleshooting

### Pre-commit Issues

```powershell
# Reinstall hooks
pre-commit clean
pre-commit install

# Update hook versions
pre-commit autoupdate

# Skip specific hooks (use sparingly)
SKIP=pester-tests-quick git commit -m "fix: urgent fix"
```

### Environment Issues

```powershell
# Validate environment
./scripts/Validate-GitHubCopilotEnvironment.ps1

# Check Azure connectivity
./scripts/Connect-AzureServicePrincipal.ps1
```

### Module Issues

```powershell
# Reinstall PowerShell modules
./scripts/Install-Requirements.ps1 -Force -IncludeOptional
```

## 💡 Best Practices for Copilot

1. **Always check existing patterns** in the repository before creating new code
2. **Reference documentation** links when suggesting solutions
3. **Run validation scripts** before suggesting code is complete
4. **Suggest pre-commit execution** as part of any code change workflow
5. **Recommend tests** alongside code changes
6. **Follow established conventions** for file naming and structure
7. **Consider Azure-specific constraints** when generating policy code

## 🔗 Quick Reference Commands

```powershell
# Setup
./scripts/Install-Requirements.ps1 -IncludeOptional
./scripts/Setup-PreCommit.ps1

# Validation
./scripts/Validate-GitHubCopilotEnvironment.ps1
./scripts/Validate-PolicyDefinitions.ps1 -PolicyPath ./policies

# Testing
./scripts/Invoke-PolicyTests.ps1 -Tag 'Quick'
./scripts/Invoke-PolicyTests-WithCoverage.ps1 -GenerateHtmlReport

# Pre-commit (REQUIRED)
pre-commit run --all-files
pre-commit run trailing-whitespace --all-files

# Azure
./scripts/Connect-AzureServicePrincipal.ps1
./scripts/Run-StorageTest.ps1
```

---

**Remember**: Always run `pre-commit run --all-files` before considering any changes complete!
