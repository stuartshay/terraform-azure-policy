# Using VS Code Test Panel with Pester Tests

This guide explains how to use the VS Code Test Panel with the Pester Test extension for running Azure Policy tests.

## 🧪 **Extension Setup**

### **Required Extension**

- **pspester.pester-test** - Pester Test extension for VS Code

### **Recommended Extensions**

- **ms-vscode.powershell** - PowerShell extension
- All other extensions are listed in `.vscode/extensions.json`

## 🎯 **Test Panel Overview**

The VS Code Test Panel provides a visual interface for running and debugging tests. With the Pester extension, you can:

- **View all tests** in a tree structure
- **Run individual tests** or test groups
- **Debug tests** with breakpoints
- **View test results** inline
- **Generate test reports** automatically

## 📋 **Test Structure in Panel**

### **Test Categories**

Tests are organized by tags for better filtering:

#### **🚀 Fast Tests** (`Unit`, `Fast`)

- `Quick-PolicyValidation.Tests.ps1` - JSON validation, no Azure required
- Policy definition structure validation
- Policy logic validation
- Simulated compliance scenarios

#### **🔗 Integration Tests** (`Integration`)

- `Deny-StorageAccountPublicAccess.Tests.ps1` - Full Azure integration
- Policy assignment validation
- Real resource compliance testing
- Policy remediation testing

#### **🐌 Slow Tests** (`Slow`)

- Tests that create Azure resources
- Tests that wait for policy evaluation
- Tests requiring cleanup

## 🎮 **Using the Test Panel**

### **Opening the Test Panel**

1. **View Menu**: `View` → `Testing`
2. **Command Palette**: `Ctrl+Shift+P` → "Test: Focus on Test Explorer View"
3. **Activity Bar**: Click the test beaker icon

### **Running Tests**

#### **Run All Tests**

- Click the ▶️ button at the top of the Test Panel
- Or use `Ctrl+Shift+P` → "Test: Run All Tests"

#### **Run Specific Test Category**

- Expand the test file in the panel
- Click ▶️ next to specific `Describe` blocks:
  - **Policy Definition Validation** (Fast)
  - **Policy Assignment Validation** (Integration)
  - **Policy Compliance Testing** (Slow)

#### **Run Individual Tests**

- Expand to specific `It` blocks
- Click ▶️ next to individual test cases

#### **Run by Tags**

Use Command Palette for tag-based execution:

- `Ctrl+Shift+P` → "Test: Run Tests in Current File"
- Filter by tags in terminal: `Invoke-Pester -Tag "Fast"`

### **Test Results**

#### **Visual Indicators**

- ✅ **Green checkmark** - Test passed
- ❌ **Red X** - Test failed  
- ⏩ **Gray arrow** - Test skipped
- 🔄 **Spinning** - Test running

#### **Detailed Results**

- Click on any test to see detailed output
- Failed tests show error messages and stack traces
- Duration and timing information included

## 🐛 **Debugging Tests**

### **Setting Breakpoints**

1. Open the test file (`.Tests.ps1`)
2. Click in the left margin to set breakpoints
3. Click the debug icon (🐛) next to the test in the panel

### **Debug Configurations**

Pre-configured debug options in `Run and Debug` panel:

- **PowerShell: Debug Pester Tests** - All tests with debugging
- **PowerShell: Debug Storage Policy Tests** - Storage tests only
- **PowerShell: Debug Quick Policy Tests** - Fast tests only

### **Debug Process**

1. Set breakpoints in test file
2. Click debug button in Test Panel
3. Test execution will pause at breakpoints
4. Use debug controls (step over, step into, continue)
5. Inspect variables in the debug sidebar

## ⚡ **Quick Start Workflow**

### **1. Fast Development Cycle**

```powershell
# Run quick validation tests (no Azure required)
tests/storage/Quick-PolicyValidation.Tests.ps1
```

- Tests JSON structure
- Validates policy logic
- No authentication needed
- Runs in seconds

### **2. Integration Testing**

```powershell
# Run full integration tests (requires Azure)
tests/storage/Deny-StorageAccountPublicAccess.Tests.ps1
```

- Tests actual Azure policy behavior
- Creates test resources
- Validates compliance
- Takes several minutes

### **3. Continuous Testing**

