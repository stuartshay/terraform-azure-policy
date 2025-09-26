# PowerShell Configuration for Azure Policy Testing

This document describes the PowerShell configuration and setup for the Azure Policy Testing project.

## Overview

The PowerShell configuration includes:
- **PowerShell Profile**: Custom functions and aliases for Azure policy operations
- **VS Code Settings**: Optimized settings for PowerShell development
- **Utility Scripts**: Automation scripts for common policy testing tasks
- **Module Requirements**: Defined dependencies with version management
- **Code Quality**: PSScriptAnalyzer configuration for consistent code formatting

## Quick Start

### 1. Install Required Modules
```powershell
./scripts/Install-Requirements.ps1 -IncludeOptional
```

### 2. Load the PowerShell Profile
```powershell
. ./PowerShell/Microsoft.PowerShell_profile.ps1
```

### 3. Initialize Azure Environment
```powershell
Initialize-AzurePolicyProject
# or use the alias
init-azure
```

## PowerShell Profile Features

The PowerShell profile (`PowerShell/Microsoft.PowerShell_profile.ps1`) provides:

### Custom Functions
- **`Test-AzurePolicyCompliance`** (alias: `tpc`) - Test policy compliance for a specific scope
- **`Deploy-AzurePolicyDefinition`** (alias: `dpd`) - Deploy policy definitions from JSON files
- **`Get-PolicyComplianceReport`** (alias: `gcr`) - Generate compliance reports
- **`Initialize-AzurePolicyProject`** (alias: `init-azure`) - Initialize the project environment

### Example Usage
```powershell
# Test policy compliance
tpc -PolicyName "MyPolicy" -Scope "/subscriptions/12345678-1234-1234-1234-123456789012"

# Deploy a policy definition
dpd -PolicyFile "./policies/my-policy.json" -ManagementGroupId "mg-01"

# Generate compliance report
gcr -Scope "/subscriptions/12345678-1234-1234-1234-123456789012"
```

## Utility Scripts

### 1. Validate Policy Definitions
```powershell
./scripts/Validate-PolicyDefinitions.ps1 -PolicyPath "./policies"
```
Validates JSON syntax and structure of policy definition files.

### 2. Deploy Policy Definitions
```powershell
# What-if deployment (dry run)
./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath "./policies" -WhatIf

# Actual deployment
./scripts/Deploy-PolicyDefinitions.ps1 -PolicyPath "./policies" -ManagementGroupId "mg-01"
```

### 3. Test Policy Compliance
```powershell
# Generate table report
./scripts/Test-PolicyCompliance.ps1 -OutputFormat "Table"

# Export to JSON
./scripts/Test-PolicyCompliance.ps1 -OutputFormat "JSON" -ExportPath "./reports/compliance.json"

# Test specific policy
./scripts/Test-PolicyCompliance.ps1 -PolicyName "MyPolicy" -OutputFormat "CSV" -ExportPath "./reports/my-policy-compliance.csv"
```

## VS Code Integration

### Tasks Available
Use `Ctrl+Shift+P` and type "Tasks: Run Task" to access:

1. **Install PowerShell Requirements** - Install all required PowerShell modules
2. **Validate Policy Definitions** - Validate all policy JSON files
3. **Deploy Policy Definitions (What-If)** - Preview deployment changes
4. **Deploy Policy Definitions** - Deploy policies to Azure
5. **Test Policy Compliance** - Run compliance tests
6. **Run PSScriptAnalyzer** - Analyze PowerShell code quality
7. **Initialize Azure Policy Project** - Set up the project environment
8. **Format PowerShell Files** - Auto-format PowerShell scripts

### Settings Highlights
- **PowerShell Extension**: Configured for optimal development experience
- **Code Formatting**: Automatic formatting on save with consistent style
- **Script Analysis**: Real-time code analysis with PSScriptAnalyzer
- **Terminal Integration**: PowerShell as default terminal with project profile loaded

