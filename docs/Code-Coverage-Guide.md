# Code Coverage Implementation Guide

## Overview

This document describes the implementation of code coverage tools for the Azure Policy Testing project. We've implemented comprehensive coverage analysis using **Pester** (for PowerShell) with additional support for external coverage tools.

## 🛠️ **Implemented Coverage Tools**

### 1. **Pester Code Coverage (Primary)**

**What it covers:**

- PowerShell scripts in `/scripts/` directory
- PowerShell modules in `/PowerShell/` directory
- Custom functions and cmdlets

**Features:**

- ✅ Native PowerShell integration
- ✅ JaCoCo XML format output
- ✅ Configurable coverage targets
- ✅ CI/CD integration
- ✅ HTML report generation (via ReportGenerator)

### 2. **Terraform Coverage (Checkov Integration)**

**What it covers:**

- Terraform configuration files
- Policy JSON structure validation
- Security best practice compliance

**Features:**

- ✅ Already integrated via Checkov reports
- ✅ Excel reporting with detailed metrics
- ✅ 841+ Azure policies tracked

## 📊 **Usage Examples**

### **Local Development**

```powershell
# Run tests with coverage (basic)
./scripts/Invoke-PolicyTests-WithCoverage.ps1

# Run with specific coverage target
./scripts/Invoke-PolicyTests-WithCoverage.ps1 -CoverageTarget 85

# Generate HTML coverage report
./scripts/Invoke-PolicyTests-WithCoverage.ps1 -GenerateHtmlReport

# Run only fast tests with coverage
./scripts/Invoke-PolicyTests-WithCoverage.ps1 -TestPath "tests/storage/Storage.Unit-DenyStorageAccountPublicAccess.Tests.ps1,tests/network"
```

### **VS Code Integration**

Use the Command Palette (`Ctrl+Shift+P`) → "Tasks: Run Task":

- **"Run Policy Tests with Coverage"** - Full test suite with 80% target
- **"Run Fast Tests with Coverage"** - Quick tests with 75% target  
- **"Generate Coverage HTML Report"** - Creates browsable HTML report

### **CI/CD Pipeline**

The GitHub Actions workflow automatically:

- Runs unit tests with coverage analysis
- Uploads coverage reports as artifacts
- Publishes test results
- Fails builds if coverage drops below threshold

## 📁 **Coverage Reports Location**

All coverage reports are saved to the `reports/` directory:

```text
reports/
├── TestResults.xml          # JUnit test results
├── coverage_YYYYMMDD_HHMMSS.xml  # JaCoCo coverage data
├── coverage-html/           # HTML coverage reports
│   ├── index.html          # Main coverage report
│   └── ...                 # Detailed file reports
└── azure_checkov_policies_report_*.xlsx  # Terraform/Policy coverage
```

## 🎯 **Coverage Targets**

| Test Type | Coverage Target | Description |
|-----------|----------------|-------------|
| **Unit Tests** | 75% | Fast tests without Azure deps |
| **Integration Tests** | 80% | Full test suite with Azure |
| **CI Pipeline** | 70% | Minimum for automated builds |
| **Release** | 85% | Target for production releases |

## 📈 **Coverage Metrics**

### **PowerShell Script Coverage**

Tracks coverage for:

- Policy validation scripts
- Test utility functions
- Azure deployment scripts
- Report generation tools

### **Policy Definition Coverage**

Via Checkov integration:

- **841 Azure policies** mapped to Checkov rules
- **197 unique resource types** covered
- **3 platforms**: Terraform, ARM, Bicep

## 🔧 **Configuration Files**

### **Pester Configuration with Coverage**

```powershell
# PesterConfiguration.Coverage.ps1
$PesterPreference = [PesterConfiguration]@{
    CodeCoverage = @{
        Enabled = $true
        OutputFormat = 'JaCoCo'
        OutputPath = "$PSScriptRoot/reports/coverage.xml"
        Path = @(
            "$PSScriptRoot/scripts/*.ps1"
            "$PSScriptRoot/PowerShell/*.ps1"
        )
        ExcludeTests = $true
        CoveragePercentTarget = 80.0
    }
}
```

### **VS Code Tasks**

Three new tasks added for coverage analysis:

