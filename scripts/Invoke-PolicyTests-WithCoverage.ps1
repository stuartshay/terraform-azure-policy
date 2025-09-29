#Requires -Modules Pester

<#
.SYNOPSIS
    Enhanced test runner with code coverage for Azure Policy tests
.DESCRIPTION
    This script runs Pester tests for Azure Policy definitions with comprehensive code coverage reporting.
    It provides coverage analysis for PowerShell scripts and generates multiple output formats.
.PARAMETER TestPath
    Path to specific test file or directory to run. Defaults to all tests in the tests directory.
.PARAMETER ResourceGroup
    Target resource group for policy testing. Defaults to 'rg-azure-policy-testing'. # pragma: allowlist secret
.PARAMETER OutputFormat
    Output format for test results. Options: NUnitXml, JUnitXml, None. Defaults to JUnitXml.
.PARAMETER OutputPath
    Path to save test results. Only used when OutputFormat is specified.
.PARAMETER PassThru
    Return the test results object.
.PARAMETER CodeCoverage
    Enable code coverage analysis (default: true).
.PARAMETER CoverageTarget
    Code coverage percentage target (default: 80).
.PARAMETER GenerateHtmlReport
    Generate HTML coverage report using ReportGenerator.
.EXAMPLE
    .\Invoke-PolicyTests-WithCoverage.ps1
    Runs all policy tests with coverage analysis
.EXAMPLE
    .\Invoke-PolicyTests-WithCoverage.ps1 -TestPath "tests\storage" -CodeCoverage
    Runs only storage policy tests with coverage
.EXAMPLE
    .\Invoke-PolicyTests-WithCoverage.ps1 -GenerateHtmlReport -CoverageTarget 90
    Runs tests with 90% coverage target and generates HTML report
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TestPath = 'tests',

    [Parameter()]
    [string]$ResourceGroup = 'rg-azure-policy-testing', # pragma: allowlist secret

    [Parameter()]
    [ValidateSet('NUnitXml', 'JUnitXml', 'None')]
    [string]$OutputFormat = 'JUnitXml',

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [switch]$PassThru,

    [Parameter()]
    [bool]$CodeCoverage = $true,

    [Parameter()]
    [ValidateRange(0, 100)]
    [double]$CoverageTarget = 80.0,

    [Parameter()]
    [switch]$GenerateHtmlReport
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# Import required modules
$requiredModules = @(
    'Pester',
    'Az.Accounts',
    'Az.Resources',
    'Az.Storage',
    'Az.PolicyInsights'
)

Write-Host 'Checking required modules...' -ForegroundColor Yellow
foreach ($module in $requiredModules) {
    if (-not (Get-Module -Name $module -ListAvailable)) {
        Write-Host "Installing module: $module" -ForegroundColor Yellow
        Install-Module -Name $module -Force -Scope CurrentUser
    }
    Import-Module -Name $module -Force
}

# Ensure reports directory exists
$reportsDir = Join-Path $PSScriptRoot 'reports'
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

# Check Azure authentication (for integration tests)
Write-Host 'Checking Azure authentication...' -ForegroundColor Yellow
$context = Get-AzContext -ErrorAction SilentlyContinue
if (-not $context) {
    Write-Warning 'No Azure context found. Integration tests will be skipped.'
    Write-Host 'To run integration tests, please run: Connect-AzAccount' -ForegroundColor Gray
}
else {
    Write-Host "Azure context found: $($context.Account.Id)" -ForegroundColor Green

    # Verify resource group exists
    $rg = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Warning "Resource group '$ResourceGroup' not found. Integration tests may fail."
    }
    else {
        Write-Host "Resource group found: $($rg.Location)" -ForegroundColor Green
    }
}

# Set up test environment variables
$env:AZURE_POLICY_TEST_RESOURCE_GROUP = $ResourceGroup
if ($context) {
    $env:AZURE_POLICY_TEST_SUBSCRIPTION_ID = $context.Subscription.Id
}

# Configure Pester with Coverage
$pesterConfig = @{
    Run        = @{
        Path     = $TestPath
        PassThru = $PassThru.IsPresent
    }
    Output     = @{
        Verbosity = 'Detailed'
    }
    TestResult = @{
        Enabled = $OutputFormat -ne 'None'
    }
}

# Set output format if specified
if ($OutputFormat -ne 'None') {
    $pesterConfig.TestResult.OutputFormat = $OutputFormat

    if ($OutputPath) {
        $pesterConfig.TestResult.OutputPath = $OutputPath
    }
    else {
        # Generate default output path
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $defaultPath = Join-Path $reportsDir "TestResults_$timestamp.$($OutputFormat.ToLower() -replace 'xml$', '.xml')"
        $pesterConfig.TestResult.OutputPath = $defaultPath
        Write-Host "Test results will be saved to: $defaultPath" -ForegroundColor Yellow
    }
}

# Configure code coverage if enabled
if ($CodeCoverage) {
    Write-Host "Code coverage analysis enabled (target: $CoverageTarget%)" -ForegroundColor Yellow

    $coverageFiles = @()

    # Include PowerShell scripts for coverage analysis
    $projectRoot = Split-Path $PSScriptRoot -Parent
    $scriptPaths = @(
        (Join-Path $projectRoot 'scripts' '*.ps1'),
        (Join-Path $projectRoot 'PowerShell' '*.ps1')
    )

    foreach ($path in $scriptPaths) {
        $coverageFiles += Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    }

    if ($coverageFiles.Count -gt 0) {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $coverageOutputPath = Join-Path $reportsDir "coverage_$timestamp.xml"

        $pesterConfig.CodeCoverage = @{
            Enabled               = $true
            OutputFormat          = 'JaCoCo'
            OutputPath            = $coverageOutputPath
            Path                  = $coverageFiles
            ExcludeTests          = $true
            CoveragePercentTarget = $CoverageTarget
        }

        Write-Host "Coverage will be saved to: $coverageOutputPath" -ForegroundColor Yellow
        Write-Host "Coverage files to analyze: $($coverageFiles.Count)" -ForegroundColor Gray
    }
    else {
        Write-Warning 'No PowerShell files found for coverage analysis'
        $CodeCoverage = $false
    }
}

