# Policy Bundle Versioning - Project Plan

## Project Status: Phase 2 In Progress 🔄

**Last Updated:** 2025-10-14  
**Current Phase:** Testing & Validation  
**Overall Progress:** 40% Complete

---

## Executive Summary

This project implements a versioned policy bundle system for Azure Policies, enabling controlled releases, version tracking, and environment-specific deployments through initiatives. The system supports dual publishing to MyGet (NuGet) and Terraform Cloud registries.

### Key Achievements

- ✅ Implemented storage policy bundle versioning (v1.0.0)
- ✅ Created automated GitHub Actions workflows
- ✅ Established clear publishing vs deployment separation
- ✅ Documented initiative-based deployment strategy

---

## Phase 1: Storage Bundle Foundation ✅ COMPLETED

**Duration:** Week 1  
**Status:** ✅ Complete  
**Commit:** `7457b1d` - feat(storage): implement policy bundle versioning system

### Deliverables Completed

#### 1.1 Bundle Structure ✅

- [x] `version.json` - Bundle version tracking (1.0.0)
- [x] `CHANGELOG.md` - Keep a Changelog format
- [x] `bundle.metadata.json` - Discovery & compliance metadata
- [x] `BUNDLE-README.md` - Comprehensive documentation
- [x] `storage-policies.nuspec` - NuGet package specification
- [x] `extract-package.ps1` - Package extraction script

#### 1.2 GitHub Actions Workflows ✅

- [x] `storage-bundle-release.yml`
  - Automated version bumping (patch/minor/major)
  - MyGet and Terraform Cloud publishing
  - GitHub releases with artifacts
  - Git tagging (format: `storage-policies/v1.0.0`)

- [x] `storage-bundle-changes.yml`
  - Automatic change detection on PRs
  - Version bump suggestions
  - Policy JSON validation
  - PR comment automation

#### 1.3 Documentation ✅

- [x] **Storage-Bundle-Versioning-Guide.md** - Complete versioning workflow
- [x] **Initiative-Consumption-Guide.md** - Deployment via initiatives
- [x] **Storage-Bundle-Quick-Reference.md** - Quick command reference

### Key Decisions Made

1. **Bundled Versioning**: All 5 storage policies share single version
2. **Semantic Versioning**: MAJOR.MINOR.PATCH format
3. **Publishing Only**: No direct Azure deployment from bundle
4. **Initiative-Based Deployment**: Separate consumption layer
5. **Dual Registry**: MyGet (discovery) + Terraform Cloud (IaC)

---

## Phase 2: Testing & Validation 🔄 IN PROGRESS

**Duration:** Week 2  
**Status:** 🔄 In Progress  
**Priority:** High

### 2.1 Pre-Release Testing

- [ ] **Test Change Detection Workflow**
  - Create test PR modifying a storage policy
  - Verify automatic change detection
  - Validate version bump suggestions
  - Check PR comment generation

- [ ] **Test Release Workflow**
  - Run manual workflow with patch bump
  - Verify version file updates
  - Confirm Git tag creation
  - Validate GitHub release creation

- [ ] **Validate Pre-commit Hooks**
  - Ensure all hooks pass
  - Verify detect-secrets works
  - Check markdown linting
  - Validate YAML syntax

### 2.2 Development Infrastructure ✅ COMPLETED

- [x] **NuGet CLI Setup (2025-10-14)**
  - Added .NET 9.0 SDK to DevContainer with 8.0 compatibility
  - Created installation script for local environments
  - Installed .NET 9.0.305 and NuGet 6.14.0.116 locally
  - Configured PATH in shell profile
  - Created comprehensive setup documentation

- [x] **MyGet Configuration**
  - Feed created: `azure-policy-compliance`
  - API key generated and tested
  - Added GitHub secret: `MYGET_FEED_URL`  <!-- pragma: allowlist secret -->
  - Added GitHub secret: `MYGET_API_KEY`  <!-- pragma: allowlist secret -->
  - Feed accessible and ready for publishing

