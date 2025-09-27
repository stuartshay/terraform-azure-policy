# Dependabot Configuration Guide

## Overview

This project uses GitHub Dependabot to automatically keep our dependencies up to date. Dependabot monitors our project dependencies and creates pull requests when updates are available.

## Configuration

The Dependabot configuration is defined in `.github/dependabot.yml` and covers the following package ecosystems:

### 1. Terraform Dependencies

- **Directory**: `/policies`
- **Schedule**: Weekly on Mondays at 09:00 UTC
- **Pull Request Limit**: 5 open PRs
- **Labels**: `dependencies`, `terraform`, `automated`

**What it monitors:**

- Terraform providers (hashicorp/azurerm, etc.)
- Terraform module versions
- Provider version constraints

**Special Configuration:**

- Ignores patch releases for the Azure RM provider to reduce noise
- Only updates direct and indirect dependencies

### 2. GitHub Actions Dependencies

- **Directory**: `/` (root)
- **Schedule**: Weekly on Mondays at 09:00 UTC
- **Pull Request Limit**: 3 open PRs
- **Labels**: `dependencies`, `github-actions`, `automated`

**What it monitors:**

- Action versions in workflow files (.github/workflows/*.yml)
- Docker image tags used in actions
- Marketplace action versions

### 3. Pre-commit Hooks Dependencies

- **Directory**: `/` (root)
- **Schedule**: Weekly on Tuesdays at 09:00 UTC
- **Pull Request Limit**: 5 open PRs
- **Labels**: `dependencies`, `pre-commit`, `automated`

**What it monitors:**

- Pre-commit hook versions in `.pre-commit-config.yaml`
- Python package versions for tools like markdownlint, yamllint
- Tool versions for terraform-docs, tflint, etc.

**Special Configuration:**

- Ignores major version updates to prevent breaking changes
- Focuses on security and patch updates

## Pull Request Management

### Automatic Assignee

All Dependabot PRs are automatically assigned to `@stuartshay` for review.

### Commit Message Format

Dependabot uses consistent commit message prefixes:

- `terraform:` for Terraform dependency updates
- `github-actions:` for GitHub Actions updates
- `pre-commit:` for pre-commit hook updates

### Labels

All PRs are automatically labeled with:

- `dependencies` - General dependency update indicator
- Ecosystem-specific label (`terraform`, `github-actions`, `pre-commit`)
- `automated` - Indicates this is an automated update

## Managing Dependabot PRs

### Reviewing Updates

1. **Check the PR Description**: Dependabot provides detailed information about what changed
2. **Review Compatibility**: Ensure the update doesn't break existing functionality
3. **Run Tests**: Use the pre-commit hooks and policy tests to validate changes
4. **Check Breaking Changes**: Review release notes for any breaking changes

### Approving and Merging

1. **For Patch Updates**: Generally safe to approve quickly
2. **For Minor Updates**: Review changelog and test thoroughly
3. **For Major Updates**: Requires careful review and potentially code changes

### Managing PR Volume

If too many PRs are opened:

1. Adjust `open-pull-requests-limit` in dependabot.yml
2. Use `ignore` blocks to skip specific updates
3. Schedule updates less frequently

## Ignoring Specific Updates

### Temporary Ignore

To temporarily ignore a specific dependency:

```yaml
ignore:
  - dependency-name: "hashicorp/azurerm"
    update-types: ["version-update:semver-minor"]
```

### Permanent Ignore

For dependencies you want to manage manually:

```yaml
ignore:
  - dependency-name: "specific-package"
    update-types: ["version-update:all"]
```

## Integration with Pre-commit

Dependabot updates work well with our pre-commit hooks:

1. **Automatic Validation**: Pre-commit hooks run on Dependabot PRs
2. **Format Consistency**: Tools like terraform fmt ensure consistent formatting
3. **Security Scanning**: detect-secrets and other tools validate security

## Troubleshooting

### Common Issues

1. **PR Creation Failures**
   - Check repository permissions
   - Verify configuration syntax
   - Review GitHub Actions logs

2. **Merge Conflicts**
   - Dependabot will automatically rebase if possible
   - Manual intervention required for complex conflicts

3. **Test Failures**
   - Review pre-commit hook output
   - Check policy validation results
   - Verify Terraform plan output

### Getting Help

- Review the [GitHub Dependabot documentation](https://docs.github.com/en/code-security/dependabot)
- Check the [configuration reference](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file)
- Examine PR descriptions for update details

## Best Practices

### Security

- Review security updates immediately
- Enable Dependabot security alerts
- Monitor for vulnerable dependencies

### Maintenance

- Regularly review and update the dependabot.yml configuration
- Adjust schedules based on team workflow
- Keep ignore lists minimal and up-to-date

### Testing

- Always run full test suite after major updates
- Validate policy definitions after Terraform provider updates
- Test pre-commit hooks after tool updates

## Configuration Examples

### High-Frequency Updates (Daily)

```yaml
schedule:
  interval: "daily"
  time: "09:00"
  timezone: "Etc/UTC"
```

### Low-Frequency Updates (Monthly)

```yaml
schedule:
  interval: "monthly"
  day: 1
  time: "09:00"
  timezone: "Etc/UTC"
```

### Version Range Constraints

```yaml
ignore:
  - dependency-name: "hashicorp/azurerm"
    versions: ["< 4.0"]  # Ignore versions before 4.0
```

This guide should help you effectively manage and understand the Dependabot configuration for this Azure Policy testing project.
