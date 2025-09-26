# Test Azure Policy Compliance Script
# This script tests compliance for deployed Azure policies

<#
.SYNOPSIS
    Test compliance for Azure policy definitions
.DESCRIPTION
    This script tests policy compliance and generates reports
.PARAMETER PolicyName
    Name of specific policy to test (optional)
.PARAMETER Scope
    Azure scope for compliance testing
.PARAMETER OutputFormat
    Output format: Table, JSON, CSV
.PARAMETER ExportPath
    Path to export compliance report
.EXAMPLE
    ./Test-PolicyCompliance.ps1 -Scope "/subscriptions/12345678-1234-1234-1234-123456789012"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$PolicyName,

    [Parameter(Mandatory = $false)]
    [string]$Scope,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Table', 'JSON', 'CSV')]
    [string]$OutputFormat = 'Table',

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

# Import required modules
Import-Module Az.Accounts -Force
Import-Module Az.PolicyInsights -Force

function Get-PolicyComplianceData {
    <#
    .SYNOPSIS
    Get policy compliance data from Azure
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$PolicyDefinitionName,

        [Parameter(Mandatory = $false)]
        [string]$ResourceScope
    )

    try {
        $QueryParams = @{}

        if ($PolicyDefinitionName) {
            $QueryParams.PolicyDefinitionName = $PolicyDefinitionName
        }

        if ($ResourceScope) {
            $QueryParams.Filter = "Scope eq '$ResourceScope'"
        }

        Write-Host 'Retrieving policy compliance data...' -ForegroundColor Yellow

        $ComplianceStates = Get-AzPolicyState @QueryParams

        if ($ComplianceStates) {
            Write-Host "Found $($ComplianceStates.Count) compliance records" -ForegroundColor Green
            return $ComplianceStates
        }
        else {
            Write-Host 'No compliance data found' -ForegroundColor Yellow
            return @()
        }
    }
    catch {
        Write-Error "Failed to retrieve compliance data: $($_.Exception.Message)"
        return @()
    }
}

function Format-ComplianceReport {
    <#
    .SYNOPSIS
    Format compliance data into a report
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$ComplianceData,

        [Parameter(Mandatory = $true)]
        [string]$Format
    )

    if ($ComplianceData.Count -eq 0) {
        return 'No compliance data available'
    }

    # Create summary data
    $Summary = $ComplianceData | Group-Object ComplianceState | ForEach-Object {
        [PSCustomObject]@{
            ComplianceState = $_.Name
            Count           = $_.Count
            Percentage      = [math]::Round(($_.Count / $ComplianceData.Count) * 100, 2)
        }
    }

    # Create detailed data
    $Details = $ComplianceData | ForEach-Object {
        [PSCustomObject]@{
            PolicyDefinitionName = $_.PolicyDefinitionName
            ResourceId           = $_.ResourceId
            ResourceType         = $_.ResourceType
            ComplianceState      = $_.ComplianceState
            Timestamp            = $_.Timestamp
            PolicyAssignmentName = $_.PolicyAssignmentName
        }
    }

    switch ($Format) {
        'Table' {
            $Output = @()
            $Output += '=== Policy Compliance Summary ==='
            $Output += ''
            $Output += $Summary | Format-Table -AutoSize | Out-String
            $Output += ''
            $Output += '=== Detailed Compliance Report ==='
            $Output += ''
            $Output += $Details | Format-Table -AutoSize | Out-String
            return $Output -join "`n"
        }
        'JSON' {
            $Report = @{
                Summary      = $Summary
                Details      = $Details
                GeneratedAt  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                TotalRecords = $ComplianceData.Count
            }
            return $Report | ConvertTo-Json -Depth 10
        }
        'CSV' {
            return $Details | ConvertTo-Csv -NoTypeInformation
        }
        default {
            return $Details | Format-Table -AutoSize | Out-String
        }
    }
}

function Export-ComplianceReport {
    <#
    .SYNOPSIS
    Export compliance report to file
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Report,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Format
    )

    try {
        $Extension = switch ($Format) {
            'JSON' { '.json' }
            'CSV' { '.csv' }
            default { '.txt' }
        }

        $FullPath = if ($Path.EndsWith($Extension)) { $Path } else { "$Path$Extension" }

        $Report | Out-File -FilePath $FullPath -Encoding UTF8
        Write-Host "Report exported to: $FullPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to export report: $($_.Exception.Message)"
    }
}

# Main execution
try {
    Write-Host 'Azure Policy Compliance Testing' -ForegroundColor Cyan
    Write-Host '===============================' -ForegroundColor Cyan

    # Check Azure authentication
    $Context = Get-AzContext
    if (-not $Context) {
        Write-Host 'Not authenticated to Azure. Attempting to connect...' -ForegroundColor Yellow
        Connect-AzAccount
        $Context = Get-AzContext

        if (-not $Context) {
            throw 'Failed to authenticate to Azure'
        }
    }

    Write-Host 'Connected to Azure:' -ForegroundColor Green
    Write-Host "  Account: $($Context.Account.Id)" -ForegroundColor White
    Write-Host "  Subscription: $($Context.Subscription.Name) ($($Context.Subscription.Id))" -ForegroundColor White

    # Use current subscription as default scope if not provided
    if (-not $Scope) {
        $Scope = "/subscriptions/$($Context.Subscription.Id)"
        Write-Host "Using current subscription as scope: $Scope" -ForegroundColor Yellow
    }

    Write-Host "`nTesting Parameters:" -ForegroundColor White
    if ($PolicyName) {
        Write-Host "  Policy: $PolicyName" -ForegroundColor Gray
    }
    else {
        Write-Host '  Policy: All policies' -ForegroundColor Gray
    }
    Write-Host "  Scope: $Scope" -ForegroundColor Gray
    Write-Host "  Output Format: $OutputFormat" -ForegroundColor Gray

    # Get compliance data
    $ComplianceData = Get-PolicyComplianceData -PolicyDefinitionName $PolicyName -ResourceScope $Scope

    # Generate report
    $Report = Format-ComplianceReport -ComplianceData $ComplianceData -Format $OutputFormat

    # Display report
    Write-Host "`n$Report" -ForegroundColor White

    # Export report if requested
    if ($ExportPath) {
        Export-ComplianceReport -Report $Report -Path $ExportPath -Format $OutputFormat
    }

    # Exit with appropriate code
    if ($ComplianceData.Count -eq 0) {
        Write-Host "`nNo compliance data found" -ForegroundColor Yellow
        exit 0
    }

    $NonCompliantCount = ($ComplianceData | Where-Object { $_.ComplianceState -eq 'NonCompliant' }).Count

    if ($NonCompliantCount -gt 0) {
        Write-Host "`nWarning: $NonCompliantCount non-compliant resources found" -ForegroundColor Yellow
        exit 0  # Non-compliance is not an error, just information
    }
    else {
        Write-Host "`nAll resources are compliant! ✓" -ForegroundColor Green
        exit 0
    }
}
catch {
    Write-Error "Compliance testing failed: $($_.Exception.Message)"
    exit 1
}
