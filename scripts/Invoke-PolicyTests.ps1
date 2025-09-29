#Requires -Modules Pester

<#
.SYNOPSIS
    Test runner for Azure Policy tests
.DESCRIPTION
    This script runs Pester tests for Azure Policy definitions and compliance validation.
    It provides a consistent way to execute tests with proper configuration and reporting.
.PARAMETER TestPath
    Path to specific test file or directory to run. Defaults to all tests in the tests directory.
.PARAMETER ResourceGroup
    Target resource group for policy testing. Defaults to 'rg-azure-policy-testing'.
.PARAMETER OutputFormat
    Output format for test results. Options: NUnitXml, JUnitXml, None. Defaults to None.
.PARAMETER OutputPath
    Path to save test results. Only used when OutputFormat is specified.
.PARAMETER PassThru
    Return the test results object.
.EXAMPLE
    .\Invoke-PolicyTests.ps1
    Runs all policy tests in the tests directory
.EXAMPLE
    .\Invoke-PolicyTests.ps1 -TestPath "tests\storage" -ResourceGroup "rg-azure-policy-testing"
    Runs only storage policy tests
.EXAMPLE
    .\Invoke-PolicyTests.ps1 -OutputFormat "NUnitXml" -OutputPath "TestResults.xml"
    Runs tests and saves results in NUnit XML format
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TestPath = "tests",

    [Parameter()]
    [string]$ResourceGroup = "rg-azure-policy-testing",

    [Parameter()]
    [ValidateSet("NUnitXml", "JUnitXml", "None")]
    [string]$OutputFormat = "None",

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [switch]$PassThru
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Import required modules
$requiredModules = @(
    'Pester',
    'Az.Accounts',
    'Az.Resources',
    'Az.Storage',
    'Az.PolicyInsights'
)

Write-Host "Checking required modules..." -ForegroundColor Yellow
foreach ($module in $requiredModules) {
    if (-not (Get-Module -Name $module -ListAvailable)) {
        Write-Error "Required module '$module' is not installed. Please install it using: Install-Module -Name $module"
        return
    }
}

# Verify Azure authentication
Write-Host "Checking Azure authentication..." -ForegroundColor Yellow
$context = Get-AzContext
if (-not $context) {
    Write-Error "No Azure context found. Please run Connect-AzAccount first."
    return
}

Write-Host "Connected to Azure:" -ForegroundColor Green
Write-Host "  Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" -ForegroundColor Gray
Write-Host "  Account: $($context.Account.Id)" -ForegroundColor Gray
Write-Host "  Tenant: $($context.Tenant.Id)" -ForegroundColor Gray

# Verify resource group exists
Write-Host "Verifying resource group '$ResourceGroup'..." -ForegroundColor Yellow
$rg = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Error "Resource group '$ResourceGroup' not found. Please create it first or specify a different resource group."
    return
}
Write-Host "Resource group found: $($rg.Location)" -ForegroundColor Green

# Set up test environment variables
$env:AZURE_POLICY_TEST_RESOURCE_GROUP = $ResourceGroup
$env:AZURE_POLICY_TEST_SUBSCRIPTION_ID = $context.Subscription.Id

# Configure Pester
$pesterConfig = @{
    Run        = @{
        Path     = $TestPath
        PassThru = $PassThru.IsPresent
    }
    Output     = @{
        Verbosity = 'Detailed'
    }
    TestResult = @{
        Enabled = $OutputFormat -ne "None"
    }
}

# Set output format if specified
if ($OutputFormat -ne "None") {
    $pesterConfig.TestResult.OutputFormat = $OutputFormat

    if ($OutputPath) {
        $pesterConfig.TestResult.OutputPath = $OutputPath
    }
    else {
        # Generate default output path
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $defaultPath = "TestResults_$timestamp.$($OutputFormat.ToLower() -replace 'xml$', '.xml')"
        $pesterConfig.TestResult.OutputPath = $defaultPath
        Write-Host "Test results will be saved to: $defaultPath" -ForegroundColor Yellow
    }
}

# Run the tests
Write-Host "`nRunning Azure Policy tests..." -ForegroundColor Green
Write-Host "Target: $TestPath" -ForegroundColor Gray
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Gray
Write-Host ("=" * 80) -ForegroundColor Gray

try {
    $results = Invoke-Pester -Configuration ([PesterConfiguration]$pesterConfig)

    # Display summary
    Write-Host "`nTest Summary:" -ForegroundColor Green
    Write-Host "  Total Tests: $($results.TotalCount)" -ForegroundColor Gray
    Write-Host "  Passed: $($results.PassedCount)" -ForegroundColor Green
    Write-Host "  Failed: $($results.FailedCount)" -ForegroundColor $(if ($results.FailedCount -gt 0) { 'Red' } else { 'Gray' })
    Write-Host "  Skipped: $($results.SkippedCount)" -ForegroundColor Yellow
    Write-Host "  Duration: $($results.Duration)" -ForegroundColor Gray

    if ($results.FailedCount -gt 0) {
        Write-Host "`nFailed Tests:" -ForegroundColor Red
        foreach ($failed in $results.Failed) {
            Write-Host "  - $($failed.Path): $($failed.Name)" -ForegroundColor Red
            if ($failed.ErrorRecord) {
                Write-Host "    Error: $($failed.ErrorRecord.Exception.Message)" -ForegroundColor DarkRed
            }
        }
    }

    # Return results if requested
    if ($PassThru.IsPresent) {
        return $results
    }

    # Exit with appropriate code
    if ($results.FailedCount -gt 0) {
        exit 1
    }
    else {
        exit 0
    }

}
catch {
    Write-Error "Failed to run tests: $($_.Exception.Message)"
    exit 1
}
finally {
    # Clean up environment variables
    Remove-Item -Path "env:AZURE_POLICY_TEST_RESOURCE_GROUP" -ErrorAction SilentlyContinue
    Remove-Item -Path "env:AZURE_POLICY_TEST_SUBSCRIPTION_ID" -ErrorAction SilentlyContinue
}
