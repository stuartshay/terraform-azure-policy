# Pre-Commit Setup in DevContainer

## Overview

Pre-commit hooks are now automatically installed when the devcontainer is built. This ensures code quality checks run before every commit.

## What's Included

### Automatic Installation

The `.devcontainer/setup.sh` script now installs:

1. **Python packages:**
   - `pre-commit` - Git hook framework
   - `commitizen` - Conventional commit message formatting
   - `detect-secrets` - Secret scanning

2. **Git hooks:**
   - `pre-commit` hook - Runs before each commit
   - `commit-msg` hook - Validates commit message format

3. **PowerShell modules:**
   - `Pester` 5.4.0 - Testing framework
   - `PSScriptAnalyzer` 1.21.0 - Code analysis
   - `Az.Storage` 6.0.0 - Azure storage (for integration tests)
   - All other Az modules for Azure integration

4. **Terraform tools:**
   - `terraform-docs` - Automatic documentation generation for Terraform modules

## Pre-Commit Hooks Configuration

The `.pre-commit-config.yaml` file includes comprehensive checks:

### File Quality Checks

- Trailing whitespace removal
- End-of-file fixer
- Mixed line ending normalization
- Large file detection
- Merge conflict detection
- Private key detection

### PowerShell Checks

- Syntax validation
- Whitespace cleanup
- PSScriptAnalyzer (critical issues only)
- Unit test execution

### Terraform Checks

- `terraform fmt` - Formatting
- `terraform validate` - Validation
- `terraform docs` - Automatic README documentation
- `terraform tflint` - Linting

### Markdown & YAML

- Markdownlint - Markdown formatting
- Yamllint - YAML validation

### Security

- `detect-secrets` - Scan for hardcoded secrets
- Azure Policy JSON validation

### GitHub Actions

- `actionlint` - GitHub workflow validation

### Commit Messages

- `commitizen` - Enforces conventional commit format

## Usage

### Automatic (Recommended)

Hooks run automatically on every commit:

```bash
git add .
git commit -m "feat: add new feature"
# Pre-commit hooks run automatically
```

### Manual Execution

Run all hooks on all files:

```bash
pre-commit run --all-files
```

Run specific hook:

```bash
pre-commit run trailing-whitespace --all-files
pre-commit run powershell-syntax-check --all-files
pre-commit run pester-tests-unit --all-files
```

### Skip Hooks (Use Sparingly)

Skip all hooks for a commit:

```bash
git commit -m "fix: urgent fix" --no-verify
```

Skip specific hooks:

```bash
SKIP=pester-tests-unit,terraform_tflint git commit -m "fix: quick fix"
```

## Verification

After container rebuild, verify pre-commit is installed:

```bash
# Check pre-commit version
pre-commit --version

# Check installed hooks
ls -la .git/hooks/

# Verify hook configuration
pre-commit run --all-files --verbose
```

## Troubleshooting

### Pre-commit not found

If pre-commit isn't in PATH after container rebuild:

```bash
pip3 install --user pre-commit
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg
```

### Hooks not running

Reinstall hooks:

```bash
pre-commit uninstall
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg
```

### Hook failures

View detailed error messages:

```bash
pre-commit run --all-files --verbose
```

Update hook environments:

```bash
pre-commit clean
pre-commit install --install-hooks
```

### PowerShell hooks failing

Ensure modules are installed:

```bash
pwsh -Command "Get-Module -ListAvailable Pester, PSScriptAnalyzer, Az.Storage"
```

If missing, run:

```bash
./scripts/Install-Requirements.ps1
```

## DevContainer Rebuild

When you rebuild the container, everything installs automatically:

1. **Container starts** → `.devcontainer/setup.sh` runs
2. **Python packages installed** → pre-commit, commitizen, detect-secrets
3. **PowerShell modules installed** → Pester, PSScriptAnalyzer, Az modules
4. **Git hooks installed** → pre-commit and commit-msg hooks
5. **Hook environments initialized** → All hook dependencies cached

## CI/CD Integration

The pre-commit configuration includes CI-specific settings:

```yaml
ci:
  skip: [
    powershell-syntax-check,
    powershell-script-analyzer,
    pester-tests-unit,
    terraform_tflint,
  ]
```

These resource-intensive hooks are skipped in automated CI environments.

## Hook Customization

To modify hooks, edit `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
```

After changes, update hooks:

```bash
pre-commit install --install-hooks
```

## Performance Tips

### Fast Commits

Most hooks are lightweight and run in seconds. Heavy hooks (Terraform, Pester tests) are skipped in CI.

### Parallel Execution

Pre-commit runs hooks in parallel when possible, speeding up execution.

### Cached Environments

Hook dependencies are cached in `.pre-commit-cache/`, so subsequent runs are faster.

## Best Practices

1. **Commit Often** - Smaller commits pass hooks faster
2. **Run Manually** - Test with `pre-commit run --all-files` before committing
3. **Keep Updated** - Run `pre-commit autoupdate` periodically
4. **Skip Rarely** - Only use `--no-verify` for urgent fixes
5. **Fix Issues** - Don't skip hooks to bypass quality checks

## Additional Resources

- [Pre-commit Documentation](https://pre-commit.com/)
- [Commitizen Guide](https://commitizen-tools.github.io/commitizen/)
- [Project Pre-Commit Guide](PreCommit-Guide.md)
- [DevContainer Setup](../DEVCONTAINER-SETUP.md)

## Summary

✅ **Automatic Installation** - Everything installs when container builds
✅ **Git Hooks** - pre-commit and commit-msg hooks configured
✅ **Quality Checks** - Comprehensive code quality validation
✅ **Security Scanning** - Detect secrets and vulnerabilities
✅ **CI/CD Ready** - Optimized for automated environments

**Pre-commit ensures code quality at every commit!** 🚀