- [x] **Terraform Cloud Configuration**
  - Organization: `azure-policy-compliance` confirmed
  - API token configured
  - Added GitHub secret: `TF_API_TOKEN`  <!-- pragma: allowlist secret -->
  - Verified API access (free tier limitations noted)
  - VCS connection needed for private registry

### 2.3 Registry Configuration Tasks

- [ ] **Terraform Cloud Private Registry**
  - Connect GitHub OAuth to Terraform Cloud
  - Publish first module via UI
  - Test automated publishing workflow
  - Document publishing process

- [ ] **MyGet Publishing**
  - Uncomment publishing code in workflow
  - Test package build and push
  - Verify package appears in feed
  - Document package consumption

### 2.3 First Release

- [ ] **Create Release v1.0.0**
  - Run `storage-bundle-release.yml` workflow
  - Select version: patch (already at 1.0.0)
  - Provide release notes
  - Verify package published to MyGet
  - Verify module published to Terraform Cloud
  - Confirm GitHub release created

- [ ] **Validation**
  - Download NuGet package from MyGet
  - Extract and verify contents
  - Test Terraform module consumption
  - Verify all 5 policies included

### 2.4 Initiative Module Development

- [ ] **Create Initiative Terraform Module**
  - Design module structure
  - Reference storage bundle version
  - Support environment-specific configs
  - Enable individual policy toggle

- [ ] **Test Deployment**
  - Deploy to sandbox environment
  - Verify policy assignments created
  - Test compliance reporting
  - Validate rollback capability

---

## Phase 3: Expand to Other Bundles 📅 PLANNED

**Duration:** Weeks 3-4  
**Status:** 📅 Planned  
**Priority:** Medium

### 3.1 Network Policy Bundle

- [ ] Copy versioning structure from storage
- [ ] Update bundle metadata
- [ ] Create network-bundle-release.yml workflow
- [ ] Create network-bundle-changes.yml workflow
- [ ] Document network-specific policies
- [ ] Initial version: 1.0.0

### 3.2 Function App Policy Bundle

- [ ] Implement versioning structure
- [ ] Create workflows
- [ ] Document bundle
- [ ] Initial version: 1.0.0

### 3.3 App Service Policy Bundle

- [ ] Implement versioning structure
- [ ] Create workflows
- [ ] Document bundle
- [ ] Initial version: 1.0.0

### 3.4 Cross-Bundle Coordination

- [ ] Document inter-bundle dependencies
- [ ] Create unified release calendar
- [ ] Establish version compatibility matrix

---

## Phase 4: Production Readiness 📅 PLANNED

**Duration:** Week 5  
**Status:** 📅 Planned  
**Priority:** High

### 4.1 Integration Testing

- [ ] **End-to-End Workflow Testing**
  - Policy change → PR → Review → Merge → Release
  - Version upgrade scenarios
  - Rollback procedures
  - Multi-environment deployment

- [ ] **Performance Testing**
  - Large-scale policy deployments
  - Multiple concurrent releases
  - Registry access patterns

### 4.2 Security & Compliance

- [ ] **Security Review**
  - Audit GitHub Actions permissions
  - Review secret management
  - Validate package signing (if applicable)
  - Check access controls

- [ ] **Compliance Documentation**
  - SOC 2 alignment
  - Change management procedures
  - Audit trail documentation
  - Version control policies

### 4.3 Runbooks & Training

- [ ] **Operational Runbooks**
  - Release procedure
  - Emergency rollback
  - Troubleshooting guide
  - Escalation procedures

- [ ] **Team Training**
  - Versioning system overview
  - Workflow demonstrations
  - Hands-on exercises
  - Q&A sessions

---

## Phase 5: Monitoring & Optimization 📅 FUTURE

**Duration:** Ongoing  
**Status:** 📅 Future  
**Priority:** Low

### 5.1 Observability

- [ ] **Metrics Dashboard**
  - Release frequency
  - Version adoption rates
  - Failed releases
  - Rollback frequency

- [ ] **Alerting**
  - Failed workflow notifications
  - Version drift alerts
  - Compliance violations
  - Registry availability

### 5.2 Process Improvements

