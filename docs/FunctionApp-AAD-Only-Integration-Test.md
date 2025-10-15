# Function App AAD-Only Integration Test

## Overview

Created comprehensive integration test for the Azure Function App AAD-only authentication policy (`deny-function-app-aad-only`).

## Test File

**Location:** `/workspaces/terraform-azure-policy/tests/function-app/FunctionApp.Integration-DenyFunctionAppAadOnly.Tests.ps1`

## Test Coverage

### 1. Policy Definition Validation

- ✅ Validates policy JSON structure
- ✅ Checks display name and policy name
- ✅ Verifies comprehensive description
- ✅ Validates metadata (category, version)
- ✅ Checks effect parameter configuration

### 2. Policy Rule Logic

- ✅ Validates authsettingsV2 config targeting (Azure AD authentication)
- ✅ Validates web config targeting (FTP/FTPS settings)
- ✅ Validates basicPublishingCredentialsPolicies targeting
- ✅ Checks for Azure AD authentication enabled requirement
- ✅ Checks for required authentication setting
- ✅ Checks for FTP disabled requirement

### 3. Policy Assignment Validation

- ✅ Verifies policy definition exists in Azure
- ✅ Verifies policy is assigned to resource group
- ✅ Validates assignment scope

### 4. Policy Compliance Testing

- ✅ Documents AAD authentication requirement
- ✅ Documents FTP/FTPS disabled requirement
- ✅ Documents basic publishing credentials disabled requirement
- ✅ Validates multiple violation scenarios (defense in depth)

### 5. Policy Evaluation Details

- ✅ Displays policy enforcement configuration
- ✅ Shows target resources
- ✅ Queries current compliance state
- ✅ Shows compliant vs non-compliant resource counts

### 6. Testing Documentation

- ✅ Provides comprehensive testing guidance
- ✅ Documents manual testing steps
- ✅ Includes alternative validation methods:
  - Azure Resource Graph queries
  - PowerShell validation scripts
  - Azure CLI commands

## Test Structure

```powershell
Describe 'Policy Definition Validation'              # 9 tests
Describe 'Policy Assignment Validation'              # 3 tests
Describe 'Policy Compliance Testing'                 # 4 tests
Describe 'Policy Evaluation Details'                 # 2 tests
Describe 'Test Documentation and Guidance'           # 2 tests
                                                     # ────────
                                                     # 20 tests total
```

## Key Features

### 1. **Configuration Resource Testing**

This policy evaluates **configuration resources**, not Function Apps directly:

- `Microsoft.Web/sites/config` (authsettingsV2) - Authentication settings
- `Microsoft.Web/sites/config` (web) - FTP settings
- `Microsoft.Web/sites/slots/config` (web) - FTP settings for deployment slots
- `Microsoft.Web/sites/basicPublishingCredentialsPolicies` (ftp) - FTP credentials
- `Microsoft.Web/sites/basicPublishingCredentialsPolicies` (scm) - SCM credentials

### 2. **Skip-on-No-Context Support**

Tests gracefully skip when no Azure connection is available:

```powershell
$envInit = Initialize-PolicyTestEnvironment -Config $script:TestConfig -SkipIfNoContext $script:TestConfig.Azure.SkipIfNoContext
```

### 3. **Comprehensive Documentation**

Includes detailed guidance on:

- How the policy works
- What it enforces
- How to test it manually
- Alternative validation methods

### 4. **Defense in Depth Validation**

Policy enforces multiple security layers:

- ✅ Authentication (Azure AD enabled)
- ✅ Authorization (require authentication)
- ✅ Transport security (FTP disabled)
- ✅ Credential management (basic auth disabled)

## Policy Requirements

The policy enforces these security requirements:

### 1. Azure AD Authentication (Easy Auth v2)

- `requireAuthentication` must be `true`
- `azureActiveDirectory.enabled` must be `true`
- `unauthenticatedClientAction` must be `RedirectToLoginPage` or `Return401`

### 2. FTP/FTPS Disabled

- `ftpsState` must be `Disabled` (not `AllAllowed` or `FtpsOnly`)
- Applies to both main app and deployment slots

### 3. Basic Publishing Credentials Disabled

