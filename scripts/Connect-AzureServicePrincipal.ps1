#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Authenticates to Azure using Service Principal credentials from environment variables
.DESCRIPTION
    This script is designed for CI/CD and Codespaces environments where Azure credentials
    are stored as environment variables (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID).
    It will authenticate to Azure and establish an Azure context for use in the current session.
.PARAMETER Force
    Force re-authentication even if already connected to Azure
.EXAMPLE
    ./scripts/Connect-AzureServicePrincipal.ps1

    Authenticates to Azure using environment variables
.EXAMPLE
    ./scripts/Connect-AzureServicePrincipal.ps1 -Force

    Forces re-authentication even if already connected
.NOTES
    Required Environment Variables:
    - ARM_CLIENT_ID: Service Principal Application (Client) ID
    - ARM_CLIENT_SECRET: Service Principal Secret
    - ARM_TENANT_ID: Azure AD Tenant ID
    - ARM_SUBSCRIPTION_ID: Azure Subscription ID
#>

param(
    [switch]$Force
)

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host '  Azure Service Principal Login' -ForegroundColor Cyan
Write-Host '=====================================' -ForegroundColor Cyan

# Check if already connected
if (-not $Force) {
    $azContext = Get-AzContext -ErrorAction SilentlyContinue

    if ($azContext) {
        Write-Host "`n✅ Already connected to Azure" -ForegroundColor Green
        Write-Host "   Subscription: $($azContext.Subscription.Name) ($($azContext.Subscription.Id))" -ForegroundColor Cyan
        Write-Host "   Tenant: $($azContext.Tenant.Id)" -ForegroundColor Cyan
        Write-Host "   Account: $($azContext.Account.Id)" -ForegroundColor Cyan
        Write-Host "`nUse -Force parameter to re-authenticate" -ForegroundColor Yellow
        return
    }
}

# Validate environment variables
Write-Host "`n🔍 Checking environment variables..." -ForegroundColor Cyan

$requiredVars = @{
    'ARM_CLIENT_ID'       = $env:ARM_CLIENT_ID
    'ARM_CLIENT_SECRET'   = $env:ARM_CLIENT_SECRET
    'ARM_TENANT_ID'       = $env:ARM_TENANT_ID
    'ARM_SUBSCRIPTION_ID' = $env:ARM_SUBSCRIPTION_ID
}

$missingVars = @()
foreach ($var in $requiredVars.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace($var.Value)) {
        $missingVars += $var.Key
        Write-Host "   ❌ $($var.Key): Not set" -ForegroundColor Red
    } else {
        if ($var.Key -eq 'ARM_CLIENT_SECRET') {
            Write-Host "   ✅ $($var.Key): [HIDDEN]" -ForegroundColor Green
        } else {
            Write-Host "   ✅ $($var.Key): $($var.Value)" -ForegroundColor Green
        }
    }
}

if ($missingVars.Count -gt 0) {
    Write-Host "`n❌ Missing required environment variables:" -ForegroundColor Red
    foreach ($var in $missingVars) {
        Write-Host "   - $var" -ForegroundColor Red
    }
    Write-Host "`nPlease set these variables in your GitHub repository secrets or Codespaces secrets." -ForegroundColor Yellow
    Write-Host 'For Codespaces: https://github.com/settings/codespaces' -ForegroundColor Yellow
    Write-Host 'For Repository: https://github.com/<owner>/<repo>/settings/secrets/actions' -ForegroundColor Yellow
    exit 1
}

# Authenticate to Azure
Write-Host "`n🔐 Authenticating to Azure using Service Principal..." -ForegroundColor Cyan

try {
    # Convert client secret to secure string
    # Note: Using -AsPlainText is acceptable here as the secret comes from secure environment variables (GitHub Secrets/Codespaces Secrets)
    # PSScriptAnalyzer: The secret is already exposed in the environment variable - this is the standard pattern for CI/CD service principal auth
    $securePassword = ConvertTo-SecureString $env:ARM_CLIENT_SECRET -AsPlainText -Force  # pragma: allowlist secret
    $credential = New-Object System.Management.Automation.PSCredential($env:ARM_CLIENT_ID, $securePassword)

    # Connect to Azure
    $null = Connect-AzAccount -ServicePrincipal `
        -Credential $credential `
        -Tenant $env:ARM_TENANT_ID `
        -Subscription $env:ARM_SUBSCRIPTION_ID `
        -ErrorAction Stop `
        -WarningAction SilentlyContinue

    Write-Host "`n✅ Successfully authenticated to Azure!" -ForegroundColor Green

    # Display connection details
    $context = Get-AzContext
    Write-Host "`n📋 Connection Details:" -ForegroundColor Cyan
    Write-Host "   Subscription: $($context.Subscription.Name)" -ForegroundColor White
    Write-Host "   Subscription ID: $($context.Subscription.Id)" -ForegroundColor White
    Write-Host "   Tenant: $($context.Tenant.Id)" -ForegroundColor White  # pragma: allowlist secret
    Write-Host "   Account: $($context.Account.Id)" -ForegroundColor White
    Write-Host "   Environment: $($context.Environment.Name)" -ForegroundColor White

    # Verify permissions by checking resource groups
    Write-Host "`n🔍 Verifying permissions..." -ForegroundColor Cyan
    try {
        $rgCount = (Get-AzResourceGroup -ErrorAction Stop).Count
        Write-Host "   ✅ Can access $rgCount resource group(s)" -ForegroundColor Green

        # Check for the testing resource group
        $testRgName = 'rg-azure-policy-testing'
        $testRg = Get-AzResourceGroup -Name $testRgName -ErrorAction SilentlyContinue
        if ($testRg) {
            Write-Host "   ✅ Testing resource group '$testRgName' exists" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Testing resource group '$testRgName' not found" -ForegroundColor Yellow
            Write-Host '      (Will be created automatically when running tests)' -ForegroundColor Gray
        }
    } catch {
        Write-Host '   ⚠️  Warning: Limited permissions or no resource groups accessible' -ForegroundColor Yellow
        Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Gray
    }

    Write-Host "`n✅ Azure authentication setup complete!" -ForegroundColor Green
    Write-Host "`n📝 You can now run your Azure scripts:" -ForegroundColor Cyan
    Write-Host '   - ./scripts/Run-StorageTest.ps1' -ForegroundColor White
    Write-Host '   - ./scripts/Test-PolicyCompliance.ps1' -ForegroundColor White
    Write-Host '   - ./scripts/Deploy-PolicyDefinitions.ps1' -ForegroundColor White
    Write-Host ''
} catch {
    Write-Host "`n❌ Failed to authenticate to Azure" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red

    if ($_.Exception.Message -like '*AADSTS*') {
        Write-Host "`n💡 Troubleshooting tips:" -ForegroundColor Yellow
        Write-Host '   1. Verify the Service Principal credentials are correct' -ForegroundColor Yellow
        Write-Host '   2. Ensure the Service Principal has not expired' -ForegroundColor Yellow
        Write-Host '   3. Check that the Service Principal has access to the subscription' -ForegroundColor Yellow
        Write-Host '   4. Verify the Tenant ID is correct' -ForegroundColor Yellow
    }

    exit 1
}
