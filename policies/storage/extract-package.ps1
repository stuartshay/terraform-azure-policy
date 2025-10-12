# Azure Storage Policy Bundle Package Extraction Script
# This script is executed automatically when the NuGet package is installed
# NOTE: This extracts package contents only - it does NOT deploy policies to Azure
# For Azure deployment, use initiatives in /initiatives/storage/

param(
    [Parameter(Mandatory=$false)]
    [string]$InstallPath = $PSScriptRoot,

    [Parameter(Mandatory=$false)]
    [string]$ToolsPath = $PSScriptRoot,

    [Parameter(Mandatory=$false)]
    [string]$Package,

    [Parameter(Mandatory=$false)]
    [string]$Project
)

$ErrorActionPreference = "Stop"

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "Azure Storage Security Policies Bundle" -ForegroundColor Cyan
Write-Host "Version: 1.0.0" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# Display installation information
Write-Host "✓ Package installed successfully" -ForegroundColor Green
Write-Host ""

# Show bundle contents
Write-Host "Bundle Contents:" -ForegroundColor Yellow
Write-Host "  • deny-storage-account-public-access (CKV_AZURE_190)" -ForegroundColor White
Write-Host "  • deny-storage-blob-logging-disabled (CKV2_AZURE_21)" -ForegroundColor White
Write-Host "  • deny-storage-https-disabled" -ForegroundColor White
Write-Host "  • deny-storage-softdelete" -ForegroundColor White
Write-Host "  • deny-storage-version" -ForegroundColor White
Write-Host ""

# Display package location
$packagePath = Split-Path -Parent $InstallPath
Write-Host "Package Location:" -ForegroundColor Yellow
Write-Host "  $packagePath" -ForegroundColor White
Write-Host ""

# Display next steps
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Navigate to the package content directory" -ForegroundColor White
Write-Host "  2. Review the documentation in docs/README.md" -ForegroundColor White
Write-Host "  3. Configure your deployment in Terraform" -ForegroundColor White
Write-Host "  4. Run 'terraform init' and 'terraform plan'" -ForegroundColor White
Write-Host ""

# Display quick start
Write-Host "Quick Start:" -ForegroundColor Yellow
Write-Host "  # Extract package contents" -ForegroundColor White
Write-Host "  cd `"$packagePath\content`"" -ForegroundColor Gray
Write-Host ""
Write-Host "  # View documentation" -ForegroundColor White
Write-Host "  Get-Content docs\README.md" -ForegroundColor Gray
Write-Host ""
Write-Host "  # Initialize Terraform" -ForegroundColor White
Write-Host "  cd terraform" -ForegroundColor Gray
Write-Host "  terraform init" -ForegroundColor Gray
Write-Host ""

# Display deployment example
Write-Host "Terraform Deployment Example:" -ForegroundColor Yellow
Write-Host @"
module "storage_policies" {
  source = "./modules/azure-policy"

  assignment_scope_id = "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/YOUR_RG"
  environment         = "production"
  policy_effect       = "Deny"
}
"@ -ForegroundColor Gray
Write-Host ""

# Display additional resources
Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  • Bundle README: $packagePath\docs\README.md" -ForegroundColor White
Write-Host "  • Changelog: $packagePath\docs\CHANGELOG.md" -ForegroundColor White
Write-Host "  • Metadata: $packagePath\metadata\bundle.metadata.json" -ForegroundColor White
Write-Host ""

Write-Host "Support:" -ForegroundColor Yellow
Write-Host "  • GitHub: https://github.com/stuartshay/terraform-azure-policy" -ForegroundColor White
Write-Host "  • Issues: https://github.com/stuartshay/terraform-azure-policy/issues" -ForegroundColor White
Write-Host ""

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Cyan
