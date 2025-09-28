# Generate-CheckovReport.ps1

## Overview

PowerShell script to generate comprehensive Excel reports for Azure Checkov policies (CKV_AZURE and CKV2_AZURE) extracted from the Checkov Policy Index.

## Prerequisites

- PowerShell 5.1 or PowerShell Core 7+
- Internet connectivity to download Checkov Policy Index
- The script will automatically install the required `ImportExcel` module if not present

## Usage

### Basic Usage

```powershell
# Generate report with default settings
.\Generate-CheckovReport.ps1

# Generate report in custom directory
.\Generate-CheckovReport.ps1 -OutputPath "C:\Reports"

# Generate report with custom filename
.\Generate-CheckovReport.ps1 -FileName "my-azure-checkov-report.xlsx"

# Generate report and open it automatically
.\Generate-CheckovReport.ps1 -OpenReport
```

### Advanced Usage

```powershell
# Custom output path with auto-open
.\Generate-CheckovReport.ps1 -OutputPath ".\security-reports" -OpenReport

# Full custom configuration
.\Generate-CheckovReport.ps1 -OutputPath "C:\ComplianceReports" -FileName "checkov-audit-$(Get-Date -Format 'yyyy-MM-dd').xlsx" -OpenReport
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `OutputPath` | String | `./reports` | Directory to save the Excel report |
| `FileName` | String | Auto-generated timestamp | Custom filename for the report |
| `OpenReport` | Switch | False | Automatically open the Excel report after generation |

## Generated Report Structure

The Excel report contains **6 comprehensive sheets**:

### 1. All_Azure_Policies

Complete dataset of all Azure policies with columns:

- **Row_ID**: Sequential identifier from source
- **Policy_ID**: Checkov policy identifier (e.g., CKV_AZURE_1)
- **Policy_Type**: Type of policy check
- **Resource_Type**: Azure resource type being checked
- **Description**: Human-readable policy description
- **Platform**: Infrastructure as Code platform (Terraform, ARM, Bicep)
- **Implementation_Link**: GitHub link to policy source code
- **File_Name**: Source implementation filename

### 2. CKV_AZURE_Policies

Filtered view containing only CKV_AZURE policies (731 policies)

### 3. CKV2_AZURE_Policies  

Filtered view containing only CKV2_AZURE policies (110 policies)

### 4. Summary

Key statistics including:

- Total Azure Policies
- CKV_AZURE vs CKV2_AZURE breakdown
- Unique resource types count
- Platform distribution (Terraform, ARM, Bicep)

### 5. Platform_Breakdown

Distribution of policies by Infrastructure as Code platform

### 6. Resource_Breakdown

Top 20 Azure resource types by policy count

## Report Statistics (Current)

- **Total Azure Policies**: 841
- **CKV_AZURE Policies**: 731  
- **CKV2_AZURE Policies**: 110
- **Unique Resource Types**: 197
- **Platform Coverage**: Terraform (426), ARM (210), Bicep (205)

## Excel Features

- **Auto-filtering**: All sheets have filters enabled on header rows
- **Auto-sizing**: Column widths optimized for readability
- **Frozen headers**: Top row frozen for easy scrolling
- **Clickable links**: Implementation links are active hyperlinks

## Top Azure Resource Types

1. Microsoft.Web/sites (42 policies)
2. Microsoft.ContainerService/managedClusters (24 policies)  
3. azurerm_kubernetes_cluster (20 policies)
4. azurerm_storage_account (20 policies)
5. azurerm_app_service (19 policies)

## Error Handling

The script includes comprehensive error handling for:

- Network connectivity issues
- Module installation failures
- HTML parsing errors
- Excel file creation problems

## Troubleshooting

### Module Installation Issues

If the ImportExcel module fails to install:

```powershell
# Manual installation
Install-Module -Name ImportExcel -Force -Scope CurrentUser

# For corporate environments with restricted execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Network Connectivity

If unable to download the Checkov Policy Index:

- Check internet connectivity
- Verify proxy settings if behind corporate firewall
- Ensure access to <https://www.checkov.io>

### Excel File Issues

If Excel file creation fails:

- Ensure the output directory is writable
- Check available disk space
- Verify no other process has the target file open

## Performance Notes

- Download time: ~5-10 seconds depending on connection
- Processing time: ~30-60 seconds for full dataset
- File size: ~110KB for complete report

## Data Source

- **Source URL**: <https://www.checkov.io/5.Policy%20Index/all.html>
- **Update Frequency**: Data is fetched live from Checkov's official policy index
- **Data Freshness**: Always current as of script execution time

## Integration Examples

### Scheduled Task

```powershell
# Create scheduled task to run weekly
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\Generate-CheckovReport.ps1 -OutputPath C:\Reports"
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 9am
Register-ScheduledTask -TaskName "Weekly Checkov Report" -Action $Action -Trigger $Trigger
```

### Azure DevOps Pipeline

```yaml
- task: PowerShell@2
  displayName: 'Generate Checkov Report'
  inputs:
    filePath: 'scripts/Generate-CheckovReport.ps1'
    arguments: '-OutputPath $(Build.ArtifactStagingDirectory) -FileName "checkov-report-$(Build.BuildNumber).xlsx"'
```

### CI/CD Integration

```powershell
# Generate report and upload to SharePoint/Teams
.\Generate-CheckovReport.ps1 -OutputPath ".\temp"
# Add your upload logic here
```

## Version History

- **v1.0**: Initial PowerShell implementation
- **Features**: Excel generation, multi-sheet reports, auto-filtering

## Related Files

- `azure_checkov_report_generator.py` - Python equivalent script
- `validate_report.py` - Python report validation script

---
*This script is part of the Azure Policy Management toolkit.*