- `Run Policy Tests with Coverage`
- `Run Fast Tests with Coverage`  
- `Generate Coverage HTML Report`

## 🚀 **Quick Start**

1. **Install dependencies:**

   ```powershell
   ./scripts/Install-Requirements.ps1 -IncludeOptional
   ```

2. **Run coverage analysis:**

   ```powershell
   ./scripts/Invoke-PolicyTests-WithCoverage.ps1 -GenerateHtmlReport
   ```

3. **View results:**
   - **Console**: Coverage summary displayed during test run
   - **XML**: `reports/coverage_*.xml` for CI/CD integration
   - **HTML**: `reports/coverage-html/index.html` for detailed analysis

## 📊 **Integration with External Tools**

### **SonarQube Integration**

```yaml
# In your sonar-project.properties
sonar.coverage.jacoco.xmlReportPaths=reports/coverage.xml
sonar.testExecutionReportPaths=reports/TestResults.xml
```

### **Azure DevOps Integration**

```yaml
- task: PublishTestResults@2
  inputs:
    testResultsFormat: 'JUnit'
    testResultsFiles: 'reports/TestResults.xml'

- task: PublishCodeCoverageResults@1
  inputs:
    codeCoverageTool: 'JaCoCo'
    summaryFileLocation: 'reports/coverage.xml'
```

### **GitHub Actions (Already Configured)**

Coverage reports are automatically:

- Generated during CI builds
- Uploaded as artifacts
- Published to GitHub's test reporting

## 🎨 **Coverage Report Features**

### **Console Output**

```pwsh
=== Code Coverage Summary ===
  Coverage Percentage: 82.5%
  Covered Commands: 165
  Total Commands: 200
  Missed Commands: 35

  Files with missed coverage:
    Generate-PolicyReports.ps1: 12 missed commands
    Deploy-PolicyDefinitions.ps1: 8 missed commands
```

### **HTML Reports**

- **Interactive navigation** through source files
- **Line-by-line coverage** highlighting
- **Coverage trends** and historical data
- **Filterable by file/directory**

## 🚨 **Troubleshooting**

### **Coverage Not Generated**

1. **Check PowerShell version**: Requires PowerShell 5.1+ or PowerShell Core 6+
2. **Verify Pester version**: Requires Pester 5.4.0+
3. **File paths**: Ensure scripts exist in `scripts/` and `PowerShell/` directories

### **Low Coverage Numbers**

1. **Exclude test files**: Coverage configuration excludes `.Tests.ps1` files
2. **Include utility scripts**: Add more script paths to coverage configuration
3. **Mock external dependencies**: Use Pester mocking for Azure cmdlets

### **HTML Report Generation Fails**

1. **Install ReportGenerator**:

   ```bash
   dotnet tool install --global dotnet-reportgenerator-globaltool
   ```

2. **Check .NET availability**: Requires .NET SDK 6.0+

## 📚 **Additional Tools to Consider**

### **For Infrastructure Coverage**

- **Terraform Coverage**: Use `terraform plan` with coverage analysis
- **Infrastructure Testing**: Consider using **Terratest** for Go-based infrastructure tests

### **For Security Coverage**

- **Checkov**: Already integrated for policy coverage
- **PSScriptAnalyzer**: Integrated for PowerShell code quality
- **Secret scanning**: Integrated via pre-commit hooks

### **For Documentation Coverage**

- **PowerShell Help**: Use `Get-Help` validation for function documentation
- **Terraform Docs**: Automated via pre-commit hooks

## 🎯 **Coverage Goals**

### **Short Term (Current)**

- ✅ PowerShell script coverage with Pester
- ✅ Policy definition coverage via Checkov  
- ✅ CI/CD integration with reporting

### **Medium Term (Next Quarter)**

- 🔄 Infrastructure testing with Terratest
- 🔄 End-to-end policy compliance testing
- 🔄 Performance benchmarking

### **Long Term (Future)**

- 🔄 Multi-cloud policy coverage
- 🔄 Advanced security scanning integration
- 🔄 Automated coverage trend analysis

---

**Next Steps**: Run `./scripts/Invoke-PolicyTests-WithCoverage.ps1 -GenerateHtmlReport` to see your first coverage report!
