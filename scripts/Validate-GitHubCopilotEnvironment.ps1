#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates GitHub Copilot environment and tests Azure connectivity
.DESCRIPTION
    This script provides a complete validation workflow:
    1. Validates all required environment variables
    2. Tests Azure authentication and connectivity
    3. Runs storage policy tests to verify end-to-end functionality

    This is the recommended script to validate the GitHub Copilot environment
    configuration as specified in the environment setup guide.
.PARAMETER SkipStorageTest
    Skip the storage test execution (only validate environment)
.PARAMETER SkipAzureAuth
    Skip Azure authentication test (only validate environment variables)
.EXAMPLE
    ./scripts/Validate-GitHubCopilotEnvironment.ps1

    Complete validation including environment variables, Azure auth, and storage tests
.EXAMPLE
    ./scripts/Validate-GitHubCopilotEnvironment.ps1 -SkipStorageTest

    Validate environment variables and Azure auth only
.EXAMPLE
    ./scripts/Validate-GitHubCopilotEnvironment.ps1 -SkipAzureAuth

    Only validate environment variables
.NOTES
    This script is designed for GitHub Copilot environments (Codespaces, Actions, etc.)
    and validates that all required environment variables are correctly configured.
#>

param(
    [switch]$SkipStorageTest,
    [switch]$SkipAzureAuth
)

$ErrorActionPreference = 'Continue'

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  GitHub Copilot Environment Validation & Testing         ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Validate Environment Configuration
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Step 1: Validating Environment Configuration" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Join-Path $PSScriptRoot "Test-EnvironmentConfiguration.ps1"

if ($SkipAzureAuth) {
    & $scriptPath -SkipAzureConnectivityTest
} else {
    & $scriptPath
}

$envValidationExitCode = $LASTEXITCODE

if ($envValidationExitCode -ne 0) {
    Write-Host "`n❌ Environment validation failed!" -ForegroundColor Red
    Write-Host "   Please fix the environment configuration issues above." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n✅ Environment validation completed successfully!" -ForegroundColor Green

# Step 2: Run Storage Tests (if not skipped)
if (-not $SkipStorageTest -and -not $SkipAzureAuth) {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Step 2: Testing Azure Connectivity with Storage Tests" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    $storageTestPath = Join-Path $PSScriptRoot "Run-StorageTest.ps1"

    if (Test-Path $storageTestPath) {
        Write-Host "🚀 Running storage policy tests to verify Azure connectivity..." -ForegroundColor Cyan
        Write-Host ""

        & $storageTestPath

        $storageTestExitCode = $LASTEXITCODE

        if ($storageTestExitCode -ne 0) {
            Write-Host "`n❌ Storage tests failed!" -ForegroundColor Red
            Write-Host "   This may indicate connectivity or permission issues." -ForegroundColor Yellow
            exit 1
        }

        Write-Host "`n✅ Storage tests completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Storage test script not found: $storageTestPath" -ForegroundColor Yellow
        Write-Host "   Skipping storage tests" -ForegroundColor Gray
    }
} else {
    if ($SkipStorageTest) {
        Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "Step 2: Storage Tests" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "⏭️  Skipped (use without -SkipStorageTest to run)" -ForegroundColor Gray
    } elseif ($SkipAzureAuth) {
        Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "Step 2: Storage Tests" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "⏭️  Skipped (Azure auth was skipped)" -ForegroundColor Gray
    }
}

# Summary
Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║           ✅ Validation & Testing Complete!               ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Summary:" -ForegroundColor Cyan
Write-Host "   ✅ Environment variables validated" -ForegroundColor Green

if (-not $SkipAzureAuth) {
    Write-Host "   ✅ Azure authentication verified" -ForegroundColor Green
}

if (-not $SkipStorageTest -and -not $SkipAzureAuth) {
    Write-Host "   ✅ Azure connectivity tested (storage tests)" -ForegroundColor Green
}

Write-Host "`n🎉 Your GitHub Copilot environment is correctly configured!" -ForegroundColor Green
Write-Host ""

Write-Host "📝 Next steps:" -ForegroundColor Cyan
Write-Host "   - Run policy compliance tests: ./scripts/Test-PolicyCompliance.ps1" -ForegroundColor White
Write-Host "   - Deploy policy definitions: ./scripts/Deploy-PolicyDefinitions.ps1" -ForegroundColor White
Write-Host "   - Run all integration tests: ./scripts/Invoke-PolicyTests.ps1" -ForegroundColor White
Write-Host ""

exit 0
