# Secrets Baseline Management

## Overview

This project uses `detect-secrets` to scan for hardcoded secrets in the codebase. The `.secrets.baseline` file contains approved "secrets" that are actually false positives (like base64-encoded policy names, documentation examples, etc.).

## What is detect-secrets?

`detect-secrets` is a security tool that scans code for potential secrets like:

- API keys
- Passwords
- Private keys
- AWS keys
- Azure storage keys
- JWT tokens
- And many more...

## The Baseline File

The `.secrets.baseline` file stores **approved findings** that are not actual secrets. This prevents false positives from blocking commits.

Current baseline: **10,415 lines** with approved false positives

### What's in the Baseline?

Common false positives in this project include:

- **Azure Policy IDs** - Base64-encoded policy definition IDs
- **Terraform variable examples** - Sample values in documentation
- **GitHub Action workflow syntax** - Action names that look like secrets
- **Configuration examples** - Sample JSON/YAML configurations
- **Resource IDs** - Azure resource identifiers
- **Documentation snippets** - Code examples in README files

## Managing the Baseline

### Update Baseline (Add New False Positives)

When you add new code that triggers false positives:

```bash
# Scan and update the baseline
~/.local/bin/detect-secrets scan --baseline .secrets.baseline \
    --exclude-files '\.git/.*' \
    --exclude-files 'node_modules/.*' \
    --exclude-files '\.vscode/.*' \
    --exclude-files 'reports/.*\.html$'

# Stage the updated baseline
git add .secrets.baseline

# Verify the hook passes
pre-commit run detect-secrets --all-files
```

### Regenerate Baseline from Scratch

If the baseline becomes corrupted or you want to start fresh:

```bash
# Delete existing baseline
rm .secrets.baseline

# Create new baseline
~/.local/bin/detect-secrets scan --baseline .secrets.baseline \
    --exclude-files '\.git/.*' \
    --exclude-files 'node_modules/.*' \
    --exclude-files '\.vscode/.*' \
    --exclude-files 'reports/.*\.html$'

# Review the baseline
cat .secrets.baseline | jq '.results | keys'

# Stage and commit
git add .secrets.baseline
git commit -m "chore: regenerate secrets baseline"
```

### Audit Baseline Entries

Review what's in the baseline:

```bash
# Count total findings
cat .secrets.baseline | jq '.results | length'

# List files with findings
cat .secrets.baseline | jq -r '.results | keys[]' | sort

# View findings for specific file
cat .secrets.baseline | jq '.results["path/to/file.ext"]'

# Count findings by type
cat .secrets.baseline | jq -r '.results[] | .[] | .type' | sort | uniq -c | sort -rn
```

### Remove File from Baseline

If you delete a file, remove it from the baseline:

```bash
# Edit baseline and remove the file entry
# Or regenerate the entire baseline (recommended)
~/.local/bin/detect-secrets scan --baseline .secrets.baseline
```

## Pre-commit Hook Configuration

The `.pre-commit-config.yaml` includes:

```yaml
- repo: https://github.com/Yelp/detect-secrets
  rev: v1.5.0
  hooks:
    - id: detect-secrets
      args:
        - '--baseline'
        - '.secrets.baseline'
        - '--base64-limit'
        - '3.0'
        - '--hex-limit'
        - '2.5'
```

### Arguments Explained

- `--baseline .secrets.baseline` - Use the baseline file to ignore known false positives
- `--base64-limit 3.0` - Base64 entropy threshold (lower = more sensitive)
- `--hex-limit 2.5` - Hexadecimal entropy threshold (lower = more sensitive)

### Adjusting Sensitivity

If too many false positives:

```yaml
args:
  - '--base64-limit'
  - '4.5'  # Increase from 3.0
  - '--hex-limit'
  - '3.5'  # Increase from 2.5
```

If missing real secrets:

```yaml
args:
  - '--base64-limit'
  - '2.5'  # Decrease from 3.0
  - '--hex-limit'
  - '2.0'  # Decrease from 2.5
```

## Excluding Files

Update `.pre-commit-config.yaml` to exclude additional paths:

```yaml
filters_used:
  - path: detect_secrets.filters.regex.should_exclude_file
    pattern:
      - '\.git/.*'
      - 'node_modules/.*'
      - '\.vscode/.*'
      - 'reports/.*\.html$'
      - 'tests/.*\.xml$'  # Add new exclusion
```