- Use **Test: Run All Tests** for complete validation
- Filter by tags for specific scenarios
- Use **Test: Watch Tests** for automatic re-runs

## 🔧 **Configuration**

### **Test Discovery Settings**

Configuration in `.vscode/settings.json`:

```json
{
    "pester.testFilePath": [
        "**/*.Tests.ps1",
        "**/tests/**/*.ps1"
    ],
    "pester.excludePath": [
        "**/reports/**",
        "**/config/**"
    ]
}
```

### **Pester Extension Settings**

```json
{
    "pester.useLegacyCodeLens": false,
    "pester.outputVerbosity": "Detailed",
    "pester.enableCodeLens": true,
    "pester.autoRefreshTests": true
}
```

### **Test Configuration**

Test settings are configured in:

- **`.vscode/settings.json`** - VS Code Pester extension settings
- **Individual test scripts** - Build their own Pester configurations inline

Configuration includes:

- Output formats and paths  
- Test discovery patterns
- Execution preferences

## 📊 **Test Reporting**

### **Built-in Reports**

The Test Panel automatically provides:

- **Test results summary** in the panel
- **Detailed output** for each test
- **Timing information** for performance analysis
- **Error details** with stack traces

### **Export Test Results**

Generate formal test reports:

```powershell
# XML report for CI/CD
./scripts/Invoke-PolicyTests.ps1 -OutputFormat "NUnitXml" -OutputPath "TestResults.xml"

# JUnit format for Jenkins/Azure DevOps
./scripts/Invoke-PolicyTests.ps1 -OutputFormat "JUnitXml" -OutputPath "TestResults-JUnit.xml"
```

### **Integration with CI/CD**

Test results XML files can be consumed by:

- **Azure DevOps** - Test Results publishing
- **GitHub Actions** - Test reporting
- **Jenkins** - Test result visualization

## 🚨 **Troubleshooting**

### **Tests Not Appearing**

1. **Check file patterns**: Ensure `.Tests.ps1` naming
2. **Reload window**: `Ctrl+Shift+P` → "Developer: Reload Window"  
3. **Check exclusions**: Verify paths aren't in `excludePath`
4. **Extension status**: Ensure Pester extension is enabled

### **Authentication Issues**

```powershell
# For integration tests, ensure Azure authentication
Connect-AzAccount
Set-AzContext -SubscriptionId "your-subscription-id"
```

### **Slow Test Performance**

- Use **Fast** tagged tests for quick feedback
- Run **Slow** tests only when needed
- Consider parallel execution for independent tests

### **Debug Not Working**

1. **PowerShell extension**: Ensure it's installed and enabled
2. **Breakpoints**: Set in test file, not in PowerShell console
3. **Debug configuration**: Use predefined launch configurations

## 📚 **Best Practices**

### **Test Organization**

- ✅ **Use descriptive test names**
- ✅ **Tag tests appropriately** (`Fast`, `Slow`, `Integration`)
- ✅ **Group related tests** in `Context` blocks
- ✅ **Keep fast tests separate** from slow ones

### **Development Workflow**

1. **Start with fast tests** - validate JSON and logic
2. **Run integration tests** - verify Azure behavior
3. **Use debugging** for complex test failures
4. **Generate reports** for documentation

### **Performance**

- 🚀 **Run fast tests frequently** during development
- 🐌 **Run slow tests periodically** or before commits
- 🔄 **Use watch mode** for automatic test execution
- 📊 **Monitor test duration** and optimize slow tests

## 🎯 **Example Workflows**

### **Policy Development**

1. Create/modify policy JSON
2. Run `Quick-PolicyValidation.Tests.ps1` (fast)
3. Fix any JSON/logic issues
4. Run full integration tests
5. Deploy and validate in Azure

### **Bug Investigation**

1. Set breakpoints in failing test
2. Run debug mode from Test Panel
3. Step through test execution
4. Inspect variables and Azure responses
5. Fix issue and re-run tests

### **CI/CD Integration**

1. Run all tests with CI flag: `Invoke-Pester -CI`
2. Generate XML reports for pipeline
3. Fail build on test failures
4. Publish test results to DevOps dashboard

The Test Panel provides a powerful, visual way to manage your Azure Policy testing workflow! 🎉
