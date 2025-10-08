#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates GitHub Copilot Environment Configuration
.DESCRIPTION
    Comprehensive validation script that checks:
    1. All required environment variables are set (ARM_* and TF_*)
    2. Azure connectivity using Service Principal authentication
    3. Azure resource access and permissions

    This script is designed to validate the GitHub Copilot environment
    configuration before running other scripts in the repository.
.PARAMETER SkipAzureConnectivityTest
    Skip the Azure connectivity test (only validate environment variables)
.PARAMETER Verbose
    Show detailed output during validation
.EXAMPLE
    ./scripts/Test-EnvironmentConfiguration.ps1

    Validates all environment variables and tests Azure connectivity
.EXAMPLE
    ./scripts/Test-EnvironmentConfiguration.ps1 -SkipAzureConnectivityTest

    Only validates environment variables without testing Azure connectivity
.NOTES
    Required Environment Variables:
    - ARM_CLIENT_ID: Service Principal Application (Client) ID
    - ARM_CLIENT_SECRET: Service Principal Secret
    - ARM_TENANT_ID: Azure AD Tenant ID
    - ARM_SUBSCRIPTION_ID: Azure Subscription ID
    - TF_API_TOKEN: Terraform Cloud API Token (optional)
    - TF_CLOUD_ORGANIZATION: Terraform Cloud Organization (optional)
#>

param(
    [switch]$SkipAzureConnectivityTest
)

# Script configuration
$ErrorActionPreference = 'Continue'
$script:ValidationPassed = $true
$script:Warnings = @()

# Helper function to write section headers
function Write-SectionHeader {
    param([string]$Title)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

# Helper function to track validation failures
function Set-ValidationFailed {
    param([string]$Message)
    $script:ValidationPassed = $false
    Write-Host "   ❌ $Message" -ForegroundColor Red
}

# Helper function to track warnings
function Add-ValidationWarning {
    param([string]$Message)
    $script:Warnings += $Message
    Write-Host "   ⚠️  $Message" -ForegroundColor Yellow
}

# Start validation
Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  GitHub Copilot Environment Configuration Validator   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# 1. Validate Azure Environment Variables
Write-SectionHeader "Validating Azure Environment Variables"

$azureVars = @{
    'ARM_CLIENT_ID'       = $env:ARM_CLIENT_ID
    'ARM_CLIENT_SECRET'   = $env:ARM_CLIENT_SECRET
    'ARM_TENANT_ID'       = $env:ARM_TENANT_ID
    'ARM_SUBSCRIPTION_ID' = $env:ARM_SUBSCRIPTION_ID
}

$missingAzureVars = @()
foreach ($var in $azureVars.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace($var.Value)) {
        $missingAzureVars += $var.Key
        Set-ValidationFailed "$($var.Key): Not set"
    } else {
        if ($var.Key -eq 'ARM_CLIENT_SECRET') {
            Write-Host "   ✅ $($var.Key): [HIDDEN]" -ForegroundColor Green
        } else {
            Write-Host "   ✅ $($var.Key): $($var.Value)" -ForegroundColor Green
        }
    }
}

# 2. Validate Terraform Cloud Environment Variables (Optional)
Write-SectionHeader "Validating Terraform Cloud Environment Variables"

$terraformVars = @{
    'TF_API_TOKEN'         = $env:TF_API_TOKEN
    'TF_CLOUD_ORGANIZATION' = $env:TF_CLOUD_ORGANIZATION
}

$hasTerraformVars = $false
foreach ($var in $terraformVars.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace($var.Value)) {
        Write-Host "   ℹ️  $($var.Key): Not set (optional)" -ForegroundColor Gray
    } else {
        $hasTerraformVars = $true
        if ($var.Key -eq 'TF_API_TOKEN') {
            Write-Host "   ✅ $($var.Key): [HIDDEN]" -ForegroundColor Green
        } else {
            Write-Host "   ✅ $($var.Key): $($var.Value)" -ForegroundColor Green
        }
    }
}

if (-not $hasTerraformVars) {
    Add-ValidationWarning "Terraform Cloud variables not configured (this is optional)"
}

