# Generate Azure Checkov Policies Report
# This script extracts all Azure Checkov vulnerabilities and generates an Excel report

<#
.SYNOPSIS
    Generate comprehensive Excel report for Azure Checkov policies (CKV_AZURE and CKV2_AZURE)
.DESCRIPTION
    This script downloads the Checkov Policy Index, extracts all Azure-specific policies,
    and generates a detailed Excel report with multiple sheets for analysis and filtering.
    The report includes policy details, summaries, and breakdowns by platform and resource type.
.PARAMETER OutputPath
    Directory to save the report (defaults to ./output)
.PARAMETER FileName
    Custom filename for the report (defaults to auto-generated timestamp)
.PARAMETER OpenReport
    Switch to automatically open the generated Excel report
.EXAMPLE
    ./Generate-CheckovReport.ps1
.EXAMPLE
    ./Generate-CheckovReport.ps1 -OutputPath "C:\Output" -OpenReport
.EXAMPLE
    ./Generate-CheckovReport.ps1 -FileName "azure-checkov-policies.xlsx"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = './output',

    [Parameter(Mandatory = $false)]
    [string]$FileName,

    [Parameter(Mandatory = $false)]
    [switch]$OpenReport
)

# Import required modules
function Test-RequiredModule {
    <#
    .SYNOPSIS
    Check and install required PowerShell modules
    #>

    $RequiredModules = @('ImportExcel')
    $MissingModules = @()

    foreach ($Module in $RequiredModules) {
        if (-not (Get-Module -ListAvailable -Name $Module)) {
            $MissingModules += $Module
        }
    }

    if ($MissingModules.Count -gt 0) {
        Write-Host "Missing required modules: $($MissingModules -join ', ')" -ForegroundColor Yellow
        Write-Host 'Installing missing modules...' -ForegroundColor Yellow

        foreach ($Module in $MissingModules) {
            try {
                Install-Module -Name $Module -Force -Scope CurrentUser
                Write-Host "✓ Installed module: $Module" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to install module $Module : $($_.Exception.Message)"
                return $false
            }
        }
    }

    # Import modules
    foreach ($Module in $RequiredModules) {
        Import-Module -Name $Module -Force
    }

    return $true
}

function Get-CheckovPoliciesData {
    <#
    .SYNOPSIS
    Download and parse Checkov policies from the web
    #>

    try {
        Write-Host 'Downloading Checkov Policy Index...' -ForegroundColor Yellow

        $Uri = 'https://www.checkov.io/5.Policy%20Index/all.html'
        $Response = Invoke-WebRequest -Uri $Uri -UseBasicParsing

        if ($Response.StatusCode -ne 200) {
            throw "Failed to download policy data. Status code: $($Response.StatusCode)"
        }

        Write-Host '✓ Successfully downloaded policy data' -ForegroundColor Green
        return $Response.Content
    }
    catch {
        Write-Error "Failed to download Checkov policies: $($_.Exception.Message)"
        return $null
    }
}

