# Storage Policy Bundle Versioning Guide

## Overview

This guide explains the versioning system for the Azure Storage Security Policies Bundle, including how to release new versions, understand version numbers, and manage the bundle lifecycle.

## Table of Contents

1. [Versioning Strategy](#versioning-strategy)
2. [Bundle Structure](#bundle-structure)
3. [Creating a New Release](#creating-a-new-release)
4. [Version Management Files](#version-management-files)
5. [GitHub Actions Workflows](#github-actions-workflows)
6. [Publishing to Registries](#publishing-to-registries)
7. [Rollback Procedures](#rollback-procedures)
8. [Best Practices](#best-practices)

---

## ⚠️ Publishing vs Deployment

### This Bundle: Publishing Only

**The Storage Policy Bundle does NOT deploy policies to Azure.** It only publishes versioned policy definitions to registries (MyGet, Terraform Cloud).

**What This Bundle Does:**

- ✅ Publishes versioned policy packages to registries
- ✅ Creates NuGet packages for MyGet
- ✅ Creates Terraform modules for Terraform Cloud
- ✅ Provides discovery metadata

**What This Bundle Does NOT Do:**

- ❌ Deploy policies to Azure subscriptions
- ❌ Create policy assignments
- ❌ Configure Azure resources

### Deployment: Via Initiatives

Actual Azure deployment happens through **Policy Initiatives** located in `/initiatives/storage/`. See the [Initiative Consumption Guide](./Initiative-Consumption-Guide.md) for deployment instructions.

**Deployment Flow:**

```text
1. Policy Bundle Published (v1.0.0) → Registries
2. Initiative References Bundle Version → /initiatives/storage/policies-prod.json
3. Terraform Deploys Initiative → Azure Subscription
4. Policy Assignment Created → Azure Resources
```

---

## Versioning Strategy

### Semantic Versioning

The Storage Policy Bundle follows **Semantic Versioning 2.0.0** (SemVer):

```text
MAJOR.MINOR.PATCH
  │     │     │
  │     │     └─── Bug fixes, documentation updates
  │     └───────── New policies, non-breaking enhancements
  └─────────────── Breaking changes to policy rules
```

**Current Version:** 1.0.0

### Version Increment Rules

| Change Type | Version Bump | Example | When to Use |
|-------------|--------------|---------|-------------|
| **MAJOR** | x.0.0 | 1.0.0 → 2.0.0 | - Breaking changes to policy rules<br>- Changes that affect existing deployments<br>- Removal of policies<br>- Changes to default effects (Audit → Deny) |
| **MINOR** | 1.x.0 | 1.0.0 → 1.1.0 | - New policies added to bundle<br>- New parameters added<br>- Non-breaking enhancements<br>- Compliance framework additions |
| **PATCH** | 1.0.x | 1.0.0 → 1.0.1 | - Bug fixes<br>- Documentation updates<br>- Metadata corrections<br>- Performance improvements |

### Bundled Versioning

All 5 storage policies share a **single version number**:

- When ANY policy changes, the entire bundle version increments
- All policies are republished together
- The CHANGELOG tracks which specific policies changed in each version

**Example:**

- If `deny-storage-https-disabled` policy is updated, the bundle version increases from 1.0.0 to 1.0.1
- All 5 policies are included in the new 1.0.1 release, even though only one changed

---

## Bundle Structure

### Policy Bundle Files

```text
policies/storage/
├── version.json                    # Bundle version tracking
├── CHANGELOG.md                    # Version history
├── bundle.metadata.json            # Discovery metadata
├── BUNDLE-README.md                # Bundle documentation
├── storage-policies.nuspec         # NuGet package spec
├── extract-package.ps1             # Package extraction script
└── [5 policy directories]          # Individual policies
    ├── deny-storage-account-public-access/
    ├── deny-storage-blob-logging-disabled/
    ├── deny-storage-https-disabled/
    ├── deny-storage-softdelete/
    └── deny-storage-version/
```

---

## Creating a New Release

### Prerequisites

- Merged changes to `main` branch
- GitHub repository write access
- (Optional) MyGet API key configured
- (Optional) Terraform Cloud API token configured

### Step-by-Step Release Process

#### 1. Make Policy Changes

```bash
# Make your changes to any storage policy
cd policies/storage/deny-storage-https-disabled
# Edit rule.json, main.tf, etc.

# Commit and push
git add .
git commit -m "fix(storage): update HTTPS policy validation"
git push origin feature-branch
```

#### 2. Create Pull Request

The **Storage Bundle Change Detection** workflow will automatically:

- Detect which policies changed
- Suggest a version bump type
- Post a comment on the PR with recommendations

#### 3. Review and Merge PR

Review the suggested version bump and merge when ready.

#### 4. Trigger Release Workflow

##### Option A: GitHub UI

1. Go to **Actions** → **Release Storage Policy Bundle**
2. Click **Run workflow**
3. Fill in the form:
   - **Version bump type**: `patch`, `minor`, or `major`
   - **Release notes**: Describe the changes
   - **Publish to MyGet**: ✓ (if configured)
   - **Publish to Terraform Cloud**: ✓ (if configured)
4. Click **Run workflow**

##### Option B: GitHub CLI

```bash
gh workflow run storage-bundle-release.yml \
  -f version_bump=patch \
  -f release_notes="Fixed HTTPS validation logic for Premium storage accounts" \
  -f publish_to_myget=true \
    -f publish_to_terraform_cloud=true
```

##### Option C: Custom Version

If you need to set a specific version:

```bash
gh workflow run storage-bundle-release.yml \
  -f custom_version=1.2.3 \
  -f release_notes="Custom release with specific version"
```

#### 5. Workflow Execution

The release workflow will:

1. **Validate** version format
2. **Update** version files:
   - `version.json`
   - `bundle.metadata.json`
   - `CHANGELOG.md`
   - `storage-policies.nuspec`
3. **Commit** changes to repository
4. **Create** Git tag: `storage-policies/v1.0.1`
5. **Build** NuGet package
6. **Publish** to MyGet (if enabled)
7. **Publish** to Terraform Cloud (if enabled)
8. **Create** GitHub Release with artifacts

#### 6. Verify Release

Check the following:

- ✅ GitHub Release created at `https://github.com/YOUR-ORG/terraform-azure-policy/releases`
- ✅ Git tag created: `storage-policies/v1.0.1`
- ✅ NuGet package available in MyGet feed
- ✅ Terraform module available in Terraform Cloud

---

## Version Management Files

### version.json

Tracks the current bundle version:

```json
{
  "version": "1.0.0",
  "bundle": "storage-policies",
  "displayName": "Azure Storage Security Policies Bundle",
  "policies": [
    "deny-storage-account-public-access",
    "deny-storage-blob-logging-disabled",
    "deny-storage-https-disabled",
    "deny-storage-softdelete",
    "deny-storage-version"
  ],
  "lastUpdated": "2025-10-11T16:52:00Z",
  "changeType": "patch"
}
```

### bundle.metadata.json

Discovery and compliance metadata:

```json
{
  "bundleId": "azure-storage-policies",
  "version": "1.0.0",
  "policyCount": 5,
  "policies": {
    "deny-storage-account-public-access": {
      "checkovId": "CKV_AZURE_190",
      "severity": "High",
      // ... metadata
    }
  }
}
```

### CHANGELOG.md

Version history following [Keep a Changelog](https://keepachangelog.com/):

```markdown
## [1.0.1] - 2025-10-15

### Fixed
- Updated HTTPS validation logic in deny-storage-https-disabled

## [1.0.0] - 2025-10-11

### Added
- Initial release with 5 storage security policies
```

---

## GitHub Actions Workflows

### storage-bundle-release.yml

**Triggers:** Manual workflow dispatch

**Purpose:** Create and publish new bundle versions

**Inputs:**

- `version_bump`: patch | minor | major
- `custom_version`: Optional override
- `release_notes`: Required description
- `publish_to_myget`: Boolean (default: true)
- `publish_to_terraform_cloud`: Boolean (default: true)

**Jobs:**

1. `validate` - Validate version format
2. `update-bundle` - Update version files and create tag
3. `build-nuget-package` - Create NuGet package
4. `publish-myget` - Publish to MyGet feed
5. `publish-terraform-cloud` - Publish to Terraform Cloud
6. `create-github-release` - Create GitHub release
7. `summary` - Generate workflow summary

### storage-bundle-changes.yml

**Triggers:** Pull requests and pushes to main

**Purpose:** Detect policy changes and suggest version bumps

**Features:**

- Automatic change detection
- Version bump suggestions
- JSON validation
- PR comments with guidance

**Example PR Comment:**

```markdown
## 📦 Storage Policy Bundle Changes Detected

### Changed Policies
- `deny-storage-https-disabled`

### Version Information
- **Current Version:** `1.0.0`
- **Suggested Bump:** `patch`
- **Suggested New Version:** `1.0.1`

### Next Steps
After this PR is merged, create a new release...
```

---

## Publishing to Registries

### MyGet Configuration

1. **Create MyGet Feed**

   ```text
   Feed Name: azure-policy-bundles
   Feed URL: https://www.myget.org/F/YOUR-FEED/api/v3/index.json
   ```

2. **Configure GitHub Secrets**

   ```text
   MYGET_FEED_URL: https://www.myget.org/F/YOUR-FEED/api/v3/index.json
   MYGET_API_KEY: your-api-key-here
   ```

3. **Enable Publishing**
   - Uncomment the publishing lines in `storage-bundle-release.yml`:

   ```yaml
   nuget sources add -Name MyGet -Source ${{ secrets.MYGET_FEED_URL }}
   nuget push $package -Source MyGet -ApiKey ${{ secrets.MYGET_API_KEY }}
   ```

### Terraform Cloud Configuration

1. **Create Organization & Workspace**

   ```text
   Organization: your-org
   Workspace: storage-policy-bundle
   ```

2. **Configure GitHub Secrets**

   ```text
   TF_API_TOKEN: your-terraform-cloud-api-token
   ```

3. **Publish Module**
   - Implement Terraform Cloud publishing in workflow
   - Connect to private module registry

---

## Rollback Procedures

### Rollback to Previous Version

#### Option 1: Deploy Previous Version

```hcl
module "storage_policies" {
  source  = "app.terraform.io/YOUR-ORG/storage-policy-bundle/azurerm"
  version = "1.0.0"  # Previous working version

  # ... configuration
}
```

#### Option 2: Emergency Disable

```hcl
module "storage_policies" {
  source  = "..."
  version = "1.1.0"  # Current version

  policy_effect = "Disabled"  # Temporarily disable all policies
}
```

#### Option 3: Create Rollback Release

```bash
# Create a new release reverting the changes
gh workflow run storage-bundle-release.yml \
  -f version_bump=patch \
  -f release_notes="Rollback: Reverted changes from v1.1.0 due to validation issues"
```

### Rollback Checklist

- [ ] Identify the issue and last known good version
- [ ] Notify team of rollback
- [ ] Deploy previous version or disable policies
- [ ] Document the issue in CHANGELOG
- [ ] Create new release with fixes when ready

---

## Best Practices

### Version Management

1. **Always use semantic versioning**
   - Follow MAJOR.MINOR.PATCH rules strictly
   - Document breaking changes clearly

2. **Maintain detailed changelogs**
   - Update CHANGELOG.md with every release
   - Include which specific policies changed

3. **Test before releasing**
   - Run unit tests
   - Validate in non-production environment
   - Review PR comments for version suggestions

### Release Process

1. **Small, frequent releases**
   - Prefer PATCH releases for incremental improvements
   - Bundle related changes together

2. **Clear release notes**
   - Describe what changed and why
   - Include migration guidance for breaking changes
   - Reference related issues/PRs

3. **Version tagging**
   - Tags follow pattern: `storage-policies/v1.0.0`
   - Never delete or modify existing tags
   - Use annotated tags with messages

### Publishing

1. **Dual publishing**
   - Publish to both MyGet and Terraform Cloud
   - Verify both publications succeeded

2. **Package integrity**
   - Generate checksums for packages
   - Verify package contents before publishing

3. **Version consistency**
   - All version files must match
   - Automated workflow handles this

---

## Troubleshooting

### Common Issues

**Issue:** Version bump workflow fails

**Solution:**

```bash
# Check version.json format
jq . policies/storage/version.json

# Validate semantic version
echo "1.0.0" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$'
```

**Issue:** NuGet package build fails

**Solution:**

- Check .nuspec file for invalid XML
- Verify all file paths exist
- Review Windows runner logs

**Issue:** Git tag already exists

**Solution:**

```bash
# Delete local tag
git tag -d storage-policies/v1.0.0

# Delete remote tag
git push origin :refs/tags/storage-policies/v1.0.0

# Re-run workflow
```

---

## Additional Resources

- [Semantic Versioning Spec](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [NuGet Package Documentation](https://docs.microsoft.com/nuget/)
- [Terraform Module Registry](https://www.terraform.io/docs/cloud/registry/index.html)

---

## Support

For questions or issues:

- **GitHub Issues**: <https://github.com/stuartshay/terraform-azure-policy/issues>
- **Documentation**: See `/docs` directory
- **Workflow Logs**: Check GitHub Actions for detailed logs

---

**Last Updated:** 2025-10-11  
**Bundle Version:** 1.0.0  
**Maintained by:** Azure Policy Testing Project