# 3. Test Azure Connectivity (if not skipped)
if (-not $SkipAzureConnectivityTest) {
    Write-SectionHeader "Testing Azure Connectivity"

    if ($missingAzureVars.Count -gt 0) {
        Set-ValidationFailed "Cannot test Azure connectivity - missing required variables"
        Write-Host "`n   Missing variables:" -ForegroundColor Red
        foreach ($var in $missingAzureVars) {
            Write-Host "      - $var" -ForegroundColor Red
        }
    } else {
        # Check if Az PowerShell module is available
        $azModule = Get-Module -ListAvailable -Name Az.Accounts -ErrorAction SilentlyContinue

        if (-not $azModule) {
            Add-ValidationWarning "Azure PowerShell modules not installed"
            Write-Host "`n   💡 To install Azure PowerShell modules:" -ForegroundColor Yellow
            Write-Host "      ./scripts/Install-Requirements.ps1" -ForegroundColor Yellow
            Write-Host "`n   ℹ️  Skipping Azure connectivity test" -ForegroundColor Gray
        } else {
            Write-Host "   🔐 Authenticating to Azure..." -ForegroundColor Cyan

            try {
                # Import Az.Accounts module
                Import-Module Az.Accounts -ErrorAction Stop

                # Check if already connected
                $azContext = Get-AzContext -ErrorAction SilentlyContinue

                if (-not $azContext) {
                    # Authenticate using Service Principal
                    $securePassword = ConvertTo-SecureString $env:ARM_CLIENT_SECRET -AsPlainText -Force
                    $credential = New-Object System.Management.Automation.PSCredential($env:ARM_CLIENT_ID, $securePassword)

                    $null = Connect-AzAccount -ServicePrincipal `
                        -Credential $credential `
                        -Tenant $env:ARM_TENANT_ID `
                        -Subscription $env:ARM_SUBSCRIPTION_ID `
                        -ErrorAction Stop `
                        -WarningAction SilentlyContinue
                }

                $context = Get-AzContext
                Write-Host "   ✅ Successfully connected to Azure" -ForegroundColor Green
                Write-Host "      Subscription: $($context.Subscription.Name)" -ForegroundColor White
                Write-Host "      Tenant: $($context.Tenant.Id)" -ForegroundColor White
                Write-Host "      Account: $($context.Account.Id)" -ForegroundColor White

                # Test permissions
                Write-Host "`n   🔍 Testing Azure permissions..." -ForegroundColor Cyan
                try {
                    $rgCount = (Get-AzResourceGroup -ErrorAction Stop).Count
                    Write-Host "   ✅ Can access $rgCount resource group(s)" -ForegroundColor Green

                    # Check for testing resource group
                    $testRgName = 'rg-azure-policy-testing'
                    $testRg = Get-AzResourceGroup -Name $testRgName -ErrorAction SilentlyContinue
                    if ($testRg) {
                        Write-Host "   ✅ Testing resource group '$testRgName' exists" -ForegroundColor Green
                    } else {
                        Add-ValidationWarning "Testing resource group '$testRgName' not found (will be created when needed)"
                    }
                } catch {
                    Add-ValidationWarning "Limited permissions or no resource groups accessible: $($_.Exception.Message)"
                }

            } catch {
                Set-ValidationFailed "Failed to authenticate to Azure: $($_.Exception.Message)"

                if ($_.Exception.Message -like '*AADSTS*') {
                    Write-Host "`n   💡 Troubleshooting tips:" -ForegroundColor Yellow
                    Write-Host "      1. Verify Service Principal credentials are correct" -ForegroundColor Yellow
                    Write-Host "      2. Ensure Service Principal has not expired" -ForegroundColor Yellow
                    Write-Host "      3. Check Service Principal has access to the subscription" -ForegroundColor Yellow
                }
            }
        }
    }
} else {
    Write-SectionHeader "Azure Connectivity Test"
    Write-Host "   ⏭️  Skipped (use without -SkipAzureConnectivityTest to test)" -ForegroundColor Gray
}

# 4. Validation Summary
Write-SectionHeader "Validation Summary"

if ($script:ValidationPassed) {
    Write-Host "   ✅ Environment configuration is valid!" -ForegroundColor Green

    if ($script:Warnings.Count -gt 0) {
        Write-Host "`n   ⚠️  Warnings ($($script:Warnings.Count)):" -ForegroundColor Yellow
        foreach ($warning in $script:Warnings) {
            Write-Host "      - $warning" -ForegroundColor Yellow
        }
    }

    Write-Host "`n   📝 Next steps:" -ForegroundColor Cyan
    Write-Host "      - Run storage tests: ./scripts/Run-StorageTest.ps1" -ForegroundColor White
    Write-Host "      - Test policy compliance: ./scripts/Test-PolicyCompliance.ps1" -ForegroundColor White
    Write-Host "      - Deploy policies: ./scripts/Deploy-PolicyDefinitions.ps1" -ForegroundColor White

    exit 0
} else {
    Write-Host "   ❌ Environment configuration validation failed!" -ForegroundColor Red

    Write-Host "`n   📋 Required actions:" -ForegroundColor Yellow
    Write-Host "      1. Set missing environment variables in GitHub Codespaces/Actions secrets" -ForegroundColor Yellow
    Write-Host "      2. For Codespaces: https://github.com/settings/codespaces" -ForegroundColor Yellow
    Write-Host "      3. For Repository: https://github.com/<owner>/<repo>/settings/secrets/actions" -ForegroundColor Yellow
    Write-Host "      4. For Environments: https://github.com/<owner>/<repo>/settings/environments" -ForegroundColor Yellow

    if ($script:Warnings.Count -gt 0) {
        Write-Host "`n   ⚠️  Warnings ($($script:Warnings.Count)):" -ForegroundColor Yellow
        foreach ($warning in $script:Warnings) {
            Write-Host "      - $warning" -ForegroundColor Yellow
        }
    }

    exit 1
}