function ConvertFrom-HtmlTable {
    <#
    .SYNOPSIS
    Parse HTML table content and extract Azure policies
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$HtmlContent
    )

    try {
        Write-Host 'Parsing HTML table data...' -ForegroundColor Yellow

        # Use regex to extract table rows
        $TableRowPattern = '<tr[^>]*>(.*?)</tr>'
        $CellPattern = '<td[^>]*>(.*?)</td>'

        $TableRows = [regex]::Matches($HtmlContent, $TableRowPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

        Write-Host "Found $($TableRows.Count) total rows in table" -ForegroundColor Gray

        $AzurePolicies = @()
        $RowCount = 0

        foreach ($Row in $TableRows) {
            $Cells = [regex]::Matches($Row.Groups[1].Value, $CellPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

            if ($Cells.Count -ge 7) {
                # Extract cell content and clean HTML tags
                $CellValues = foreach ($Cell in $Cells) {
                    $CellContent = $Cell.Groups[1].Value
                    # Remove HTML tags and decode entities
                    $CleanContent = $CellContent -replace '<[^>]+>', '' -replace '&lt;', '<' -replace '&gt;', '>' -replace '&amp;', '&'
                    $CleanContent.Trim()
                }

                $PolicyId = $CellValues[1]

                # Filter for Azure policies only
                if ($PolicyId -match '^CKV2?_AZURE_') {
                    # Extract link from the last cell
                    $LinkMatch = [regex]::Match($Cells[6].Groups[1].Value, 'href="([^"]+)"')
                    $Link = if ($LinkMatch.Success) { $LinkMatch.Groups[1].Value } else { '' }

                    $Policy = [PSCustomObject]@{
                        Row_ID              = $CellValues[0]
                        Policy_ID           = $CellValues[1]
                        Policy_Type         = $CellValues[2]
                        Resource_Type       = $CellValues[3]
                        Description         = $CellValues[4]
                        Platform            = $CellValues[5]
                        Implementation_Link = $Link
                        File_Name           = $CellValues[6] -replace '<[^>]+>', ''
                    }

                    $AzurePolicies += $Policy
                }
            }

            $RowCount++
            if ($RowCount % 1000 -eq 0) {
                Write-Host "  Processed $RowCount rows..." -ForegroundColor Gray
            }
        }

        Write-Host "✓ Extracted $($AzurePolicies.Count) Azure policies" -ForegroundColor Green
        return $AzurePolicies
    }
    catch {
        Write-Error "Failed to parse HTML table: $($_.Exception.Message)"
        return @()
    }
}

function New-PolicySummary {
    <#
    .SYNOPSIS
    Generate summary statistics for the policies
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Policies
    )

    $CkvAzurePolicies = $Policies | Where-Object { $_.Policy_ID -match '^CKV_AZURE_' }
    $Ckv2AzurePolicies = $Policies | Where-Object { $_.Policy_ID -match '^CKV2_AZURE_' }

    $Summary = @(
        [PSCustomObject]@{ Metric = 'Total Azure Policies'; Count = $Policies.Count }
        [PSCustomObject]@{ Metric = 'CKV_AZURE Policies'; Count = $CkvAzurePolicies.Count }
        [PSCustomObject]@{ Metric = 'CKV2_AZURE Policies'; Count = $Ckv2AzurePolicies.Count }
        [PSCustomObject]@{ Metric = 'Unique Resource Types'; Count = ($Policies | Select-Object -ExpandProperty Resource_Type -Unique).Count }
        [PSCustomObject]@{ Metric = 'Terraform Policies'; Count = ($Policies | Where-Object { $_.Platform -eq 'Terraform' }).Count }
        [PSCustomObject]@{ Metric = 'ARM Policies'; Count = ($Policies | Where-Object { $_.Platform -eq 'arm' }).Count }
        [PSCustomObject]@{ Metric = 'Bicep Policies'; Count = ($Policies | Where-Object { $_.Platform -eq 'Bicep' }).Count }
    )

    return $Summary
}

function New-PlatformBreakdown {
    <#
    .SYNOPSIS
    Generate platform breakdown statistics
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Policies
    )

    $PlatformStats = $Policies | Group-Object -Property Platform |
        Select-Object @{Name = 'Platform'; Expression = { $_.Name } }, @{Name = 'Count'; Expression = { $_.Count } } |
        Sort-Object -Property Count -Descending

    return $PlatformStats
}

function New-ResourceBreakdown {
    <#
    .SYNOPSIS
    Generate resource type breakdown statistics (top 20)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Policies
    )

    $ResourceStats = $Policies | Group-Object -Property Resource_Type |
        Select-Object @{Name = 'Resource_Type'; Expression = { $_.Name } }, @{Name = 'Count'; Expression = { $_.Count } } |
        Sort-Object -Property Count -Descending |
        Select-Object -First 20

    return $ResourceStats
}

