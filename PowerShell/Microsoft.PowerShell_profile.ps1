# Azure Policy Testing PowerShell Profile
# This profile sets up the environment for Azure policy development and testing

# Import required modules for Azure policy work
$RequiredModules = @(
    'Az.Accounts',
    'Az.Resources',
    'Az.PolicyInsights',
    'PSScriptAnalyzer',
    'Pester'
)

# Check and install missing modules
foreach ($Module in $RequiredModules) {
    if (!(Get-Module -ListAvailable -Name $Module)) {
        Write-Host "Installing module: $Module" -ForegroundColor Yellow
        try {
            Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber
            Write-Host "Successfully installed: $Module" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to install module: $Module - $($_.Exception.Message)"
        }
    }
}

# Import modules silently
foreach ($Module in $RequiredModules) {
    try {
        Import-Module $Module -Force -DisableNameChecking -WarningAction SilentlyContinue
    }
    catch {
        Write-Warning "Failed to import module: $Module"
    }
}

# Set up environment variables for the project
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$env:AZURE_POLICY_PROJECT_ROOT = $ProjectRoot

# Custom functions for Azure policy testing
function Test-AzurePolicyCompliance {
    <#
    .SYNOPSIS
    Test Azure policy compliance for a specific scope

    .PARAMETER PolicyName
    Name of the policy to test

    .PARAMETER Scope
    Azure scope to test against
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PolicyName,

        [Parameter(Mandatory = $false)]
        [string]$Scope = "/subscriptions/$env:ARM_SUBSCRIPTION_ID"
    )

    try {
        $ComplianceResults = Get-AzPolicyState -ResourceGroupName $null -PolicyDefinitionName $PolicyName
        return $ComplianceResults
    }
    catch {
        Write-Error "Failed to get policy compliance: $($_.Exception.Message)"
    }
}

function Deploy-AzurePolicyDefinition {
    <#
    .SYNOPSIS
    Deploy an Azure policy definition from a JSON file

    .PARAMETER PolicyFile
    Path to the policy definition JSON file

    .PARAMETER ManagementGroupId
    Management group ID for policy deployment
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PolicyFile,

        [Parameter(Mandatory = $false)]
        [string]$ManagementGroupId
    )

    if (!(Test-Path $PolicyFile)) {
        Write-Error "Policy file not found: $PolicyFile"
        return
    }

    try {
        $PolicyContent = Get-Content $PolicyFile -Raw | ConvertFrom-Json
        $PolicyName = $PolicyContent.name

        if ($ManagementGroupId) {
            $Policy = New-AzPolicyDefinition -Name $PolicyName -Policy $PolicyFile -ManagementGroupName $ManagementGroupId
        }
        else {
            $Policy = New-AzPolicyDefinition -Name $PolicyName -Policy $PolicyFile
        }

        Write-Host "Successfully deployed policy: $PolicyName" -ForegroundColor Green
        return $Policy
    }
    catch {
        Write-Error "Failed to deploy policy: $($_.Exception.Message)"
    }
}

function Get-PolicyComplianceReport {
    <#
    .SYNOPSIS
    Generate a compliance report for all policies in a scope

    .PARAMETER Scope
    Azure scope to generate report for
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$Scope = "/subscriptions/$env:ARM_SUBSCRIPTION_ID"
    )

    try {
        $ComplianceStates = Get-AzPolicyState -ResourceGroupName $null | Group-Object ComplianceState

        Write-Host "`nPolicy Compliance Summary:" -ForegroundColor Cyan
        foreach ($State in $ComplianceStates) {
            Write-Host "$($State.Name): $($State.Count)" -ForegroundColor White
        }

        return $ComplianceStates
    }
    catch {
        Write-Error "Failed to generate compliance report: $($_.Exception.Message)"
    }
}

function Initialize-AzurePolicyProject {
    <#
    .SYNOPSIS
    Initialize the Azure policy testing environment
    #>

    # Load configuration from tfvars.json
    $ConfigPath = Join-Path $ProjectRoot 'config\vars\sandbox.tfvars.json'
    if (Test-Path $ConfigPath) {
        try {
            $Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            $env:ARM_SUBSCRIPTION_ID = $Config.subcription_id
            $env:ARM_MANAGEMENT_GROUP_ID = $Config.mangement_group_id

            Write-Host "Loaded configuration from: $ConfigPath" -ForegroundColor Green
            Write-Host "Subscription ID: $($Config.subcription_id)" -ForegroundColor White
            Write-Host "Management Group ID: $($Config.mangement_group_id)" -ForegroundColor White
        }
        catch {
            Write-Warning "Failed to load configuration: $($_.Exception.Message)"
        }
    }

    # Check Azure connection
    try {
        $Context = Get-AzContext
        if ($Context) {
            Write-Host "Connected to Azure as: $($Context.Account.Id)" -ForegroundColor Green
        }
        else {
            Write-Host 'Not connected to Azure. Run Connect-AzAccount to authenticate.' -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host 'Azure PowerShell not available or not authenticated.' -ForegroundColor Yellow
    }
}

# Set up aliases for convenience
Set-Alias -Name 'tpc' -Value 'Test-AzurePolicyCompliance'
Set-Alias -Name 'dpd' -Value 'Deploy-AzurePolicyDefinition'
Set-Alias -Name 'gcr' -Value 'Get-PolicyComplianceReport'
Set-Alias -Name 'init-azure' -Value 'Initialize-AzurePolicyProject'

# Display welcome message
Write-Host "`n=== Azure Policy Testing Environment ===" -ForegroundColor Cyan
Write-Host 'Available commands:' -ForegroundColor White
Write-Host '  Test-AzurePolicyCompliance (alias: tpc)' -ForegroundColor Gray
Write-Host '  Deploy-AzurePolicyDefinition (alias: dpd)' -ForegroundColor Gray
Write-Host '  Get-PolicyComplianceReport (alias: gcr)' -ForegroundColor Gray
Write-Host '  Initialize-AzurePolicyProject (alias: init-azure)' -ForegroundColor Gray
Write-Host "`nRun 'init-azure' to initialize the environment" -ForegroundColor Yellow
Write-Host "===============================================`n" -ForegroundColor Cyan

# Auto-initialize if requested
if ($env:AUTO_INIT_AZURE_POLICY -eq 'true') {
    Initialize-AzurePolicyProject
}
