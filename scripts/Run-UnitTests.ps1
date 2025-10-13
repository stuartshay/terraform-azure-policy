#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs unit tests for CI/CD pipeline
.DESCRIPTION
    This script runs Pester unit tests for the CI/CD pipeline.
#>

Import-Module Pester -Force

Write-Host 'Searching for unit test files...' -ForegroundColor Cyan
$unitTests = Get-ChildItem -Path 'tests' -Filter '*Unit*.Tests.ps1' -Recurse |
    Select-Object -ExpandProperty FullName

if (-not $unitTests -or $unitTests.Count -eq 0) {
    Write-Warning 'No unit test files found.'
    exit 0
}

Write-Host "Found $($unitTests.Count) unit test file(s)" -ForegroundColor Green

# Configure Pester
$config = New-PesterConfiguration
$config.Run.Path = $unitTests
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'JUnitXml'
$config.TestResult.OutputPath = 'testResults.xml'

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
Write-Host "  Failed:  $($results.FailedCount)" -ForegroundColor $(if ($results.FailedCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Skipped: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host '═══════════════════════════════════════' -ForegroundColor Cyan

if ($results.FailedCount -gt 0) {
    Write-Host ''
    Write-Host '❌ One or more tests failed' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '✅ All tests passed' -ForegroundColor Green
exit 0
