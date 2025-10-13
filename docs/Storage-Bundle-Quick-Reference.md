# Storage Policy Bundle - Quick Reference

Quick reference guide for common versioning operations.

## ⚠️ Important: Publishing vs Deployment

**This bundle PUBLISHES policies only - it does NOT deploy to Azure.**

- **Publishing** = Creating versioned packages → MyGet/Terraform Cloud
- **Deployment** = Applying to Azure → Via Initiatives (`/initiatives/storage/`)

See [Initiative Consumption Guide](./Initiative-Consumption-Guide.md) for deployment.

---

## 🚀 Release a New Version

### Via GitHub UI

1. Go to **Actions** → **Release Storage Policy Bundle**
2. Click **Run workflow**
3. Select version bump type and enter release notes
4. Click **Run workflow**

### Via CLI

```bash
gh workflow run storage-bundle-release.yml \
  -f version_bump=patch \
  -f release_notes="Your changes here"
```

## 📦 Version Files Location

```text
policies/storage/
├── version.json              # Current version
├── CHANGELOG.md              # Version history
├── bundle.metadata.json      # Package metadata
└── storage-policies.nuspec   # NuGet spec
```

## 🔢 Version Bump Types

| Type | Use When | Example |
|------|----------|---------|
| `patch` | Bug fixes, docs | 1.0.0 → 1.0.1 |
| `minor` | New features | 1.0.0 → 1.1.0 |
| `major` | Breaking changes | 1.0.0 → 2.0.0 |

## 📋 Pre-Release Checklist

- [ ] Changes merged to `main`
- [ ] Tests passing
- [ ] Review PR comment for suggested version bump
- [ ] Prepare release notes

## 🏷️ Git Tags

Format: `storage-policies/v1.0.0`

```bash
# List tags
git tag -l "storage-policies/*"

# View tag details
git show storage-policies/v1.0.0
```

## 📥 Install Package

### MyGet (NuGet)

```powershell
Install-Package AzurePolicy.Storage.SecurityBundle `
  -Version 1.0.0 `
  -Source https://www.myget.org/F/YOUR-FEED/api/v3/index.json
```

### Terraform Cloud

```hcl
module "storage_policies" {
  source  = "app.terraform.io/YOUR-ORG/storage-policy-bundle/azurerm"
  version = "1.0.0"
}
```

## 🔄 Rollback

```hcl
# Deploy previous version
module "storage_policies" {
  version = "1.0.0"  # Previous version
}
```

## 🛠️ Troubleshooting

### Check current version

```bash
jq -r '.version' policies/storage/version.json
```

### Validate version.json

```bash
jq empty policies/storage/version.json
```

### View workflow logs

```bash
gh run list --workflow=storage-bundle-release.yml
gh run view <run-id>
```

## 📚 Documentation

- Full Guide: [docs/Storage-Bundle-Versioning-Guide.md](./Storage-Bundle-Versioning-Guide.md)
- Bundle README: [policies/storage/BUNDLE-README.md](../policies/storage/BUNDLE-README.md)
- Changelog: [policies/storage/CHANGELOG.md](../policies/storage/CHANGELOG.md)

## 🔗 Links

- [GitHub Releases](https://github.com/stuartshay/terraform-azure-policy/releases)
- [GitHub Actions](https://github.com/stuartshay/terraform-azure-policy/actions)
- [Semantic Versioning](https://semver.org/)

## ⚙️ Configuration Required

To enable full functionality, configure these secrets:

```text
Repository Secrets:
- MYGET_FEED_URL
- MYGET_API_KEY
- TF_API_TOKEN
```

## 📞 Support

- Issues: <https://github.com/stuartshay/terraform-azure-policy/issues>
- Docs: [docs/](.)
