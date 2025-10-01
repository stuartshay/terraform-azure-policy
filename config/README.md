# Azure Policy Test Configuration

This directory contains the centralized configuration system for Azure Policy functional tests. The configuration system provides a single source of truth for all test settings, making it easier to maintain and modify test parameters across multiple test files.

## Overview

The centralized configuration system consists of three main components:

1. **`test-config.ps1`** - Main test configuration with common settings
2. **`policies.json`** - Policy-specific configuration and metadata
3. **`config-loader.ps1`** - Helper functions to load and work with configurations

## Files

### test-config.ps1

Contains the main test configuration including:

- Azure environment settings (resource groups, locations, subscriptions)
- Test timing configuration (wait times, timeouts)
- Test behavior flags (cleanup, verbose output, etc.)
- Resource naming configuration
- Azure PowerShell module settings
- Test tag definitions

### policies.json

Contains policy-specific configuration organized by category:

- Policy names, display names, and categories
- Policy definition file paths
- Resource prefixes for test resources
- Policy-specific test configuration (SKUs, suffixes, etc.)
- Environment-specific overrides
- Metadata about the configuration

### config-loader.ps1

Provides helper functions for working with the configuration:

- `Get-PolicyConfiguration()` - Load the policy configuration
- `Get-PolicyConfig()` - Get configuration for a specific policy
- `Initialize-PolicyTestConfig()` - Initialize complete test configuration
- `New-PolicyTestResourceName()` - Generate unique resource names
- `Get-PolicyDefinitionPath()` - Resolve policy definition file paths
- `Test-ConfigurationFile()` - Validate configuration files

## Usage

### Basic Usage in Test Files

```powershell
# Import centralized configuration
. "$PSScriptRoot\..\..\config\config-loader.ps1"

# Initialize test configuration for a specific policy
$script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access'

# Import required modules
Import-PolicyTestModule -ModuleTypes @('Required', 'Storage')

# Initialize test environment
$envInit = Initialize-PolicyTestEnvironment -Config $script:TestConfig
if (-not $envInit.Success) {
    throw "Environment initialization failed: $($envInit.Errors -join '; ')"
}

# Use configuration values
$resourceGroupName = $script:TestConfig.Azure.ResourceGroupName
$policyName = $script:TestConfig.Policy.Name
$waitTime = $script:TestConfig.Timeouts.PolicyEvaluationWaitSeconds
```

### Generating Resource Names

```powershell
# Generate unique resource names using centralized configuration
$compliantStorageName = New-PolicyTestResourceName -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access' -ResourceType 'compliant'
$nonCompliantStorageName = New-PolicyTestResourceName -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access' -ResourceType 'nonCompliant'
```

### Using Policy Definition Paths

```powershell
# Get the full path to a policy definition file
$policyPath = Get-PolicyDefinitionPath -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access' -TestScriptPath $PSScriptRoot
$policyDefinitionJson = Get-Content $policyPath -Raw | ConvertFrom-Json
```

### Environment-Specific Configuration

```powershell
# Initialize configuration for a specific environment
$testConfig = Initialize-PolicyTestConfig -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access' -Environment 'dev'
```

## Configuration Structure

### Test Configuration Schema

The main test configuration (`$TestConfig`) contains:

```powershell
@{
    Azure = @{
        ResourceGroupName = 'rg-azure-policy-testing'
        DefaultLocation = 'East US'
        RequireValidSubscription = $true
        ValidateResourceGroupExists = $true
    }
    Timeouts = @{
        PolicyEvaluationWaitSeconds = 60
        ComplianceScanWaitSeconds = 30
        RemediationWaitSeconds = 30
        # ... more timeout settings
    }
    Behavior = @{
        CleanupTestResources = $true
        SkipLongRunningTests = $false
        VerboseOutput = $true
        # ... more behavior flags
    }
    Policy = @{
        Name = 'policy-name'
        DisplayName = 'Policy Display Name'
        Category = 'Policy Category'
        PolicyPath = 'relative/path/to/policy.json'
        ResourcePrefix = 'testprefix'
        TestConfig = @{
            # Policy-specific test configuration
        }
    }
}
```

