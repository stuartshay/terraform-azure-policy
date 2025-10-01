#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Helper script to run storage policy tests
.DESCRIPTION
    Checks prerequisites and runs the Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1
.PARAMETER SkipAzureCheck
    Skip Azure connection check
.EXAMPLE
    ./scripts/Run-StorageTest.ps1
#>

param(
    [switch]$SkipAzureCheck
)

# Check if connected to Azure
if (-not $SkipAzureCheck) {
    $azContext = Get-AzContext -ErrorAction SilentlyContinue

    if (-not $azContext) {
        Write-Host '❌ Not connected to Azure. Please run: Connect-AzAccount' -ForegroundColor Red
        Write-Host ''
        Write-Host 'After connecting, verify you have:' -ForegroundColor Yellow
        Write-Host '  1. Resource group: rg-azure-policy-testing' -ForegroundColor Yellow
        Write-Host '  2. Policy assigned to the resource group' -ForegroundColor Yellow
        Write-Host '  3. Appropriate permissions to create/delete storage accounts' -ForegroundColor Yellow
        exit 1
    }

    Write-Host '✅ Connected to Azure' -ForegroundColor Green
    Write-Host "   Subscription: $($azContext.Subscription.Name)" -ForegroundColor Cyan
    Write-Host "   Tenant: $($azContext.Tenant.Id)" -ForegroundColor Cyan  # pragma: allowlist secret
    Write-Host ''

    # Check if resource group exists
    $rgName = 'rg-azure-policy-testing'
    $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue

    if (-not $rg) {
        Write-Host "⚠️  Resource group '$rgName' not found" -ForegroundColor Yellow
        Write-Host '   Creating resource group...' -ForegroundColor Yellow

        try {
            $rg = New-AzResourceGroup -Name $rgName -Location 'eastus' -ErrorAction Stop
            Write-Host "✅ Resource group created: $rgName" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Failed to create resource group: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "✅ Resource group exists: $rgName" -ForegroundColor Green
    }
    Write-Host ''
}

# Run the test
Write-Host '🚀 Running Storage Account Public Access Policy Tests...' -ForegroundColor Cyan
Write-Host ''

$testPath = "$PSScriptRoot/../tests/storage/Storage.Integration-DenyStorageAccountPublicAccess.Tests.ps1"

if (-not (Test-Path $testPath)) {
    Write-Host "❌ Test file not found: $testPath" -ForegroundColor Red
    exit 1
}

Invoke-Pester -Path $testPath -Output Detailed