## Module Requirements

The project uses these key PowerShell modules:

### Required Modules
- **Az.Accounts** (2.12.1) - Azure authentication
- **Az.Resources** (6.6.0) - Policy definition management
- **Az.PolicyInsights** (1.6.1) - Compliance testing
- **PSScriptAnalyzer** (1.21.0) - Code analysis
- **Pester** (5.4.0) - Testing framework

### Optional Modules
- **Az.ResourceGraph** (0.13.0) - Advanced queries
- **ImportExcel** (7.8.4) - Excel reporting
- **PSWriteColor** (1.0.1) - Enhanced console output

## Configuration Files

### Environment Variables
Set these in your environment or `.env` file:
```bash
ARM_SUBSCRIPTION_ID=your-subscription-id
ARM_MANAGEMENT_GROUP_ID=your-management-group-id
```

### Terraform Variables
Update `config/vars/sandbox.tfvars.json`:
```json
{
   "subcription_id": "your-subscription-id",
   "mangement_group_id": "your-management-group-id",
   "scope_id": "/providers/Microsoft.Management/managementGroups/your-management-group-id"
}
```

## Code Quality

### PSScriptAnalyzer Rules
The project uses comprehensive code analysis rules:
- **Compatibility**: Multi-version PowerShell support
- **Formatting**: Consistent indentation and whitespace
- **Security**: Password and security best practices
- **Performance**: Efficient PowerShell patterns
- **Best Practices**: Approved verbs, proper casing, comment-based help

### Custom Rules
Some rules are customized for this project:
- `PSAvoidUsingWriteHost` is disabled (we use colored console output)
- `PSUseShouldProcessForStateChangingFunctions` is disabled for utility functions

## Troubleshooting

### Module Installation Issues
```powershell
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Trust PowerShell Gallery
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

# Force reinstall modules
./scripts/Install-Requirements.ps1 -Force -IncludeOptional
```

### Azure Authentication
```powershell
# Connect to Azure
Connect-AzAccount

# Select subscription
Set-AzContext -SubscriptionId "your-subscription-id"

# Verify connection
Get-AzContext
```

### VS Code PowerShell Extension
If you encounter issues:
1. Install the PowerShell extension for VS Code
2. Restart VS Code after installing modules
3. Check the PowerShell Integrated Console output for errors
4. Verify the PowerShell execution policy allows script execution

## Best Practices

### PowerShell Development
1. **Always use approved verbs** for function names
2. **Include comment-based help** for all functions
3. **Use proper error handling** with try/catch blocks
4. **Follow consistent formatting** (automatic with our settings)
5. **Test scripts** before committing to version control

### Azure Policy Development
1. **Validate JSON syntax** before deployment
2. **Use What-If deployments** to preview changes
3. **Test compliance** after policy deployment
4. **Document policy purpose** and parameters
5. **Use version control** for all policy definitions

## Project Structure

```
azure-policy-testing/
├── .vscode/
│   ├── settings.json              # VS Code PowerShell settings
│   ├── tasks.json                 # Build and test tasks
│   └── PSScriptAnalyzerSettings.psd1  # Code analysis rules
├── PowerShell/
│   └── Microsoft.PowerShell_profile.ps1  # PowerShell profile
├── scripts/
│   ├── Install-Requirements.ps1   # Module installation
│   ├── Validate-PolicyDefinitions.ps1  # Policy validation
│   ├── Deploy-PolicyDefinitions.ps1    # Policy deployment
│   └── Test-PolicyCompliance.ps1       # Compliance testing
├── config/
│   ├── backend/
│   │   └── sandbox.tfbackend      # Terraform backend config
│   └── vars/
│       └── sandbox.tfvars.json    # Terraform variables
├── policies/                      # Azure policy definitions (JSON)
├── tests/                         # Test files
└── requirements.psd1              # PowerShell module requirements
```

This configuration provides a comprehensive PowerShell development environment optimized for Azure policy testing and development.