# Run the tests
Write-Host "`n=== Running Azure Policy Tests with Coverage ===" -ForegroundColor Green
Write-Host "Target: $TestPath" -ForegroundColor Gray
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Gray
Write-Host "Code Coverage: $($CodeCoverage -and $coverageFiles.Count -gt 0)" -ForegroundColor Gray
Write-Host ('=' * 80) -ForegroundColor Gray

try {
    $results = Invoke-Pester -Configuration ([PesterConfiguration]$pesterConfig)

    # Display summary
    Write-Host "`n=== Test Summary ===" -ForegroundColor Green
    $totalCount = $results.TotalCount ?? 0
    $passedCount = $results.PassedCount ?? 0
    $failedCount = $results.FailedCount ?? 0
    $skippedCount = $results.SkippedCount ?? 0
    $duration = $results.Duration ?? 'Unknown'

    Write-Host "  Total Tests: $totalCount" -ForegroundColor Gray
    Write-Host "  Passed: $passedCount" -ForegroundColor Green
    Write-Host "  Failed: $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { 'Red' } else { 'Gray' })
    Write-Host "  Skipped: $skippedCount" -ForegroundColor Yellow
    Write-Host "  Duration: $duration" -ForegroundColor Gray

    # Display coverage summary if enabled
    if ($CodeCoverage -and $results.CodeCoverage) {
        Write-Host "`n=== Code Coverage Summary ===" -ForegroundColor Green
        Write-Host "  Coverage Percentage: $([math]::Round($results.CodeCoverage.CoveragePercent, 2))%" -ForegroundColor $(
            if ($results.CodeCoverage.CoveragePercent -ge $CoverageTarget) { 'Green' } else { 'Red' }
        )
        Write-Host "  Covered Commands: $($results.CodeCoverage.CommandsExecutedCount)" -ForegroundColor Gray
        Write-Host "  Total Commands: $($results.CodeCoverage.CommandsAnalyzedCount)" -ForegroundColor Gray
        Write-Host "  Missed Commands: $($results.CodeCoverage.CommandsMissedCount)" -ForegroundColor Red

        # Show top uncovered files if any
        if ($results.CodeCoverage.CommandsMissedCount -gt 0) {
            Write-Host "`n  Files with missed coverage:" -ForegroundColor Yellow
            $results.CodeCoverage.MissedCommands | Group-Object File | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object {
                $fileName = Split-Path $_.Name -Leaf
                Write-Host "    ${fileName}: $($_.Count) missed commands" -ForegroundColor Gray
            }
        }

        # Check if coverage target was met
        if ($results.CodeCoverage.CoveragePercent -lt $CoverageTarget) {
            Write-Warning "Code coverage $([math]::Round($results.CodeCoverage.CoveragePercent, 2))% is below target $CoverageTarget%"
        }
        else {
            Write-Host '✓ Code coverage target achieved!' -ForegroundColor Green
        }
    }

    # Generate HTML report if requested
    if ($GenerateHtmlReport -and $CodeCoverage -and $results.CodeCoverage) {
        Write-Host "`n=== Generating HTML Coverage Report ===" -ForegroundColor Green

        try {
            # Check if ReportGenerator is available
            $reportGeneratorPath = Get-Command 'reportgenerator' -ErrorAction SilentlyContinue
            if (-not $reportGeneratorPath) {
                Write-Host 'Installing ReportGenerator...' -ForegroundColor Yellow
                dotnet tool install --global dotnet-reportgenerator-globaltool --ignore-failed-sources 2>$null
                $reportGeneratorPath = Get-Command 'reportgenerator' -ErrorAction SilentlyContinue
            }

            if ($reportGeneratorPath) {
                $htmlReportDir = Join-Path $reportsDir 'coverage-html' # pragma: allowlist secret
                $coverageXmlPath = $pesterConfig.CodeCoverage.OutputPath

                & reportgenerator "-reports:$coverageXmlPath" "-targetdir:$htmlReportDir" '-reporttypes:Html' 2>$null

                $indexPath = Join-Path $htmlReportDir 'index.html'
                if (Test-Path $indexPath) {
                    Write-Host "✓ HTML coverage report generated: $indexPath" -ForegroundColor Green

                    # Try to open the report
                    try {
                        if ($IsWindows -or $env:OS -eq 'Windows_NT') { # pragma: allowlist secret
                            # pragma: allowlist secret
                            Start-Process $indexPath
                        }
                        elseif ($IsLinux) {
                            & xdg-open $indexPath 2>/dev/null
                        }
                        elseif ($IsMacOS) {
                            & open $indexPath
                        }
                    }
                    catch {
                        Write-Host "  Open manually: $indexPath" -ForegroundColor Gray
                    }
                }
                else {
                    Write-Warning 'HTML report generation may have failed'
                }
            }
            else {
                Write-Warning 'ReportGenerator not available. Install with: dotnet tool install --global dotnet-reportgenerator-globaltool'
            }
        }
        catch {
            Write-Warning "Failed to generate HTML report: $($_.Exception.Message)"
        }
    }

    # Return results if requested
    if ($PassThru) {
        return $results
    }

    # Exit with appropriate code
    exit $(if ($results.FailedCount -gt 0) { 1 } else { 0 })

}
catch {
    Write-Error "Test execution failed: $($_.Exception.Message)"
    exit 1
}
