# Setup Azure Storage Backend for Terraform
# This script creates the required Azure Storage infrastructure for Terraform state management

<#
.SYNOPSIS
    Create Azure Storage backend infrastructure for Terraform state
.DESCRIPTION
    This script creates a storage account and container in the specified resource group
    for storing Terraform state files remotely in Azure Storage
.PARAMETER ResourceGroupName
    Name of the existing resource group
.PARAMETER StorageAccountName
    Name for the storage account (must be globally unique)
.PARAMETER ContainerName
    Name for the blob container that will store Terraform state files
.PARAMETER Location
    Azure region for the storage account
.EXAMPLE
    ./Setup-TerraformBackend.ps1 -ResourceGroupName "rg-azure-policy-testing"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = 'rg-azure-policy-testing',

    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName = 'staazurepolicytesting',

    [Parameter(Mandatory = $false)]
    [string]$ContainerName = 'state-files-sandbox',

    [Parameter(Mandatory = $false)]
    [string]$Location = 'East US'
)

try {
    Write-Host 'Azure Terraform Backend Setup' -ForegroundColor Cyan
    Write-Host '=============================' -ForegroundColor Cyan

    # Check if Azure CLI is available
    $AzVersion = az version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'Azure CLI not found. Please install Azure CLI first.'
    }

    Write-Host "Azure CLI Version: $(($AzVersion | ConvertFrom-Json).'azure-cli')" -ForegroundColor Green

    # Check if user is logged in
    Write-Host "`nChecking Azure authentication..." -ForegroundColor Yellow
    $Account = az account show 2>$null | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Not authenticated to Azure. Please login...' -ForegroundColor Yellow
        az login
        $Account = az account show | ConvertFrom-Json
    }

    Write-Host "Authenticated as: $($Account.user.name)" -ForegroundColor Green
    Write-Host "Subscription: $($Account.name) ($($Account.id))" -ForegroundColor Green

    # Check if resource group exists
    Write-Host "`nChecking resource group: $ResourceGroupName" -ForegroundColor Yellow
    $ResourceGroup = az group show --name $ResourceGroupName 2>$null | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Resource group '$ResourceGroupName' not found. Creating..." -ForegroundColor Yellow
        az group create --name $ResourceGroupName --location $Location

        if ($LASTEXITCODE -eq 0) {
            Write-Host '✓ Resource group created successfully' -ForegroundColor Green
        }
        else {
            throw 'Failed to create resource group'
        }
    }
    else {
        Write-Host "✓ Resource group '$ResourceGroupName' exists" -ForegroundColor Green
    }

    # Check if storage account exists
    Write-Host "`nChecking storage account: $StorageAccountName" -ForegroundColor Yellow
    $StorageAccount = az storage account show --name $StorageAccountName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Storage account '$StorageAccountName' not found. Creating..." -ForegroundColor Yellow

        # Create storage account
        az storage account create `
            --name $StorageAccountName `
            --resource-group $ResourceGroupName `
            --location $Location `
            --sku 'Standard_LRS' `
            --kind 'StorageV2' `
            --access-tier 'Hot' `
            --https-only true `
            --min-tls-version 'TLS1_2' `
            --allow-blob-public-access false

        if ($LASTEXITCODE -eq 0) {
            Write-Host '✓ Storage account created successfully' -ForegroundColor Green
        }
        else {
            throw 'Failed to create storage account'
        }
    }
    else {
        Write-Host "✓ Storage account '$StorageAccountName' exists" -ForegroundColor Green
    }

    # Get storage account key
    Write-Host "`nRetrieving storage account key..." -ForegroundColor Yellow
    $StorageKey = (az storage account keys list --resource-group $ResourceGroupName --account-name $StorageAccountName --query '[0].value' --output tsv)

    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to retrieve storage account key'
    }

    # Check if container exists
    Write-Host "Checking blob container: $ContainerName" -ForegroundColor Yellow
    $Container = az storage container show --name $ContainerName --account-name $StorageAccountName --account-key $StorageKey 2>$null | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Container '$ContainerName' not found. Creating..." -ForegroundColor Yellow

        # Create blob container
        az storage container create `
            --name $ContainerName `
            --account-name $StorageAccountName `
            --account-key $StorageKey `
            --public-access off

        if ($LASTEXITCODE -eq 0) {
            Write-Host '✓ Blob container created successfully' -ForegroundColor Green
        }
        else {
            throw 'Failed to create blob container'
        }
    }
    else {
        Write-Host "✓ Blob container '$ContainerName' exists" -ForegroundColor Green
    }

    # Display configuration summary
    Write-Host "`n=== Backend Configuration Summary ===" -ForegroundColor Cyan
    Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "Storage Account: $StorageAccountName" -ForegroundColor White
    Write-Host "Container: $ContainerName" -ForegroundColor White
    Write-Host "Subscription: $($Account.id)" -ForegroundColor White

    # Create/update terraform backend configuration
    $BackendConfigPath = Join-Path $PSScriptRoot '..' 'config' 'backend' 'sandbox.tfbackend'
    $BackendConfig = @"
