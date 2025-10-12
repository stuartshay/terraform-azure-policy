#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs unit tests for CI/CD pipeline
.DESCRIPTION
    This script runs Pester unit tests with code coverage for the CI/CD pipeline.
    It creates the reports directory if needed and handles the case where no unit tests exist.
.NOTES
    This script is designed to be run in CI/CD environments.
#>

[CmdletBinding()]
param()

# Ensure we're in strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Create reports directory if it doesn't exist
if (-not (Test-Path 'reports')) {
    New-Item -ItemType Directory -Path 'reports' -Force | Out-Null
    Write-Host '✓ Created reports directory' -ForegroundColor Green
}

# Import Pester module
Import-Module Pester -Force

# Find all unit test files
Write-Host 'Searching for unit test files...' -ForegroundColor Cyan
$unitTests = Get-ChildItem -Path 'tests' -Filter '*Unit*.Tests.ps1' -Recurse -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName

if (-not $unitTests -or $unitTests.Count -eq 0) {
    Write-Warning 'No unit test files found. Creating placeholder test results.'

    # Create minimal test results XML so the workflow doesn't fail
    $emptyXml = @'
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="Pester" tests="0" failures="0" errors="0" time="0">
  <testcase name="No unit tests found" classname="Placeholder" time="0">
    <skipped message="No unit test files matching *Unit*.Tests.ps1 were found" />
  </testcase>
</testsuite>
'@
    $emptyXml | Set-Content -Path 'reports/TestResults.xml' -Force
    Write-Host '✓ Created placeholder test results' -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($unitTests.Count) unit test file(s):" -ForegroundColor Green
$unitTests | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }

# Configure Pester
$config = [PesterConfiguration]@{
    Run          = @{
        Path     = $unitTests
        PassThru = $true
    }
    Output       = @{
        Verbosity = 'Detailed'
    }
    TestResult   = @{
        Enabled      = $true
        OutputFormat = 'JUnitXml'
        OutputPath   = 'reports/TestResults.xml'
    }
    CodeCoverage = @{
        Enabled              = $true
        OutputFormat         = 'JaCoCo'
        OutputPath           = 'reports/coverage.xml'
        Path                 = @(
            'scripts/*.ps1',
            'PowerShell/*.ps1'
        )
        ExcludeTests         = $true
        CoveragePercentTarget = 70.0
    }
}

# Run tests
Write-Host ''
Write-Host 'Running unit tests...' -ForegroundColor Cyan
$results = Invoke-Pester -Configuration $config

# Display results
Write-Host ''
Write-Host '═══════════════════════════════════════' -ForegroundColor Cyan
Write-Host '           Test Results                ' -ForegroundColor Cyan
Write-Host '═══════════════════════════════════════' -ForegroundColor Cyan
Write-Host "  Total:   $($results.TotalCount)" -ForegroundColor White
Write-Host "  Passed:  $($results.PassedCount)" -ForegroundColor Green

if ($results.FailedCount -gt 0) {
    Write-Host "  Failed:  $($results.FailedCount)" -ForegroundColor Red
}
else {
    Write-Host "  Failed:  $($results.FailedCount)" -ForegroundColor Green
}

Write-Host "  Skipped: $($results.SkippedCount)" -ForegroundColor Yellow

# Display coverage results
if ($results.CodeCoverage) {
    Write-Host ''
    Write-Host '═══════════════════════════════════════' -ForegroundColor Cyan
    Write-Host '         Coverage Results             ' -ForegroundColor Cyan
    Write-Host '═══════════════════════════════════════' -ForegroundColor Cyan
    $coveragePercent = [math]::Round($results.CodeCoverage.CoveragePercent, 2)
    Write-Host "  Percentage:        $coveragePercent%" -ForegroundColor White
    Write-Host "  Commands Analyzed: $($results.CodeCoverage.CommandsAnalyzedCount)" -ForegroundColor White
    Write-Host "  Commands Executed: $($results.CodeCoverage.CommandsExecutedCount)" -ForegroundColor White
}

Write-Host '═══════════════════════════════════════' -ForegroundColor Cyan

# Exit with appropriate code
if ($results.FailedCount -gt 0) {
    Write-Host ''
    Write-Host '❌ One or more tests failed' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '✅ All tests passed' -ForegroundColor Green
exit 0
