<#
.SYNOPSIS
    Install PowerShell modules for GitHub Actions CI/CD environments with retry logic

.DESCRIPTION
    This script installs PowerShell modules required for CI/CD pipelines with enhanced
    error handling and retry logic to handle intermittent network issues and firewall restrictions.

.PARAMETER RequiredModules
    Array of module names to install. Defaults to common testing modules.

.PARAMETER MaxRetries
    Maximum number of retry attempts for each module. Default is 3.

.PARAMETER RetryDelaySeconds
    Delay in seconds between retry attempts. Default is 5.

.EXAMPLE
    ./Install-ModulesForCI.ps1 -RequiredModules @('Pester', 'PSScriptAnalyzer')

.EXAMPLE
    ./Install-ModulesForCI.ps1 -MaxRetries 5 -RetryDelaySeconds 10
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$RequiredModules = @('Pester', 'PSScriptAnalyzer', 'Az.Accounts', 'Az.Resources'),

    [Parameter(Mandatory = $false)]
    [int]$MaxRetries = 3,

    [Parameter(Mandatory = $false)]
    [int]$RetryDelaySeconds = 5
)

# Configure TLS for secure connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host '═══════════════════════════════════════════════════════' -ForegroundColor Cyan
Write-Host '  PowerShell Module Installation for CI/CD' -ForegroundColor Cyan
Write-Host '═══════════════════════════════════════════════════════' -ForegroundColor Cyan
Write-Host ''

# Function to test PowerShell Gallery connectivity
function Test-PSGalleryConnectivity {
    Write-Host 'Testing PowerShell Gallery connectivity...' -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri 'https://www.powershellgallery.com' -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        Write-Host "  ✓ PowerShell Gallery is accessible (Status: $($response.StatusCode))" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "  ⚠ PowerShell Gallery connectivity check failed: $($_.Exception.Message)"
        return $false
    }
}

# Function to configure PSGallery repository
function Initialize-PSGalleryRepository {
    Write-Host 'Configuring PSGallery repository...' -ForegroundColor Yellow
    
    try {
        # Ensure PSGallery is registered
        $psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        
        if (-not $psGallery) {
            Write-Host '  Registering PSGallery repository...' -ForegroundColor Cyan
            Register-PSRepository -Default -ErrorAction Stop
        }
        
        # Set as trusted
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
        
        $psGallery = Get-PSRepository -Name PSGallery
        Write-Host '  ✓ PSGallery repository configured' -ForegroundColor Green
        Write-Host "    Source Location: $($psGallery.SourceLocation)" -ForegroundColor Gray
        Write-Host "    Installation Policy: $($psGallery.InstallationPolicy)" -ForegroundColor Gray
        return $true
    }
    catch {
        Write-Warning "  ⚠ Failed to configure PSGallery: $($_.Exception.Message)"
        return $false
    }
}

# Function to install module with retry logic
function Install-ModuleWithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $false)]
        [string]$MinimumVersion,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxAttempts = 3,
        
        [Parameter(Mandatory = $false)]
        [int]$DelaySeconds = 5
    )

    $attempt = 0
    $success = $false

    while (-not $success -and $attempt -lt $MaxAttempts) {
        $attempt++
        try {
            Write-Host "  Attempt $attempt of $MaxAttempts: Installing $ModuleName..." -ForegroundColor Cyan
            
            $installParams = @{
                Name               = $ModuleName
                Force              = $true
                Scope              = 'CurrentUser'
                AllowClobber       = $true
                SkipPublisherCheck = $true
                ErrorAction        = 'Stop'
            }
            
            if ($MinimumVersion) {
                $installParams['MinimumVersion'] = $MinimumVersion
            }
            
            Install-Module @installParams
            
            # Verify installation
            $installed = Get-Module -ListAvailable -Name $ModuleName | Select-Object -First 1
            
            if ($installed) {
                $success = $true
                Write-Host "    ✓ Successfully installed $ModuleName (Version: $($installed.Version))" -ForegroundColor Green
                return $true
            }
            else {
                throw "Module installation verification failed"
            }
        }
        catch {
            Write-Warning "    Failed to install $ModuleName on attempt ${attempt}: $($_.Exception.Message)"
            
            if ($attempt -lt $MaxAttempts) {
                Write-Host "    Waiting $DelaySeconds seconds before retry..." -ForegroundColor Yellow
                Start-Sleep -Seconds $DelaySeconds
            }
            else {
                Write-Error "    ✗ Failed to install $ModuleName after $MaxAttempts attempts"
                return $false
            }
        }
    }
    
    return $success
}

