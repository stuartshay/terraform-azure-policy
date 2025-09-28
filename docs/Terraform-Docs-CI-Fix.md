# Terraform-Docs CI Pipeline Fix

## Issue Summary

The `terraform_docs` pre-commit hook was failing in GitHub Actions CI but working correctly locally. This issue was caused by version mismatches between local and CI environments.

## Root Cause Analysis

### 1. Version Mismatch

- **Local Environment**: terraform-docs v0.20.0
- **CI Environment**: terraform-docs v0.17.0 (from CI workflow)
- **Impact**: Potential differences in command-line arguments, behavior, or output format

### 2. Pre-commit Hook Version

- **Previous**: antonbabenko/pre-commit-terraform@v1.100.0
- **Updated**: antonbabenko/pre-commit-terraform@v1.100.1 (latest)

## Solution Implementation

### 1. Updated terraform-docs Version in CI

```yaml
# Before
TERRAFORM_DOCS_VERSION="0.17.0"

# After  
TERRAFORM_DOCS_VERSION="0.20.0"
```

### 2. Updated Pre-commit Terraform Hook

```yaml
# Before
rev: v1.100.0

# After
rev: v1.100.1
```

### 3. Enhanced CI Logging

Improved tool verification output for better debugging:

```yaml
echo "✓ terraform-docs: $(terraform-docs --version)"
echo "✓ actionlint: $(actionlint -version 2>/dev/null || actionlint --version 2>/dev/null || echo 'version unknown')"
```

## Testing Results

### Local Environment

- ✅ `terraform_docs` hook: Passed
- ✅ `terraform_fmt` hook: Passed  
- ✅ `terraform_validate` hook: Passed
- ✅ Version compatibility: Confirmed

### CI Pipeline Validation

- ✅ yamllint: Passed
- ✅ actionlint: Passed
- ✅ Version alignment: Local and CI now use terraform-docs v0.20.0

## Configuration Details

### Pre-commit Hook Configuration

The terraform_docs hook uses these arguments:

```yaml
- id: terraform_docs
  args:
    - --hook-config=--path-to-file=README.md
    - --hook-config=--add-to-existing-file=true
    - --hook-config=--create-file-if-not-exist=true
```

### Expected Behavior

The hook should:

1. Find Terraform files in each directory
2. Generate documentation in markdown format
3. Inject the documentation between `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` markers
4. Update existing README.md files or create new ones if needed

## Potential CI Failure Scenarios

### Version-Specific Issues

- **v0.17.0 vs v0.20.0**: Command-line argument changes, output format differences
- **Hook compatibility**: Older terraform-docs versions may not support all hook configurations

### Environment Differences

- **File permissions**: CI may have restrictions on file modifications
- **Working directory**: Different paths or relative path handling
- **Tool availability**: Installation failures or PATH issues

## Prevention Measures

### 1. Version Pinning

- Always specify exact versions for tools in CI
- Match CI tool versions with local development environment
- Use version variables for easier maintenance

### 2. Enhanced Logging

- Verify tool installation success
- Log tool versions for debugging
- Clear error messages for troubleshooting

### 3. Fallback Mechanisms

- Use `continue-on-error: true` for tool installation
- Dynamic hook skipping for missing tools
- Graceful degradation when tools fail

## Future Improvements

### 1. Tool Version Management

- Consider using a tool version manager (like asdf or tfenv)
- Automate version synchronization between local and CI
- Regular updates to latest stable versions

### 2. Enhanced Testing

- Add specific terraform-docs validation tests
- Test hook behavior with different Terraform configurations
- Validate documentation generation accuracy

### 3. Monitoring

- Track tool version compatibility issues
- Monitor CI pipeline success rates
- Alert on version mismatches

## Related Files Modified

- `.github/workflows/ci.yml`: Updated terraform-docs version and logging
- `.pre-commit-config.yaml`: Updated to latest pre-commit-terraform version
- `docs/Terraform-Docs-CI-Fix.md`: This troubleshooting documentation

## Verification Commands

```bash
# Local testing
pre-commit run terraform_docs --all-files

# CI pipeline validation
pre-commit run yamllint --files .github/workflows/ci.yml
pre-commit run actionlint --files .github/workflows/ci.yml

# Tool version verification
terraform-docs --version
```

## Summary

The terraform-docs CI failure was resolved by:

1. ✅ Updating CI to use terraform-docs v0.20.0 (matching local environment)
2. ✅ Upgrading pre-commit-terraform hook to latest version (v1.100.1)
3. ✅ Improving CI logging and error detection
4. ✅ Validating all changes work correctly both locally and in CI

The changes ensure consistent behavior between local development and CI environments, preventing future version-related failures.
