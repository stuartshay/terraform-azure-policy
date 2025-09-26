# Generate Azure Policy Reports
# This script generates comprehensive reports for Azure Policy assignments and compliance

<#
.SYNOPSIS
    Generate reports for Azure Policy assignments and compliance in a resource group
.DESCRIPTION
    This script creates detailed reports showing all policy assignments and their compliance
    status within a specified resource group. Reports can be generated in multiple formats.
.PARAMETER ResourceGroup
    Name of the resource group to analyze
.PARAMETER ReportType
    Type of report to generate: All, Assignments, Compliance
.PARAMETER Format
    Output format: JSON, CSV, HTML, All
.PARAMETER OutputPath
    Directory to save reports (defaults to ./reports)
.EXAMPLE
    ./Generate-PolicyReports.ps1 -ResourceGroup "rg-azure-policy-testing"
.EXAMPLE
    ./Generate-PolicyReports.ps1 -ResourceGroup "rg-azure-policy-testing" -Format "CSV" -ReportType "Assignments"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Assignments", "Compliance")]
    [string]$ReportType = "All",

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "HTML", "All")]
    [string]$Format = "All",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./reports"
)

function Get-PolicyAssignments {
    <#
    .SYNOPSIS
    Get all policy assignments for a resource group
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName
    )

    try {
        Write-Host "Retrieving policy assignments for resource group: $ResourceGroupName" -ForegroundColor Yellow

        $Assignments = az policy assignment list --resource-group $ResourceGroupName | ConvertFrom-Json

        if (-not $Assignments) {
            Write-Warning "No policy assignments found in resource group: $ResourceGroupName"
            return @()
        }

        $AssignmentDetails = foreach ($Assignment in $Assignments) {
            # Get policy definition details
            $PolicyDef = az policy definition show --name (Split-Path $Assignment.policyDefinitionId -Leaf) 2>$null | ConvertFrom-Json

            [PSCustomObject]@{
                AssignmentName = $Assignment.name
                DisplayName = $Assignment.displayName
                Description = $Assignment.description
                PolicyDefinitionId = $Assignment.policyDefinitionId
                PolicyDefinitionName = if ($PolicyDef) { $PolicyDef.displayName } else { Split-Path $Assignment.policyDefinitionId -Leaf }
                PolicyType = if ($PolicyDef) { $PolicyDef.policyType } else { "Unknown" }
                Category = if ($PolicyDef -and $PolicyDef.metadata.category) { $PolicyDef.metadata.category } else { "Unspecified" }
                Effect = if ($Assignment.parameters -and $Assignment.parameters.effect) { $Assignment.parameters.effect.value } else { "Default" }
                Scope = $Assignment.scope
                EnforcementMode = if ($Assignment.enforcementMode) { $Assignment.enforcementMode } else { "Default" }
                Identity = if ($Assignment.identity) { $Assignment.identity.type } else { "None" }
                CreatedBy = if ($Assignment.metadata -and $Assignment.metadata.createdBy) { $Assignment.metadata.createdBy } else { "Unknown" }
                CreatedOn = if ($Assignment.metadata -and $Assignment.metadata.createdOn) { $Assignment.metadata.createdOn } else { "Unknown" }
                UpdatedBy = if ($Assignment.metadata -and $Assignment.metadata.updatedBy) { $Assignment.metadata.updatedBy } else { "Unknown" }
                UpdatedOn = if ($Assignment.metadata -and $Assignment.metadata.updatedOn) { $Assignment.metadata.updatedOn } else { "Unknown" }
            }
        }

        Write-Host "Found $($AssignmentDetails.Count) policy assignment(s)" -ForegroundColor Green
        return $AssignmentDetails
    }
    catch {
        Write-Error "Failed to retrieve policy assignments: $($_.Exception.Message)"
        return @()
    }
}

function Get-PolicyCompliance {
    <#
    .SYNOPSIS
    Get policy compliance status for a resource group
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName
    )

    try {
        Write-Host "Retrieving policy compliance for resource group: $ResourceGroupName" -ForegroundColor Yellow

        # Trigger compliance scan first
        Write-Host "Triggering policy compliance scan..." -ForegroundColor Gray
        az policy state trigger-scan --resource-group $ResourceGroupName 2>$null

        # Wait a moment for scan to process
        Start-Sleep -Seconds 5

        $ComplianceStates = az policy state list --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json

        if (-not $ComplianceStates) {
            Write-Warning "No compliance data found for resource group: $ResourceGroupName"
            return @()
        }

        $ComplianceDetails = foreach ($State in $ComplianceStates) {
            [PSCustomObject]@{
                ResourceId = $State.resourceId
                ResourceName = Split-Path $State.resourceId -Leaf
                ResourceType = if ($State.resourceType) { $State.resourceType } else { "Unknown" }
                PolicyDefinitionName = $State.policyDefinitionName
                PolicyAssignmentName = $State.policyAssignmentName
                ComplianceState = $State.complianceState
                Timestamp = $State.timestamp
                IsCompliant = $State.complianceState -eq "Compliant"
                ComplianceReasonCode = if ($State.complianceReasonCode) { $State.complianceReasonCode } else { "N/A" }
                PolicyDefinitionAction = if ($State.policyDefinitionAction) { $State.policyDefinitionAction } else { "N/A" }
                PolicyAssignmentScope = if ($State.policyAssignmentScope) { $State.policyAssignmentScope } else { "N/A" }
            }
        }

        Write-Host "Found $($ComplianceDetails.Count) compliance record(s)" -ForegroundColor Green
        return $ComplianceDetails
    }
    catch {
        Write-Error "Failed to retrieve policy compliance: $($_.Exception.Message)"
        return @()
    }
}