# Main execution
try {
    Write-Host 'Environment Information:' -ForegroundColor White
    Write-Host "  PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
    Write-Host "  OS: $($PSVersionTable.OS)" -ForegroundColor Gray
    Write-Host "  Platform: $($PSVersionTable.Platform)" -ForegroundColor Gray
    Write-Host ''

    # Test connectivity
    $galleryAccessible = Test-PSGalleryConnectivity
    Write-Host ''

    # Configure repository
    $repoConfigured = Initialize-PSGalleryRepository
    Write-Host ''

    if (-not $repoConfigured) {
        Write-Warning 'PSGallery repository configuration failed, but will attempt module installation anyway...'
    }

    # Install modules
    Write-Host "Installing $($RequiredModules.Count) required module(s)..." -ForegroundColor Yellow
    Write-Host ''

    $results = @()
    $failedModules = @()

    foreach ($moduleName in $RequiredModules) {
        Write-Host "Processing: $moduleName" -ForegroundColor White
        
        # Check if already installed
        $existing = Get-Module -ListAvailable -Name $moduleName | Select-Object -First 1
        
        if ($existing) {
            Write-Host "  ✓ Already installed (Version: $($existing.Version))" -ForegroundColor Green
            $results += [PSCustomObject]@{
                Module  = $moduleName
                Success = $true
                Action  = 'Already Installed'
                Version = $existing.Version
            }
        }
        else {
            # Determine minimum version if specified
            $minVersion = $null
            if ($moduleName -eq 'Pester') {
                $minVersion = '5.4.0'
            }
            
            $installed = Install-ModuleWithRetry -ModuleName $moduleName -MinimumVersion $minVersion -MaxAttempts $MaxRetries -DelaySeconds $RetryDelaySeconds
            
            if ($installed) {
                $installedModule = Get-Module -ListAvailable -Name $moduleName | Select-Object -First 1
                $results += [PSCustomObject]@{
                    Module  = $moduleName
                    Success = $true
                    Action  = 'Newly Installed'
                    Version = $installedModule.Version
                }
            }
            else {
                $failedModules += $moduleName
                $results += [PSCustomObject]@{
                    Module  = $moduleName
                    Success = $false
                    Action  = 'Installation Failed'
                    Version = 'N/A'
                }
            }
        }
        
        Write-Host ''
    }

    # Summary
    Write-Host '═══════════════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Host '  Installation Summary' -ForegroundColor Cyan
    Write-Host '═══════════════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Host ''

    $results | Format-Table -AutoSize

    $successCount = ($results | Where-Object { $_.Success }).Count
    $failureCount = ($results | Where-Object { -not $_.Success }).Count

    Write-Host "Total Modules: $($results.Count)" -ForegroundColor White
    Write-Host "Successful: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failureCount" -ForegroundColor Red
    Write-Host ''

    if ($failedModules.Count -gt 0) {
        Write-Warning "Failed to install the following modules:"
        foreach ($module in $failedModules) {
            Write-Host "  - $module" -ForegroundColor Red
        }
        Write-Host ''
        Write-Host 'Possible causes:' -ForegroundColor Yellow
        Write-Host '  1. Network connectivity issues or firewall restrictions' -ForegroundColor Gray
        Write-Host '  2. PowerShell Gallery service unavailable' -ForegroundColor Gray
        Write-Host '  3. Module not found in PSGallery' -ForegroundColor Gray
        Write-Host '  4. Insufficient permissions' -ForegroundColor Gray
        Write-Host ''
        exit 1
    }
    else {
        Write-Host '✓ All modules installed successfully!' -ForegroundColor Green
        Write-Host ''
        
        # Display loaded modules for verification
        Write-Host 'Testing module imports...' -ForegroundColor Yellow
        foreach ($moduleName in $RequiredModules) {
            try {
                Import-Module $moduleName -Force -ErrorAction Stop
                Write-Host "  ✓ $moduleName imported successfully" -ForegroundColor Green
            }
            catch {
                Write-Warning "  ⚠ Failed to import $moduleName : $($_.Exception.Message)"
            }
        }
        
        Write-Host ''
        exit 0
    }
}
catch {
    Write-Error "Module installation script failed: $($_.Exception.Message)"
    Write-Host ''
    Write-Host 'Stack Trace:' -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    exit 1
}
