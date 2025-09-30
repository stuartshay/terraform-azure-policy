# Azure Policy Tests

This directory contains comprehensive Pester tests for validating Azure Policy definitions and testing their compliance behavior.

## 📋 Test Structure

```text
tests/
├── storage/
│   └── Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1    # Storage policy tests
├── network/                                          # Network policy tests (future)
├── PolicyTestConfig.ps1                              # Test configuration
└── README.md                                         # This file
```

## 🚀 Quick Start

### Prerequisites

1. **PowerShell Modules** (installed automatically by `Install-Requirements.ps1`):
   - Pester (v5+)
   - Az.Accounts
   - Az.Resources
   - Az.Storage
   - Az.PolicyInsights

2. **Azure Authentication**:

   ```powershell
   Connect-AzAccount
   ```

3. **Resource Group**: Ensure `rg-azure-policy-testing` exists and has policies assigned.

### Running Tests

#### Option 1: VS Code Tasks (Recommended)

1. Open Command Palette (`Ctrl+Shift+P`)
2. Select "Tasks: Run Task"
3. Choose one of:
   - **"Run Policy Tests"** - All policy tests
   - **"Run Storage Policy Tests"** - Only storage tests with XML output

#### Option 2: PowerShell Script

```powershell
# Run all tests
./scripts/Invoke-PolicyTests.ps1

# Run specific test category
./scripts/Invoke-PolicyTests.ps1 -TestPath "tests/storage"

# Generate test report
./scripts/Invoke-PolicyTests.ps1 -OutputFormat "NUnitXml" -OutputPath "TestResults.xml"
```

#### Option 3: Direct Pester

```powershell
# Run specific test file
Invoke-Pester -Path "tests/storage/Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1"
```

## 🧪 Test Categories

### Storage Policy Tests (`tests/storage/`)

The storage policy tests validate the "Deny Storage Account Public Access" policy:

#### Test Scenarios

1. **Policy Definition Validation**
   - JSON structure validation
   - Property checks (displayName, description, policyRule)
   - Resource type targeting validation
   - Condition logic verification

2. **Policy Assignment Validation**
   - Verifies policy is assigned to target resource group
   - Validates assignment scope and configuration

3. **Compliance Testing**
   - Creates compliant storage account (public access disabled)
   - Creates non-compliant storage account (public access enabled)
   - Validates policy evaluation results
   - Tests remediation scenarios

4. **Policy Evaluation Details**
   - Displays detailed compliance information
   - Shows policy state for all resources

#### What the Tests Do

**✅ Compliant Test Scenario:**

- Creates storage account with:
  - `AllowBlobPublicAccess = $false`
  - `PublicNetworkAccess = "Disabled"`
- Validates it shows as "Compliant" in policy evaluation

**❌ Non-Compliant Test Scenario:**

- Creates storage account with:
  - `AllowBlobPublicAccess = $true`
  - `PublicNetworkAccess = "Enabled"`
- Validates it shows as "NonCompliant" in policy evaluation

**🔧 Remediation Test:**

- Updates non-compliant storage account to be compliant
- Verifies policy re-evaluation shows improved compliance

## 📊 Test Output

### Console Output

Tests provide detailed console output including:

- Test progress and results
- Azure resource creation/deletion status
- Policy compliance states
- Cleanup operations

### XML Reports

When using `-OutputFormat "NUnitXml"`, tests generate XML reports compatible with:

- Azure DevOps Test Results
- Jenkins Test Results
- GitHub Actions Test Reports

### Example Output

```text
Running Azure Policy tests...
Target: tests/storage
Resource Group: rg-azure-policy-testing

Describing Policy Definition Validation
  Context Policy JSON Structure
    [+] Should have valid policy definition structure 45ms (44ms|1ms)
    [+] Should have correct display name 12ms (11ms|1ms)
    [+] Should have description 8ms (7ms|1ms)
    [+] Should target Microsoft.Storage/storageAccounts resource type 15ms (14ms|1ms)

Describing Policy Assignment Validation
  Context Policy Assignment Exists
    [+] Should have policy assigned to resource group 234ms (233ms|1ms)
    [+] Should be assigned at resource group scope 45ms (44ms|1ms)

Describing Policy Compliance Testing
  Context Storage Account Compliance Scenarios
    [+] Should create compliant storage account (public access disabled) 2.1s (2.09s|10ms)
    [+] Should create non-compliant storage account (public access enabled) 1.8s (1.79s|11ms)
    [+] Should wait for policy evaluation to complete 1m (60s|4ms)

Test Summary:
  Total Tests: 12
  Passed: 11
  Failed: 0
  Skipped: 1
  Duration: 00:02:15
```

