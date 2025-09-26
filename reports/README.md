# Azure Policy Reports

This directory contains generated reports for Azure Policy assignments and compliance status.

## Report Types

### Policy Assignment Reports

- Lists all policy assignments in the resource group
- Shows policy definition details and assignment status
- Generated using PowerShell scripts

### Compliance Reports

- Shows compliance status for each policy assignment
- Includes compliant and non-compliant resources
- Available in multiple formats (JSON, CSV, HTML)

## Generated Files

The following files are automatically generated and should not be edited manually:

- `policy-assignments-*.json` - Policy assignment details in JSON format
- `policy-compliance-*.json` - Compliance status in JSON format
- `policy-assignments-*.csv` - Policy assignment details in CSV format
- `policy-compliance-*.csv` - Compliance status in CSV format
- `policy-report-*.html` - Combined HTML report with assignments and compliance

## Usage

### Generate All Reports

```powershell
./scripts/Generate-PolicyReports.ps1 -ResourceGroup "rg-azure-policy-testing"
```

### Generate Specific Report Type

```powershell
# Policy assignments only
./scripts/Generate-PolicyReports.ps1 -ResourceGroup "rg-azure-policy-testing" -ReportType "Assignments"

# Compliance only
./scripts/Generate-PolicyReports.ps1 -ResourceGroup "rg-azure-policy-testing" -ReportType "Compliance"
```

### Export Formats

```powershell
# Export to CSV
./scripts/Generate-PolicyReports.ps1 -ResourceGroup "rg-azure-policy-testing" -Format "CSV"

# Export to JSON
./scripts/Generate-PolicyReports.ps1 -ResourceGroup "rg-azure-policy-testing" -Format "JSON"

# Export to HTML
./scripts/Generate-PolicyReports.ps1 -ResourceGroup "rg-azure-policy-testing" -Format "HTML"
```

## File Naming Convention

Reports use the following naming convention:

- `policy-assignments-{resource-group}-{timestamp}.{format}`
- `policy-compliance-{resource-group}-{timestamp}.{format}`
- `policy-report-{resource-group}-{timestamp}.html`

Example:

- `policy-assignments-rg-azure-policy-testing-20250926-174530.json`
- `policy-compliance-rg-azure-policy-testing-20250926-174530.csv`

## Retention

Reports are kept for historical analysis. Old reports can be manually deleted or archived as needed.