function New-ExcelReport {
    <#
    .SYNOPSIS
    Generate Excel report with multiple sheets, blue headers, and proper column sizing
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Policies,

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        Write-Host 'Generating Excel report...' -ForegroundColor Yellow

        # Separate policy types
        $CkvAzurePolicies = $Policies | Where-Object { $_.Policy_ID -match '^CKV_AZURE_' }
        $Ckv2AzurePolicies = $Policies | Where-Object { $_.Policy_ID -match '^CKV2_AZURE_' }

        # Generate summary data
        $Summary = New-PolicySummary -Policies $Policies
        $PlatformBreakdown = New-PlatformBreakdown -Policies $Policies
        $ResourceBreakdown = New-ResourceBreakdown -Policies $Policies

        # Create Excel workbook with multiple sheets
        Write-Host '  Creating Excel sheets...' -ForegroundColor Gray

        # Define column widths for policy sheets (columns 1-8)
        $PolicyColumnWidths = @(15, 25, 15, 50, 90, 15, 50, 30)  # Row_ID, Policy_ID, Policy_Type, Resource_Type, Description, Platform, Implementation_Link, File_Name

        # Define blue header style
        $HeaderStyle = New-ExcelStyle -BackgroundColor Blue -FontColor White -Bold -Range '1:1'

        # All Azure Policies sheet
        Write-Host '    Creating All Azure Policies sheet...' -ForegroundColor Gray
        $Policies | Export-Excel -Path $FilePath -WorksheetName 'All_Azure_Policies' -AutoFilter -FreezeTopRow -Style $HeaderStyle

        # Set column widths for All Azure Policies
        $ExcelPackage = Open-ExcelPackage -Path $FilePath
        $WorkSheet = $ExcelPackage.Workbook.Worksheets['All_Azure_Policies']
        for ($i = 0; $i -lt $PolicyColumnWidths.Count; $i++) {
            $WorkSheet.Column($i + 1).Width = $PolicyColumnWidths[$i]
        }
        Close-ExcelPackage -ExcelPackage $ExcelPackage

        # CKV_AZURE Policies sheet
        if ($CkvAzurePolicies.Count -gt 0) {
            Write-Host '    Creating CKV_AZURE Policies sheet...' -ForegroundColor Gray
            $CkvAzurePolicies | Export-Excel -Path $FilePath -WorksheetName 'CKV_AZURE_Policies' -AutoFilter -FreezeTopRow -Style $HeaderStyle

            # Set column widths for CKV_AZURE Policies
            $ExcelPackage = Open-ExcelPackage -Path $FilePath
            $WorkSheet = $ExcelPackage.Workbook.Worksheets['CKV_AZURE_Policies']
            for ($i = 0; $i -lt $PolicyColumnWidths.Count; $i++) {
                $WorkSheet.Column($i + 1).Width = $PolicyColumnWidths[$i]
            }
            Close-ExcelPackage -ExcelPackage $ExcelPackage
        }

        # CKV2_AZURE Policies sheet
        if ($Ckv2AzurePolicies.Count -gt 0) {
            Write-Host '    Creating CKV2_AZURE Policies sheet...' -ForegroundColor Gray
            $Ckv2AzurePolicies | Export-Excel -Path $FilePath -WorksheetName 'CKV2_AZURE_Policies' -AutoFilter -FreezeTopRow -Style $HeaderStyle

            # Set column widths for CKV2_AZURE Policies
            $ExcelPackage = Open-ExcelPackage -Path $FilePath
            $WorkSheet = $ExcelPackage.Workbook.Worksheets['CKV2_AZURE_Policies']
            for ($i = 0; $i -lt $PolicyColumnWidths.Count; $i++) {
                $WorkSheet.Column($i + 1).Width = $PolicyColumnWidths[$i]
            }
            Close-ExcelPackage -ExcelPackage $ExcelPackage
        }

        # Summary sheet
        Write-Host '    Creating Summary sheet...' -ForegroundColor Gray
        $Summary | Export-Excel -Path $FilePath -WorksheetName 'Summary' -AutoFilter -FreezeTopRow -Style $HeaderStyle

        # Set column widths for Summary
        $ExcelPackage = Open-ExcelPackage -Path $FilePath
        $WorkSheet = $ExcelPackage.Workbook.Worksheets['Summary']
        $WorkSheet.Column(1).Width = 30  # Metric
        $WorkSheet.Column(2).Width = 15  # Count
        Close-ExcelPackage -ExcelPackage $ExcelPackage

        # Platform breakdown sheet
        Write-Host '    Creating Platform Breakdown sheet...' -ForegroundColor Gray
        $PlatformBreakdown | Export-Excel -Path $FilePath -WorksheetName 'Platform_Breakdown' -AutoFilter -FreezeTopRow -Style $HeaderStyle

        # Set column widths for Platform Breakdown
        $ExcelPackage = Open-ExcelPackage -Path $FilePath
        $WorkSheet = $ExcelPackage.Workbook.Worksheets['Platform_Breakdown']
        $WorkSheet.Column(1).Width = 20  # Platform
        $WorkSheet.Column(2).Width = 15  # Count
        Close-ExcelPackage -ExcelPackage $ExcelPackage

        # Resource breakdown sheet
        Write-Host '    Creating Resource Breakdown sheet...' -ForegroundColor Gray
        $ResourceBreakdown | Export-Excel -Path $FilePath -WorksheetName 'Resource_Breakdown' -AutoFilter -FreezeTopRow -Style $HeaderStyle

        # Set column widths for Resource Breakdown
        $ExcelPackage = Open-ExcelPackage -Path $FilePath
        $WorkSheet = $ExcelPackage.Workbook.Worksheets['Resource_Breakdown']
        $WorkSheet.Column(1).Width = 40  # Resource_Type
        $WorkSheet.Column(2).Width = 15  # Count
        Close-ExcelPackage -ExcelPackage $ExcelPackage

        Write-Host '✓ Excel report created successfully with blue headers and optimized column widths' -ForegroundColor Green
        Write-Host "✓ Report contains $($Policies.Count) Azure policies" -ForegroundColor Green
        Write-Host "  - CKV_AZURE policies: $($CkvAzurePolicies.Count)" -ForegroundColor White
        Write-Host "  - CKV2_AZURE policies: $($Ckv2AzurePolicies.Count)" -ForegroundColor White

        return $true
    }
    catch {
        Write-Error "Failed to create Excel report: $($_.Exception.Message)"
        return $false
    }
}