## ⚙️ Configuration

### Test Configuration (`PolicyTestConfig.ps1`)

Modify test behavior by updating configuration values:

```powershell
$TestConfig = @{
    ResourceGroup = "rg-azure-policy-testing"           # Target RG
    PolicyName = "deny-storage-account-public-access"   # Policy name
    StorageAccountPrefix = "testpolicysa"               # Test SA prefix
    PolicyEvaluationWaitSeconds = 60                    # Wait time for evaluation
    CleanupTestResources = $true                        # Auto-cleanup test resources
    SkipLongRunningTests = $false                       # Skip time-intensive tests
}
```

### Environment Variables

Tests respect these environment variables if set:

- `AZURE_POLICY_TEST_RESOURCE_GROUP` - Override target resource group
- `AZURE_POLICY_TEST_SUBSCRIPTION_ID` - Override subscription ID

## 🧹 Test Cleanup

Tests automatically clean up resources they create:

- **Test Storage Accounts** - Removed in `AfterAll` block
- **Temporary Resources** - Cleaned up after each test context

To disable cleanup (for debugging):

```powershell
# Edit PolicyTestConfig.ps1
$TestConfig.CleanupTestResources = $false
```

## 🚨 Troubleshooting

### Common Issues

#### ❌ "No Azure context found"

```powershell
# Solution: Authenticate to Azure
Connect-AzAccount
Set-AzContext -SubscriptionId "your-subscription-id"
```

#### ❌ "Resource group not found"

```powershell
# Solution: Create the resource group or update configuration
New-AzResourceGroup -Name "rg-azure-policy-testing" -Location "East US"
```

#### ❌ "Policy assignment not found"

- Ensure the policy is deployed via Terraform
- Check policy assignment scope matches test configuration

#### ❌ "Compliance state not available"

- Azure Policy evaluation can take time (up to 30 minutes)
- Tests include wait periods, but may need longer for initial runs
- Use `Start-AzPolicyComplianceScan` to trigger immediate evaluation

### Debugging Tests

1. **Run tests individually:**

   ```powershell
   Invoke-Pester -Path "tests/storage/Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1" -Tag "PolicyDefinition"
   ```

2. **Enable verbose output:**

   ```powershell
   $VerbosePreference = "Continue"
   ./scripts/Invoke-PolicyTests.ps1 -TestPath "tests/storage"
   ```

3. **Disable cleanup for inspection:**

   ```powershell
   # Edit PolicyTestConfig.ps1
   $TestConfig.CleanupTestResources = $false
   ```

## 📝 Adding New Tests

### Creating New Policy Tests

1. **Create test file**: `tests/[category]/[PolicyName].Tests.ps1`
2. **Follow naming convention**: `[Action]-[Resource][Condition].Tests.ps1`
3. **Use template structure**:

   ```powershell
   #Requires -Modules Pester, Az.Accounts, Az.Resources

   BeforeAll {
       # Test setup
   }

   Describe "Policy Definition Validation" {
       # Validate JSON structure
   }

   Describe "Policy Assignment Validation" {
       # Validate assignment exists and is configured correctly
   }

   Describe "Policy Compliance Testing" {
       # Test actual compliance scenarios
   }

   AfterAll {
       # Cleanup
   }
   ```

4. **Update VS Code tasks** if needed
5. **Update this README** with new test documentation

### Test Best Practices

- ✅ **Always clean up resources** in `AfterAll`
- ✅ **Use unique resource names** with timestamps
- ✅ **Include both compliant and non-compliant scenarios**
- ✅ **Wait for policy evaluation** before checking compliance
- ✅ **Provide informative test descriptions**
- ✅ **Handle API delays and eventual consistency**
- ✅ **Use `-Skip` for tests that require specific conditions**

## 📚 References

- [Pester Documentation](https://pester.dev/)
- [Azure Policy REST API](https://docs.microsoft.com/en-us/rest/api/policy/)
- [Azure PowerShell Policy Cmdlets](https://docs.microsoft.com/en-us/powershell/module/az.resources/)
- [Azure Policy Compliance](https://docs.microsoft.com/en-us/azure/governance/policy/how-to/get-compliance-data)