### Policy Configuration Schema

The policy configuration (`policies.json`) contains:

```json
{
    "policies": {
        "category": {
            "policy-name": {
                "name": "policy-name",
                "displayName": "Policy Display Name",
                "category": "Category",
                "policyPath": "relative/path/to/policy.json",
                "resourcePrefix": "testprefix",
                "testConfig": {
                    "compliantSuffix": "comp",
                    "nonCompliantSuffix": "nonc",
                    "exemptedSuffix": "exemp"
                }
            }
        }
    },
    "environments": {
        "env-name": {
            "resourceGroupName": "rg-name",
            "subscriptionId": "optional-sub-id",
            "location": "location"
        }
    }
}
```

## Adding New Policies

To add a new policy to the centralized configuration:

1. **Add policy configuration to `policies.json`**:

   ```json
   "policy-category": {
       "new-policy-name": {
           "name": "new-policy-name",
           "displayName": "New Policy Display Name",
           "category": "Policy Category",
           "policyPath": "policies/category/new-policy-name/rule.json",
           "resourcePrefix": "testpolicynew",
           "testConfig": {
               "compliantSuffix": "comp",
               "nonCompliantSuffix": "nonc",
               "exemptedSuffix": "exemp",
               "customSetting": "value"
           }
       }
   }
   ```

2. **Update module configuration in `test-config.ps1`** (if needed):

   ```powershell
   # Add new module type if needed
   NewResourceType = @('Az.NewResource')
   ```

3. **Create or update test files** to use the centralized configuration:

   ```powershell
   # Import configuration
   . "$PSScriptRoot\..\..\config\config-loader.ps1"

   # Initialize for new policy
   $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'policy-category' -PolicyName 'new-policy-name'
   ```

## Migrating Existing Tests

To migrate an existing test file to use centralized configuration:

1. **Replace the BeforeAll block**:
   - Remove hardcoded configuration variables
   - Import the config-loader module
   - Initialize policy test configuration
   - Use centralized environment initialization

2. **Update resource name generation**:
   - Replace manual timestamp/naming logic
   - Use `New-PolicyTestResourceName()` function

3. **Update wait times**:
   - Replace hardcoded sleep values
   - Use timeout values from `$TestConfig.Timeouts`

4. **Update policy path resolution**:
   - Replace manual path construction
   - Use `Get-PolicyDefinitionPath()` function

## Benefits

### Single Source of Truth

- All configuration is centralized in one location
- Easy to update settings across all tests
- Consistent naming and timing across tests

### Environment Support

- Easy switching between dev, staging, and prod environments
- Environment-specific resource groups and settings
- Simplified CI/CD pipeline configuration

### Maintainability

- Reduced code duplication across test files
- Standardized test patterns and structure
- Easier to add new policies and tests

### Consistency

- Consistent resource naming patterns
- Standardized wait times and timeouts
- Uniform test behavior across all policy tests

## Troubleshooting

### Configuration Validation

Use the validation function to check configuration files:

```powershell
if (-not (Test-ConfigurationFile)) {
    Write-Error "Configuration validation failed"
}
```

### Common Issues

1. **Missing configuration files**: Ensure all three configuration files exist in the config directory
2. **Invalid JSON**: Validate `policies.json` syntax using a JSON validator
3. **Missing policy configuration**: Add new policies to `policies.json` before using them
4. **Path resolution issues**: Use `Get-PolicyDefinitionPath()` instead of manual path construction

### Debug Mode

Enable verbose output to see detailed configuration loading:

```powershell
$VerbosePreference = 'Continue'
$testConfig = Initialize-PolicyTestConfig -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access'
```

## Best Practices

1. **Always use centralized functions** for resource naming and path resolution
2. **Update policies.json** when adding new policies
3. **Use environment-specific configurations** for different deployment stages
4. **Validate configurations** before running tests
5. **Keep test-specific settings** in the policy configuration, not in test files
6. **Use meaningful resource prefixes** to identify test resources easily
7. **Document custom test configuration** properties in the policy configuration

## Examples

See the refactored `Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1` file for a complete example of how to use the centralized configuration system.
