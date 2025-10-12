# Changelog - Azure Storage Security Policies Bundle

All notable changes to the Azure Storage Security Policies bundle will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-11

### Added

- Initial release of Azure Storage Security Policies bundle
- **deny-storage-account-public-access**: Prevents storage accounts from allowing public blob access or public container access (CKV_AZURE_190)
- **deny-storage-blob-logging-disabled**: Ensures blob logging is enabled for storage accounts
- **deny-storage-https-disabled**: Enforces HTTPS-only access for storage accounts
- **deny-storage-softdelete**: Requires soft delete to be enabled for blob storage
- **deny-storage-version**: Ensures versioning is enabled for blob storage

### Bundle Information

- Total Policies: 5
- Category: Storage Security
- Compliance Frameworks: Checkov security rules
- Default Effect: Deny
- Supports Effects: Audit, Deny, Disabled

### Deployment

- Terraform Module: Available via Terraform Cloud Registry
- NuGet Package: Available via MyGet feed
- GitHub Release: v1.0.0

---

## Version Guidelines

### Version Increment Rules

- **MAJOR** (x.0.0): Breaking changes to policy rules that may affect existing deployments
- **MINOR** (1.x.0): New policies added to the bundle or significant feature enhancements
- **PATCH** (1.0.x): Bug fixes, documentation updates, or minor policy refinements

### What Triggers a New Version

- Changes to any policy rule.json file
- Updates to policy parameters or effects
- Documentation updates (PATCH)
- Addition/removal of policies (MINOR/MAJOR)

### Backward Compatibility

- Bundle maintains backward compatibility for at least 2 major versions
- Deprecated features will be announced 1 version prior to removal
- Breaking changes will be clearly documented in CHANGELOG
