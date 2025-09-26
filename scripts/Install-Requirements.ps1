# PowerShell Module Installation Script
# This script installs all required and optional PowerShell modules for the Azure Policy Testing project

<#
.SYNOPSIS
    Install PowerShell modules required for Azure Policy Testing
.DESCRIPTION
    This script reads the requirements.psd1 file and installs all required PowerShell modules
.PARAMETER IncludeOptional
    Install optional modules in addition to required modules
.PARAMETER Force
    Force installation even if modules are already installed
.PARAMETER Scope
    Installation scope: CurrentUser or AllUsers (requires admin for AllUsers)
.EXAMPLE
    ./Install-Requirements.ps1 -IncludeOptional -Force
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$IncludeOptional,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser'
)

function Install-RequiredModule {
    <#
    .SYNOPSIS
    Install a PowerShell module with proper error handling
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ModuleInfo,

        [Parameter(Mandatory = $true)]
        [string]$InstallScope,

        [Parameter(Mandatory = $false)]
        [switch]$ForceInstall
    )

    $ModuleName = $ModuleInfo.ModuleName
    $ModuleVersion = $ModuleInfo.ModuleVersion
    $Description = $ModuleInfo.Description

    try {
        Write-Host "Processing module: $ModuleName" -ForegroundColor Yellow
        Write-Host "  Description: $Description" -ForegroundColor Gray
        Write-Host "  Required Version: $ModuleVersion" -ForegroundColor Gray

        # Check if module is already installed
        $InstalledModule = Get-Module -ListAvailable -Name $ModuleName | Where-Object { $_.Version -eq $ModuleVersion }

        if ($InstalledModule -and -not $ForceInstall) {
            Write-Host "  ✓ Already installed (Version: $($InstalledModule.Version))" -ForegroundColor Green
            return $true
        }

        # Install the module
        $InstallParams = @{
            Name               = $ModuleName
            RequiredVersion    = $ModuleVersion
            Scope              = $InstallScope
            Force              = $ForceInstall
            AllowClobber       = $true
            SkipPublisherCheck = $true
        }

        Write-Host '  Installing...' -ForegroundColor Cyan
        Install-Module @InstallParams

        # Verify installation
        $InstalledModule = Get-Module -ListAvailable -Name $ModuleName | Where-Object { $_.Version -eq $ModuleVersion }

        if ($InstalledModule) {
            Write-Host "  ✓ Successfully installed (Version: $($InstalledModule.Version))" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host '  ✗ Installation verification failed' -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "  ✗ Installation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
try {
    Write-Host 'Azure Policy Testing - PowerShell Module Installation' -ForegroundColor Cyan
    Write-Host '=====================================================' -ForegroundColor Cyan

    # Load requirements
    $RequirementsPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'requirements.psd1'

    if (-not (Test-Path $RequirementsPath)) {
        throw "Requirements file not found: $RequirementsPath"
    }

    $Requirements = Import-PowerShellDataFile -Path $RequirementsPath

    Write-Host 'Installation Settings:' -ForegroundColor White
    Write-Host "  Scope: $Scope" -ForegroundColor Gray
    Write-Host "  Include Optional: $IncludeOptional" -ForegroundColor Gray
    Write-Host "  Force Reinstall: $Force" -ForegroundColor Gray
    Write-Host "  PowerShell Version Required: $($Requirements.PowerShellVersion)" -ForegroundColor Gray

    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt [int]$Requirements.PowerShellVersion.Split('.')[0]) {
        Write-Warning "This script requires PowerShell $($Requirements.PowerShellVersion) or higher. Current version: $($PSVersionTable.PSVersion)"
    }

    # Set up PowerShell Gallery as trusted repository
    $Gallery = Get-PSRepository -Name 'PSGallery'
    if ($Gallery.InstallationPolicy -ne 'Trusted') {
        Write-Host "`nSetting PSGallery as trusted repository..." -ForegroundColor Yellow
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    }

    # Install required modules
    Write-Host "`n=== Installing Required Modules ===" -ForegroundColor Cyan
    $RequiredResults = @()

    foreach ($Module in $Requirements.RequiredModules) {
        $Success = Install-RequiredModule -ModuleInfo $Module -InstallScope $Scope -ForceInstall:$Force
        $RequiredResults += [PSCustomObject]@{
            Name    = $Module.ModuleName
            Version = $Module.ModuleVersion
            Success = $Success
            Type    = 'Required'
        }
    }

    # Install optional modules if requested
    $OptionalResults = @()
    if ($IncludeOptional -and $Requirements.OptionalModules) {
        Write-Host "`n=== Installing Optional Modules ===" -ForegroundColor Cyan

        foreach ($Module in $Requirements.OptionalModules) {
            $Success = Install-RequiredModule -ModuleInfo $Module -InstallScope $Scope -ForceInstall:$Force
            $OptionalResults += [PSCustomObject]@{
                Name    = $Module.ModuleName
                Version = $Module.ModuleVersion
                Success = $Success
                Type    = 'Optional'
            }
        }
    }

    # Summary
    $AllResults = $RequiredResults + $OptionalResults
    $SuccessCount = ($AllResults | Where-Object { $_.Success }).Count
    $FailureCount = ($AllResults | Where-Object { -not $_.Success }).Count

    Write-Host "`n=== Installation Summary ===" -ForegroundColor Cyan
    Write-Host "Total Modules: $($AllResults.Count)" -ForegroundColor White
    Write-Host "Successful: $SuccessCount" -ForegroundColor Green
    Write-Host "Failed: $FailureCount" -ForegroundColor Red

    if ($FailureCount -gt 0) {
        Write-Host "`nFailed Installations:" -ForegroundColor Red
        $AllResults | Where-Object { -not $_.Success } | ForEach-Object {
            Write-Host "  - $($_.Name) ($($_.Type))" -ForegroundColor Red
        }
    }

    # Display next steps
    Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
    Write-Host "1. Run 'Import-Module' for the modules you need" -ForegroundColor White
    Write-Host '2. Use the PowerShell profile: ./PowerShell/Microsoft.PowerShell_profile.ps1' -ForegroundColor White
    Write-Host '3. Set environment variables in your .env file:' -ForegroundColor White

    if ($Requirements.RequiredEnvironmentVariables) {
        foreach ($EnvVar in $Requirements.RequiredEnvironmentVariables) {
            Write-Host "   - $EnvVar" -ForegroundColor Gray
        }
    }

    Write-Host '4. Install recommended VS Code extensions:' -ForegroundColor White
    if ($Requirements.RecommendedExtensions) {
        foreach ($Extension in $Requirements.RecommendedExtensions) {
            Write-Host "   - $Extension" -ForegroundColor Gray
        }
    }

    if ($FailureCount -eq 0) {
        Write-Host "`nAll modules installed successfully! ✓" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "`nSome modules failed to install. Please check the errors above." -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Error "Installation script failed: $($_.Exception.Message)"
    exit 1
}