resource_group_name  = "$ResourceGroupName"
storage_account_name = "$StorageAccountName"
container_name       = "$ContainerName"
key                  = "sandbox.terraform.tfstate"
"@

    Write-Host "`nUpdating backend configuration file..." -ForegroundColor Yellow
    $BackendConfig | Out-File -FilePath $BackendConfigPath -Encoding UTF8
    Write-Host "✓ Backend configuration updated: $BackendConfigPath" -ForegroundColor Green

    # Create terraform.tfvars from the sandbox config
    $TerraformVarsPath = Join-Path $PSScriptRoot '..' 'terraform' 'policy-definitions' 'terraform.tfvars'
    $SandboxConfigPath = Join-Path $PSScriptRoot '..' 'config' 'vars' 'sandbox.tfvars.json'

    if (Test-Path $SandboxConfigPath) {
        Write-Host "`nCreating terraform.tfvars from sandbox configuration..." -ForegroundColor Yellow
        $SandboxConfig = Get-Content $SandboxConfigPath -Raw | ConvertFrom-Json

        $TerraformVars = @"
# Terraform Variables for Storage Public Access Policy
# Generated from sandbox configuration

# Azure Configuration
subcription_id     = "$($SandboxConfig.subcription_id)"
mangement_group_id = "$($SandboxConfig.mangement_group_id)"
scope_id          = "$($SandboxConfig.scope_id)"

# Policy Assignment Configuration
policy_assignment_name         = "deny-storage-public-access-assignment"
policy_assignment_display_name = "Deny Storage Account Public Access Assignment"
policy_assignment_description  = "This assignment enforces the policy to deny storage accounts with public access enabled."

# Policy Parameters
policy_effect               = "Audit"  # Start with Audit mode for testing
exempted_resource_groups   = []        # Add any resource groups to exempt

# Environment Configuration
environment = "sandbox"
owner      = "Policy-Team"
"@

        $TerraformVars | Out-File -FilePath $TerraformVarsPath -Encoding UTF8
        Write-Host "✓ Terraform variables created: $TerraformVarsPath" -ForegroundColor Green
        Write-Host "  Note: Policy effect is set to 'Audit' for safe testing" -ForegroundColor Yellow
    }

    Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
    Write-Host '1. Review and update terraform.tfvars if needed' -ForegroundColor White
    Write-Host '2. Initialize Terraform: ./scripts/Deploy-StoragePolicy.ps1 -Action init' -ForegroundColor White
    Write-Host '3. Plan deployment: ./scripts/Deploy-StoragePolicy.ps1 -Action plan' -ForegroundColor White
    Write-Host '4. Apply policy: ./scripts/Deploy-StoragePolicy.ps1 -Action apply' -ForegroundColor White

    Write-Host "`n✓ Azure backend setup completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Backend setup failed: $($_.Exception.Message)"
    exit 1
}
