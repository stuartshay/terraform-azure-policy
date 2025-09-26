# Deploy Azure Policy Definitions Script
# This script deploys Azure policy definitions to Azure

<#
.SYNOPSIS
    Deploy Azure policy definitions from JSON files
.DESCRIPTION
    This script reads policy definition files and deploys them to Azure
.PARAMETER PolicyPath
    Path to the policy definition file or directory containing policy files
.PARAMETER ManagementGroupId
    Management Group ID for deployment scope
.PARAMETER SubscriptionId
    Subscription ID for deployment scope
.PARAMETER WhatIf
    Show what would be deployed without actually deploying
.EXAMPLE
    ./Deploy-PolicyDefinitions.ps1 -PolicyPath "./policies" -ManagementGroupId "mg-01"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PolicyPath,

    [Parameter(Mandatory = $false)]
    [string]$ManagementGroupId,

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Import required modules
Import-Module Az.Accounts -Force
Import-Module Az.Resources -Force

function Deploy-PolicyDefinition {
    <#
    .SYNOPSIS
    Deploy a single policy definition
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$ManagementGroup,

        [Parameter(Mandatory = $false)]
        [string]$Subscription,

        [Parameter(Mandatory = $false)]
        [switch]$WhatIfPreference
    )

    try {
        $Content = Get-Content $FilePath -Raw
        $PolicyDefinition = $Content | ConvertFrom-Json

        $PolicyName = $PolicyDefinition.name
        $DisplayName = $PolicyDefinition.properties.displayName
        $Description = $PolicyDefinition.properties.description

        Write-Host "Deploying policy: $PolicyName" -ForegroundColor Yellow
        Write-Host "  Display Name: $DisplayName" -ForegroundColor White
        Write-Host "  Description: $Description" -ForegroundColor Gray

        if ($WhatIfPreference) {
            Write-Host "  [WHAT-IF] Would deploy policy definition" -ForegroundColor Cyan
            return $true
        }

        # Determine deployment scope
        $DeploymentParams = @{
            Name = $PolicyName
            Policy = $FilePath
            Verbose = $true
        }

        if ($ManagementGroup) {
            $DeploymentParams.ManagementGroupName = $ManagementGroup
            Write-Host "  Scope: Management Group ($ManagementGroup)" -ForegroundColor Gray
        }
        elseif ($Subscription) {
            $DeploymentParams.SubscriptionId = $Subscription
            Write-Host "  Scope: Subscription ($Subscription)" -ForegroundColor Gray
        }
        else {
            # Use current subscription context
            $Context = Get-AzContext
            if ($Context) {
                Write-Host "  Scope: Current Subscription ($($Context.Subscription.Id))" -ForegroundColor Gray
            }
            else {
                throw "No Azure context found. Please run Connect-AzAccount first."
            }
        }

        $Result = New-AzPolicyDefinition @DeploymentParams

        if ($Result) {
            Write-Host "  ✓ Successfully deployed" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "  ✗ Deployment failed" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-PolicyFiles {
    <#
    .SYNOPSIS
    Get all policy definition files from a path
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path $Path -PathType Leaf) {
        return @($Path)
    }
    elseif (Test-Path $Path -PathType Container) {
        return Get-ChildItem -Path $Path -Filter "*.json" -Recurse | ForEach-Object { $_.FullName }
    }
    else {
        throw "Path not found: $Path"
    }
}

# Main execution
try {
    Write-Host "Azure Policy Definition Deployment" -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Cyan

    if ($WhatIf) {
        Write-Host "[WHAT-IF MODE] No actual deployments will be made" -ForegroundColor Yellow
    }

    # Check Azure authentication
    $Context = Get-AzContext
    if (-not $Context) {
        Write-Host "Not authenticated to Azure. Attempting to connect..." -ForegroundColor Yellow
        Connect-AzAccount
        $Context = Get-AzContext

        if (-not $Context) {
            throw "Failed to authenticate to Azure"
        }
    }

    Write-Host "Connected to Azure:" -ForegroundColor Green
    Write-Host "  Account: $($Context.Account.Id)" -ForegroundColor White
    Write-Host "  Subscription: $($Context.Subscription.Name) ($($Context.Subscription.Id))" -ForegroundColor White

    # Get policy files
    $PolicyFiles = Get-PolicyFiles -Path $PolicyPath

    if ($PolicyFiles.Count -eq 0) {
        Write-Warning "No policy definition files found in: $PolicyPath"
        exit 0
    }

    Write-Host "`nFound $($PolicyFiles.Count) policy definition(s)" -ForegroundColor White

    # Deploy each policy
    $DeploymentResults = @()

    foreach ($File in $PolicyFiles) {
        Write-Host "`n--- Processing: $(Split-Path $File -Leaf) ---" -ForegroundColor Cyan

        $Success = Deploy-PolicyDefinition -FilePath $File -ManagementGroup $ManagementGroupId -Subscription $SubscriptionId -WhatIfPreference:$WhatIf

        $DeploymentResults += [PSCustomObject]@{
            File = $File
            Success = $Success
        }
    }

    # Summary
    $SuccessCount = ($DeploymentResults | Where-Object { $_.Success }).Count
    $FailureCount = ($DeploymentResults | Where-Object { -not $_.Success }).Count

    Write-Host "`n=== Deployment Summary ===" -ForegroundColor Cyan
    Write-Host "Total Policies: $($PolicyFiles.Count)" -ForegroundColor White
    Write-Host "Successful: $SuccessCount" -ForegroundColor Green
    Write-Host "Failed: $FailureCount" -ForegroundColor Red

    if ($FailureCount -gt 0) {
        Write-Host "`nFailed Deployments:" -ForegroundColor Red
        $DeploymentResults | Where-Object { -not $_.Success } | ForEach-Object {
            Write-Host "  - $(Split-Path $_.File -Leaf)" -ForegroundColor Red
        }
        exit 1
    }
    else {
        if ($WhatIf) {
            Write-Host "`nAll policies would deploy successfully! ✓" -ForegroundColor Green
        }
        else {
            Write-Host "`nAll policies deployed successfully! ✓" -ForegroundColor Green
        }
        exit 0
    }
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}