- FTP publishing credentials must be disabled (`allow = false`)
- SCM publishing credentials must be disabled (`allow = false`)

## Important Notes

### Platform Limitations

1. **Cannot filter by 'kind' field** - The `kind` field is not a valid Azure Policy alias
2. **Policy applies to ALL App Services** - Not just Function Apps (includes Web Apps, Logic Apps, etc.)
3. **Authentication settings apply to main app only** - Not deployment slots
4. **FTP settings apply to both main app and slots**

### Testing Considerations

1. **Manual testing required** - Cannot programmatically create compliant/non-compliant auth configs
2. **Compliance evaluation is delayed** - Configuration changes may take time to evaluate
3. **Use `Start-AzPolicyComplianceScan`** - For immediate compliance evaluation

## Alternative Validation Methods

### Azure Resource Graph Query

```kusto
resources
| where type =~ 'Microsoft.Web/sites'
| extend authSettings = properties.siteConfig.authSettings
| extend ftpsState = properties.siteConfig.ftpsState
| extend aadEnabled = tobool(authSettings.enabled)
| extend requireAuth = tobool(authSettings.requireAuthentication)
| where aadEnabled != true or requireAuth != true or ftpsState != 'Disabled'
| project name, resourceGroup, aadEnabled, requireAuth, ftpsState
```

### PowerShell Validation

```powershell
$functionApps = Get-AzWebApp | Where-Object { $_.Kind -like '*functionapp*' }
foreach ($app in $functionApps) {
    $authSettings = Get-AzWebAppAuthSettings -ResourceGroupName $app.ResourceGroup -Name $app.Name
    $config = Get-AzWebApp -ResourceGroupName $app.ResourceGroup -Name $app.Name

    if (-not $authSettings.Enabled -or $config.SiteConfig.FtpsState -ne 'Disabled') {
        Write-Warning "Non-compliant: $($app.Name)"
    }
}
```

### Azure CLI

```bash
# Check auth settings
az webapp auth show --name <function-app-name> --resource-group <rg-name>

# Check FTP state
az functionapp config show --name <function-app-name> --resource-group <rg-name> --query ftpsState

# Check publishing credentials
az functionapp deployment list-publishing-credentials --name <function-app-name> --resource-group <rg-name>
```

## Running the Tests

### Prerequisites

- Azure PowerShell modules: `Az.Accounts`, `Az.Resources`, `Az.PolicyInsights`
- Authenticated Azure session
- Resource group `rg-azure-policy-testing` must exist
- Policy must be deployed and assigned

### Run All Tests

```powershell
Invoke-Pester -Path tests/function-app/FunctionApp.Integration-DenyFunctionAppAadOnly.Tests.ps1
```

### Run Specific Test Categories

```powershell
# Fast tests only
Invoke-Pester -Path tests/function-app/FunctionApp.Integration-DenyFunctionAppAadOnly.Tests.ps1 -Tag 'Fast'

# Documentation tests only
Invoke-Pester -Path tests/function-app/FunctionApp.Integration-DenyFunctionAppAadOnly.Tests.ps1 -Tag 'Documentation'

# Informational tests
Invoke-Pester -Path tests/function-app/FunctionApp.Integration-DenyFunctionAppAadOnly.Tests.ps1 -Tag 'Informational'
```

## Pre-commit Validation

✅ All pre-commit hooks pass:

- PowerShell syntax check
- PowerShell Script Analyzer
- Pester unit tests
- Secrets detection
- Test file naming convention

## Related Files

- **Unit Tests:** `tests/function-app/FunctionApp.Unit-DenyFunctionAppAadOnly.Tests.ps1`
- **Policy Definition:** `policies/function-app/deny-function-app-aad-only/rule.json`
- **Test Configuration:** `config/policies.json`

## Summary

✅ **Created comprehensive integration test** with 20 test cases
✅ **Validates policy definition, assignment, and compliance**
✅ **Includes extensive documentation and guidance**
✅ **Provides alternative validation methods**
✅ **Passes all pre-commit validation checks**

The integration test provides thorough validation of the AAD-only authentication policy while acknowledging its unique characteristics as a configuration resource policy.
