# Test Naming Convention

## Overview

This document describes the standardized naming convention for test files in the Azure Policy Testing project.

## Naming Pattern

All test files follow this pattern:

```text
{Area}.{TestType}-{PolicyName}.Tests.ps1
```

### Components

- **Area**: The Azure service or resource category (e.g., `Storage`, `Network`, `FunctionApp`)
- **TestType**: The type of test being performed
  - `Unit` - Static validation tests that don't require Azure resources (fast, no authentication)
  - `Integration` - Tests that require Azure resources and policy assignments (slower, requires authentication)
- **PolicyName**: The specific policy being tested in PascalCase (e.g., `DenyStorageAccountPublicAccess`)

## File Renames Summary

### Storage Tests

| Old Name | New Name | Test Type |
|----------|----------|-----------|
| `Storage.Quick-PolicyValidation.Tests.ps1` | `Storage.Unit-DenyStorageAccountPublicAccess.Tests.ps1` | Unit |
| `Storage.Quick-SoftDeletePolicyValidation.Tests.ps1` | `Storage.Unit-DenyStorageSoftDelete.Tests.ps1` | Unit |
| `Storage.Deny-StorageAccountPublicAccess.Tests.ps1` | `Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1` | Integration |
| `Storage.Test-DenyStorageVersion.Tests.ps1` | `Storage.Integration-DenyStorageVersion.Tests.ps1` | Integration |

### Function App Tests

| Old Name | New Name | Test Type |
|----------|----------|-----------|
| `FunctionApp.Test-DenyFunctionAppHttpsOnly.Tests.ps1` | `FunctionApp.Integration-DenyFunctionAppHttpsOnly.Tests.ps1` | Integration |
| `FunctionApp.Test-DenyFunctionAppAnonymous.Tests.ps1` | `FunctionApp.Integration-DenyFunctionAppAnonymous.Tests.ps1` | Integration |

### Network Tests

| Old Name | New Name | Test Type |
|----------|----------|-----------|
| `Network.Test-DenyNetworkNoNSG.Tests.ps1` | `Network.Integration-DenyNetworkNoNSG.Tests.ps1` | Integration |
| `Network.Test-DenyNetworkPrivateIPs.Tests.ps1` | `Network.Integration-DenyNetworkPrivateIPs.Tests.ps1` | Integration |

## Test Type Characteristics

### Unit Tests

- **Speed**: Fast (typically < 1 second)
- **Azure Authentication**: Not required
- **Azure Resources**: Not created
- **What they test**:
  - JSON schema validation
  - Policy definition structure
  - Policy rule logic
  - Metadata validation
  - Static compliance scenarios

### Integration Tests

- **Speed**: Slower (can take several minutes)
- **Azure Authentication**: Required (`Connect-AzAccount`)
- **Azure Resources**: Created and tested against
- **What they test**:
  - Policy assignment validation
  - Actual compliance behavior
  - Resource creation/modification
  - Policy remediation
  - End-to-end scenarios

## Benefits of This Convention

1. **Clear Test Categorization**: Immediately understand the test type from the filename
2. **Easy Test Selection**: Run unit tests for quick validation, integration tests for full coverage
3. **Consistent Structure**: All test files follow the same predictable pattern
4. **Better Organization**: Group tests by area and type
5. **Improved CI/CD**: Easily separate fast tests from slow tests in pipelines

## Examples

### Running Unit Tests Only

```powershell
# Run all unit tests (fast, no Azure auth needed)
Invoke-Pester -Path "tests/**/*.Unit-*.Tests.ps1"

# Run storage unit tests only
Invoke-Pester -Path "tests/storage/Storage.Unit-*.Tests.ps1"
```

### Running Integration Tests

```powershell
# Requires Azure authentication first
Connect-AzAccount

# Run all integration tests
Invoke-Pester -Path "tests/**/*.Integration-*.Tests.ps1"

# Run specific integration test
Invoke-Pester -Path "tests/storage/Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1"
```

### Running Tests by Tag

Tests also use Pester tags that align with the naming convention:

```powershell
# Run all fast unit tests
Invoke-Pester -Tag "Unit", "Fast"

# Run integration tests only
Invoke-Pester -Tag "Integration"
```

## Migration Impact

The following files and configurations were updated:

- ✅ All test files renamed using `git mv` (preserves history)
- ✅ `.pre-commit-config.yaml` - Updated test paths
- ✅ `.vscode/tasks.json` - Updated task configurations
- ✅ `.github/workflows/ci.yml` - Updated CI pipeline
- ✅ `tests/README.md` - Updated documentation
- ✅ `docs/TestPanel-Guide.md` - Updated guide
- ✅ `docs/Code-Coverage-Guide.md` - Updated examples
- ✅ `docs/README.md` - Updated quick start
- ✅ Policy READMEs - Updated test file references
- ✅ `.secrets.baseline` - Regenerated with new filenames

## Future Additions

When adding new test files, follow these guidelines:

1. **Unit Tests**: Name as `{Area}.Unit-{PolicyName}.Tests.ps1`
   - Use for JSON validation, schema checks, static analysis
   - Should run in < 1 second
   - No Azure authentication required

2. **Integration Tests**: Name as `{Area}.Integration-{PolicyName}.Tests.ps1`
   - Use for end-to-end testing with real Azure resources
   - Requires authentication and resource group
   - Tag resource-intensive tests appropriately

3. **Tags**: Use consistent Pester tags
   - `Unit`, `Fast`, `Static` for unit tests
   - `Integration`, `Slow`, `Compliance` for integration tests
   - `RequiresCleanup` for tests that create resources

## Version History

- **2025-09-30**: Initial standardization - renamed all test files to new convention