function Show-PolicySummary {
    <#
    .SYNOPSIS
    Display policy summary to console
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Policies
    )

    $Summary = New-PolicySummary -Policies $Policies
    $ResourceStats = New-ResourceBreakdown -Policies $Policies

    Write-Host "`n=== Azure Checkov Policies Summary ===" -ForegroundColor Cyan
    foreach ($Stat in $Summary) {
        Write-Host "$($Stat.Metric): $($Stat.Count)" -ForegroundColor White
    }

    Write-Host "`n=== Top 5 Azure Resource Types ===" -ForegroundColor Cyan
    $ResourceStats | Select-Object -First 5 | ForEach-Object {
        Write-Host "$($_.Resource_Type): $($_.Count)" -ForegroundColor White
    }
}

# Main execution
try {
    Write-Host 'Azure Checkov Policies Report Generator' -ForegroundColor Cyan
    Write-Host '=======================================' -ForegroundColor Cyan
    Write-Host "Output Path: $OutputPath" -ForegroundColor White

    # Check and install required modules
    if (-not (Test-RequiredModule)) {
        throw 'Failed to install required modules'
    }

    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Host "✓ Created output directory: $OutputPath" -ForegroundColor Green
    }

    # Generate filename if not provided
    if ([string]::IsNullOrEmpty($FileName)) {
        $Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $FileName = "azure_checkov_policies_report_$Timestamp.xlsx"
    }

    $FilePath = Join-Path $OutputPath $FileName
    Write-Host "Report File: $FilePath" -ForegroundColor White

    # Download Checkov policy data
    $HtmlContent = Get-CheckovPoliciesData
    if ([string]::IsNullOrEmpty($HtmlContent)) {
        throw 'Failed to download policy data'
    }

    # Parse Azure policies from HTML
    $AzurePolicies = ConvertFrom-HtmlTable -HtmlContent $HtmlContent
    if ($AzurePolicies.Count -eq 0) {
        throw 'No Azure policies found in the data'
    }

    # Display summary to console
    Show-PolicySummary -Policies $AzurePolicies

    # Generate Excel report
    Write-Host "`n=== Generating Excel Report ===" -ForegroundColor Cyan
    $Success = New-ExcelReport -Policies $AzurePolicies -FilePath $FilePath

    if ($Success) {
        Write-Host "`n✓ Report generation completed successfully!" -ForegroundColor Green
        Write-Host "Report saved to: $FilePath" -ForegroundColor White

        # Open report if requested
        if ($OpenReport) {
            Write-Host 'Opening Excel report...' -ForegroundColor Yellow
            try {
                Start-Process -FilePath $FilePath
            }
            catch {
                Write-Warning "Could not open Excel report automatically: $($_.Exception.Message)"
            }
        }
    }
    else {
        throw 'Failed to generate Excel report'
    }
}
catch {
    Write-Error "Report generation failed: $($_.Exception.Message)"
    exit 1
}