Or use `--exclude-files` when scanning:

```bash
detect-secrets scan --baseline .secrets.baseline \
    --exclude-files 'tests/.*\.xml$'
```

## Common Issues

### Hook Fails: "Your baseline file is unstaged"

**Problem:** The `.secrets.baseline` file was modified but not staged.

**Solution:**

```bash
git add .secrets.baseline
```

### Hook Fails: New Secrets Detected

**Problem:** New code contains potential secrets.

**Options:**

1. **Remove the secret** (if it's a real secret):

   ```bash
   # Never commit real secrets!
   # Remove from code and use environment variables
   ```

2. **Add to baseline** (if it's a false positive):

   ```bash
   detect-secrets scan --baseline .secrets.baseline
   git add .secrets.baseline
   ```

3. **Skip the hook temporarily** (use sparingly):

   ```bash
   SKIP=detect-secrets git commit -m "fix: urgent fix"
   ```

### Large Baseline File (>10MB)

**Problem:** Baseline file is too large.

**Solution:** Increase exclusion patterns or adjust entropy limits:

```bash
# Exclude more file types
detect-secrets scan --baseline .secrets.baseline \
    --exclude-files '\.json$' \
    --exclude-files '\.md$'

# Or increase entropy thresholds
# Edit .pre-commit-config.yaml:
# --base64-limit 5.0
# --hex-limit 4.0
```

## CI/CD Integration

### GitHub Actions

The pre-commit hook runs in CI, but `detect-secrets` is skipped:

```yaml
ci:
  skip:
    - detect-secrets  # Skip in CI to avoid baseline conflicts
```

To enable in CI:

```yaml
- name: Run detect-secrets
  run: |
    pip install detect-secrets
    detect-secrets scan --baseline .secrets.baseline
```

### Manual Scanning

Run detect-secrets manually without pre-commit:

```bash
# Install detect-secrets
pip install detect-secrets

# Scan without baseline (shows all findings)
detect-secrets scan

# Scan with baseline (shows only new findings)
detect-secrets scan --baseline .secrets.baseline

# Scan specific directory
detect-secrets scan policies/ --baseline .secrets.baseline
```

## Best Practices

### 1. Review Baseline Changes

When updating the baseline, review what's being added:

```bash
# Show diff before staging
git diff .secrets.baseline | grep '"filename"' | sort | uniq
```

### 2. Don't Commit Real Secrets

**Never add real secrets to the baseline!** Only add false positives.

### 3. Regular Audits

Periodically audit the baseline:

```bash
# List all files in baseline
jq -r '.results | keys[]' .secrets.baseline | wc -l

# Check for suspicious entries
jq -r '.results[] | .[] | select(.type == "AWS Access Key")' .secrets.baseline
```

### 4. Use Environment Variables

Instead of hardcoding secrets:

```bash
# ❌ BAD
export AZURE_CLIENT_SECRET="abc123"

# ✅ GOOD
export AZURE_CLIENT_SECRET="${AZURE_CLIENT_SECRET}"
```

### 5. Test Before Committing

Always test the hook before committing:

```bash
pre-commit run detect-secrets --all-files
```

## Troubleshooting

### detect-secrets Not Found

```bash
# Install globally
pip install detect-secrets

# Or install in devcontainer
pip3 install --user detect-secrets

# Verify installation
~/.local/bin/detect-secrets --version
```

### Baseline File Corrupted

```bash
# Validate JSON
jq empty .secrets.baseline

# If invalid, regenerate
detect-secrets scan --baseline .secrets.baseline
```

### Pre-commit Hook Not Running

```bash
# Reinstall hooks
pre-commit install --install-hooks

# Verify configuration
pre-commit run --all-files --verbose
```

## Summary

- ✅ **Baseline file**: `.secrets.baseline` - Contains approved false positives
- ✅ **Update command**: `detect-secrets scan --baseline .secrets.baseline`
- ✅ **Pre-commit hook**: Automatically scans for secrets before commit
- ✅ **False positives**: Add to baseline, never real secrets
- ✅ **Manual scan**: `detect-secrets scan` - Show all findings
- ✅ **Audit baseline**: `jq '.results | keys' .secrets.baseline` - Review entries

**Remember: The baseline is for false positives only. Real secrets should NEVER be committed!** 🔒