function Export-ReportData {
    <#
    .SYNOPSIS
    Export report data in specified format
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$ExportFormat
    )

    try {
        switch ($ExportFormat) {
            "JSON" {
                $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $FilePath -Encoding UTF8
            }
            "CSV" {
                $Data | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8
            }
            "HTML" {
                $Html = Generate-HtmlReport -Data $Data -Title (Split-Path $FilePath -LeafBase)
                $Html | Out-File -FilePath $FilePath -Encoding UTF8
            }
        }
        Write-Host "  ✓ Exported to: $FilePath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to export to $FilePath : $($_.Exception.Message)"
    }
}

function Generate-HtmlReport {
    <#
    .SYNOPSIS
    Generate HTML report from data
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,

        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    $Html = @"
<!DOCTYPE html>
<html>
<head>
    <title>$Title</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0066cc; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .compliant { color: green; font-weight: bold; }
        .non-compliant { color: red; font-weight: bold; }
        .summary { background-color: #e6f3ff; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>$Title</h1>
    <div class="summary">
        <strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')<br>
        <strong>Total Records:</strong> $($Data.Count)
    </div>
    <table>
        <thead>
            <tr>
"@

    # Add table headers
    if ($Data.Count -gt 0) {
        $Properties = $Data[0].PSObject.Properties.Name
        foreach ($Property in $Properties) {
            $Html += "<th>$Property</th>"
        }
    }

    $Html += "</tr></thead><tbody>"

    # Add table rows
    foreach ($Item in $Data) {
        $Html += "<tr>"
        foreach ($Property in $Properties) {
            $Value = $Item.$Property
            $CssClass = ""

            # Add special formatting for compliance state
            if ($Property -eq "ComplianceState") {
                $CssClass = if ($Value -eq "Compliant") { "compliant" } else { "non-compliant" }
            }

            $Html += "<td class='$CssClass'>$Value</td>"
        }
        $Html += "</tr>"
    }

    $Html += @"
        </tbody>
    </table>
</body>
</html>
"@

    return $Html
}

# Main execution
try {
    Write-Host "Azure Policy Report Generator" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
    Write-Host "Report Type: $ReportType" -ForegroundColor White
    Write-Host "Format: $Format" -ForegroundColor White
    Write-Host "Output Path: $OutputPath" -ForegroundColor White

    # Check if Azure CLI is available and authenticated
    $AzVersion = az version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI not found. Please install Azure CLI first."
    }

    $Account = az account show 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        throw "Not authenticated to Azure. Please run 'az login' first."
    }

    Write-Host "`nAuthenticated as: $($Account.user.name)" -ForegroundColor Green
    Write-Host "Subscription: $($Account.name) ($($Account.id))" -ForegroundColor Green

    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Host "`nCreated output directory: $OutputPath" -ForegroundColor Green
    }

    # Generate timestamp for file names
    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $ResourceGroupClean = $ResourceGroup -replace '[^a-zA-Z0-9-]', '-'

    # Generate policy assignments report
    if ($ReportType -in @("All", "Assignments")) {
        Write-Host "`n=== Generating Policy Assignments Report ===" -ForegroundColor Cyan
        $Assignments = Get-PolicyAssignments -ResourceGroupName $ResourceGroup

        if ($Assignments.Count -gt 0) {
            $Formats = if ($Format -eq "All") { @("JSON", "CSV", "HTML") } else { @($Format) }

            foreach ($ExportFormat in $Formats) {
                $Extension = $ExportFormat.ToLower()
                $FileName = "policy-assignments-$ResourceGroupClean-$Timestamp.$Extension"
                $FilePath = Join-Path $OutputPath $FileName

                Export-ReportData -Data $Assignments -FilePath $FilePath -ExportFormat $ExportFormat
            }
        }
    }

    # Generate policy compliance report
    if ($ReportType -in @("All", "Compliance")) {
        Write-Host "`n=== Generating Policy Compliance Report ===" -ForegroundColor Cyan
        $Compliance = Get-PolicyCompliance -ResourceGroupName $ResourceGroup

        if ($Compliance.Count -gt 0) {
            $Formats = if ($Format -eq "All") { @("JSON", "CSV", "HTML") } else { @($Format) }

            foreach ($ExportFormat in $Formats) {
                $Extension = $ExportFormat.ToLower()
                $FileName = "policy-compliance-$ResourceGroupClean-$Timestamp.$Extension"
                $FilePath = Join-Path $OutputPath $FileName

                Export-ReportData -Data $Compliance -FilePath $FilePath -ExportFormat $ExportFormat
            }

            # Display compliance summary
            $ComplianceStats = $Compliance | Group-Object ComplianceState
            Write-Host "`n=== Compliance Summary ===" -ForegroundColor Cyan
            foreach ($Stat in $ComplianceStats) {
                $Color = if ($Stat.Name -eq "Compliant") { "Green" } else { "Red" }
                Write-Host "$($Stat.Name): $($Stat.Count)" -ForegroundColor $Color
            }
        } else {
            Write-Host "No compliance data available. This may be normal for newly created policies." -ForegroundColor Yellow
            Write-Host "Policy evaluation can take up to 15 minutes for new assignments." -ForegroundColor Yellow
        }
    }

    Write-Host "`n✓ Report generation completed successfully!" -ForegroundColor Green
    Write-Host "Reports saved to: $OutputPath" -ForegroundColor White
}
catch {
    Write-Error "Report generation failed: $($_.Exception.Message)"
    exit 1
}
