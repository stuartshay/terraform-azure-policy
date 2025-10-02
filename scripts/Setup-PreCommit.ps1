#Requires -Version 5.1

<#
.SYNOPSIS
    Setup pre-commit hooks for Azure Policy Testing project
.DESCRIPTION
    This script installs and configures pre-commit hooks for the Azure Policy Testing project.
    It handles the installation of pre-commit and sets up all necessary hooks.
.NOTES
    Prerequisites:
    - Python 3.8+ (for pre-commit)
    - PowerShell 5.1+
    - Git repository initialized
.EXAMPLE
    ./scripts/Setup-PreCommit.ps1
    Sets up pre-commit hooks for the project
.EXAMPLE
    ./scripts/Setup-PreCommit.ps1 -SkipInstall
    Configures pre-commit hooks without installing pre-commit itself
.EXAMPLE
    ./scripts/Setup-PreCommit.ps1 -SkipInstall -SkipTest
    Configures hooks without installing pre-commit and without testing (used by devcontainer setup)
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$SkipInstall,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$SkipTest
)

# Set error action preference
$ErrorActionPreference = 'Stop'

Write-Host '🔧 Setting up pre-commit hooks for Azure Policy Testing project...' -ForegroundColor Green

# Check if we're in a git repository
if (-not (Test-Path '.git')) {
    Write-Error 'This script must be run from the root of a Git repository.'
}

# Check Python installation
Write-Host 'Checking Python installation...' -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    if ($pythonVersion -match 'Python (\d+)\.(\d+)') {
        $majorVersion = [int]$matches[1]
        $minorVersion = [int]$matches[2]

        if ($majorVersion -lt 3 -or ($majorVersion -eq 3 -and $minorVersion -lt 8)) {
            Write-Warning "Python 3.8+ is recommended for pre-commit. Found: $pythonVersion"
        } else {
            Write-Host "✓ Python version: $pythonVersion" -ForegroundColor Green
        }
    }
} catch {
    Write-Error 'Python is not installed or not in PATH. Please install Python 3.8+ first.'
}

# Install pre-commit if not skipped
if (-not $SkipInstall) {
    Write-Host 'Installing pre-commit...' -ForegroundColor Yellow

    try {
        # Try pip install first
        python -m pip install pre-commit --upgrade
        Write-Host '✓ pre-commit installed successfully' -ForegroundColor Green
    } catch {
        Write-Warning 'Failed to install pre-commit via pip. Trying alternative methods...'

        # Try with user flag
        try {
            python -m pip install --user pre-commit --upgrade
            Write-Host '✓ pre-commit installed successfully (user install)' -ForegroundColor Green
        } catch {
            Write-Error 'Failed to install pre-commit. Please install manually: pip install pre-commit'
        }
    }
}

# Verify pre-commit installation
Write-Host 'Verifying pre-commit installation...' -ForegroundColor Yellow
try {
    $preCommitVersion = pre-commit --version
    Write-Host "✓ pre-commit version: $preCommitVersion" -ForegroundColor Green
} catch {
    Write-Error 'pre-commit is not installed or not in PATH. Please install it first.'
}

# Check if .pre-commit-config.yaml exists
if (-not (Test-Path '.pre-commit-config.yaml')) {
    Write-Error '.pre-commit-config.yaml not found. Please ensure the configuration file exists.'
}

Write-Host '✓ Found .pre-commit-config.yaml' -ForegroundColor Green

# Install the pre-commit hooks
Write-Host 'Installing pre-commit hooks...' -ForegroundColor Yellow
try {
    if ($Force) {
        pre-commit install --overwrite
    } else {
        pre-commit install
    }
    Write-Host '✓ Pre-commit hooks installed successfully' -ForegroundColor Green
} catch {
    Write-Error "Failed to install pre-commit hooks: $_"
}

# Install commit-msg hook for commitizen
Write-Host 'Installing commit-msg hook...' -ForegroundColor Yellow
try {
    if ($Force) {
        pre-commit install --hook-type commit-msg --overwrite
    } else {
        pre-commit install --hook-type commit-msg
    }
    Write-Host '✓ Commit-msg hook installed successfully' -ForegroundColor Green
} catch {
    Write-Warning 'Failed to install commit-msg hook. Commitizen hook may not work properly.'
}

# Check for required tools and modules
Write-Host 'Checking optional dependencies...' -ForegroundColor Yellow

# Check PowerShell modules
$requiredModules = @('PSScriptAnalyzer', 'Pester')
foreach ($module in $requiredModules) {
    if (Get-Module -ListAvailable -Name $module) {
        Write-Host "✓ $module module found" -ForegroundColor Green
    } else {
        Write-Warning "$module module not found. Some hooks may be skipped."
        Write-Host "  Install with: Install-Module -Name $module" -ForegroundColor Gray
    }
}

# Check Terraform
try {
    $terraformVersion = terraform version 2>&1
    if ($terraformVersion -match 'v(\d+\.\d+\.\d+)') {
        Write-Host "✓ Terraform version: $($matches[1])" -ForegroundColor Green
    }
} catch {
    Write-Warning 'Terraform not found. Terraform hooks will be skipped.'
    Write-Host '  Install from: https://www.terraform.io/downloads.html' -ForegroundColor Gray
}

# Run a test of the hooks
# The $SkipTest parameter can be set to skip running pre-commit hook tests,
# for example during automated devcontainer setup or CI/CD pipelines.
if (-not $SkipTest) {
    Write-Host 'Testing pre-commit hooks...' -ForegroundColor Yellow
    try {
        pre-commit run --all-files --verbose
        Write-Host '✓ Pre-commit hooks test completed' -ForegroundColor Green
    } catch {
        Write-Warning 'Pre-commit hooks test had some issues. Check the output above.'
        Write-Host 'You can fix issues and run: pre-commit run --all-files' -ForegroundColor Gray
    }
} else {
    Write-Host '⊘ Skipping pre-commit hooks test' -ForegroundColor Gray
}

# Create initial secrets baseline if it doesn't exist
if (-not (Test-Path '.secrets.baseline')) {
    Write-Host 'Creating initial secrets baseline...' -ForegroundColor Yellow
    try {
        detect-secrets scan --baseline .secrets.baseline
        Write-Host '✓ Initial secrets baseline created' -ForegroundColor Green
    } catch {
        Write-Warning 'Could not create secrets baseline. detect-secrets may not be installed.'
    }
}

Write-Host ''
Write-Host '🎉 Pre-commit setup completed!' -ForegroundColor Green
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Cyan
Write-Host '1. Make some changes to your files' -ForegroundColor White
Write-Host "2. Run 'git add .' to stage your changes" -ForegroundColor White
Write-Host "3. Run 'git commit -m \"your message\"' - hooks will run automatically!" -ForegroundColor White
Write-Host ''
Write-Host 'Manual hook execution:' -ForegroundColor Cyan
Write-Host '- Run all hooks: pre-commit run --all-files' -ForegroundColor White
Write-Host '- Run specific hook: pre-commit run <hook-name>' -ForegroundColor White
Write-Host '- Skip hooks: git commit --no-verify' -ForegroundColor White
Write-Host ''
Write-Host 'Configuration file: .pre-commit-config.yaml' -ForegroundColor Gray
Write-Host 'Secrets baseline: .secrets.baseline' -ForegroundColor Gray