- [ ] **Automation Enhancements**
  - Auto-detect version bump type from PR labels
  - Automated CHANGELOG generation
  - Release note templates
  - Dependency update automation

- [ ] **Developer Experience**
  - CLI tool for version management
  - VS Code extension integration
  - Local testing capabilities
  - Improved documentation search

---

## Immediate Next Steps (Next 48 Hours)

### Priority 1: Critical Path

1. **Configure MyGet Feed**
   - Create account/feed if needed
   - Generate and store API keys in GitHub secrets
   - Test package publishing manually

2. **Configure Terraform Cloud**
   - Set up organization/workspace
   - Generate API token
   - Store in GitHub secrets
   - Test module publishing

3. **Test Release Workflow**
   - Create test branch
   - Make minor policy change
   - Run through full workflow
   - Validate end-to-end

### Priority 2: Documentation

1. **Add Configuration Guide**
   - Document MyGet setup steps
   - Document Terraform Cloud setup
   - Create secret management guide
   - Add troubleshooting section

2. **Update Main README**
   - Add versioning section
   - Link to new documentation
   - Update architecture diagram

### Priority 3: Quality Assurance

1. **Code Review**
   - Review workflow YAML files
   - Check error handling
   - Validate rollback scenarios

2. **Documentation Review**
   - Proof-read all new docs
   - Check code examples
   - Verify links work

---

## Risk Register

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Registry unavailability | High | Low | Dual registry approach, cached packages |
| Breaking policy changes | High | Medium | Semantic versioning, changelog documentation |
| Workflow failures | Medium | Low | Comprehensive testing, rollback procedures |
| Version drift between environments | Medium | Medium | Automated compliance checks, monitoring |
| Team adoption resistance | Low | Low | Training, documentation, support |

---

## Success Metrics

### Phase 2 Goals

- [ ] Successfully publish first release to both registries
- [ ] Zero failed pre-commit checks
- [ ] Complete end-to-end workflow in <15 minutes
- [ ] All documentation reviewed and approved

### Long-term Goals

- Monthly release cadence for each bundle
- <5% rollback rate
- 100% version tracking compliance
- <30 minute emergency rollback time

---

## Resources & Dependencies

### GitHub Secrets Required

```plaintext
MYGET_FEED_URL       - MyGet feed URL for package publishing
MYGET_API_KEY        - MyGet API key for authentication  <!-- pragma: allowlist secret -->
TF_API_TOKEN         - Terraform Cloud API token  <!-- pragma: allowlist secret -->
```

### External Dependencies

- MyGet subscription/account
- Terraform Cloud organization
- GitHub Actions minutes
- Azure subscription for testing

### Team Resources

- DevOps Engineer (lead)
- Policy Developer
- Documentation Writer
- QA/Test Engineer

---

## Communication Plan

### Stakeholders

- Development Team
- Security Team
- Compliance Team
- Operations Team

### Updates

- Weekly status updates
- Major milestone announcements
- Incident reports (as needed)
- Monthly metrics review

---

## Appendix

### Related Documentation

- [Storage Bundle Versioning Guide](./Storage-Bundle-Versioning-Guide.md)
- [Initiative Consumption Guide](./Initiative-Consumption-Guide.md)
- [Storage Bundle Quick Reference](./Storage-Bundle-Quick-Reference.md)

### Repository Links

- [GitHub Repository](https://github.com/stuartshay/terraform-azure-policy)
- [Storage Bundle Workflows](./.github/workflows/)
- [Storage Policies](../policies/storage/)

### Change Log

- 2025-10-14: NuGet CLI infrastructure completed (.NET 9.0 SDK, all environments)
- 2025-10-14: MyGet and Terraform Cloud configurations validated
- 2025-10-14: Project plan updated with Phase 2 progress (40% complete)
- 2025-10-12: Phase 1 completed, pushed to GitHub
- 2025-10-12: Project plan created
- 2025-10-11: Initial implementation started

---

**Document Owner:** Azure Policy Testing Project  
**Next Review:** 2025-10-21  
**Version:** 1.1
