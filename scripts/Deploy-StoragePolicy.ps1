# Deploy Storage Policy via Terraform
# This script deploys the Azure Policy for denying storage account public access

<#
.SYNOPSIS
    Deploy the storage account public access denial policy using Terraform
.DESCRIPTION
    This script initializes and deploys the Terraform configuration for the Azure Policy
.PARAMETER Action
    Terraform action to perform: plan, apply, or destroy
.PARAMETER AutoApprove
    Skip interactive approval for apply/destroy actions
.PARAMETER VarFile
    Path to the Terraform variables file (defaults to terraform.tfvars)
.EXAMPLE
    ./Deploy-StoragePolicy.ps1 -Action plan
.EXAMPLE
    ./Deploy-StoragePolicy.ps1 -Action apply -AutoApprove
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('plan', 'apply', 'destroy', 'init')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [switch]$AutoApprove,

    [Parameter(Mandatory = $false)]
    [string]$VarFile = 'terraform.tfvars'
)

# Set working directory
$TerraformPath = Join-Path $PSScriptRoot '..' 'terraform' 'policy-definitions'

try {
    Write-Host 'Azure Policy Terraform Deployment' -ForegroundColor Cyan
    Write-Host '=================================' -ForegroundColor Cyan
    Write-Host "Action: $Action" -ForegroundColor White
    Write-Host "Path: $TerraformPath" -ForegroundColor White

    # Change to Terraform directory
    Push-Location $TerraformPath

    # Check if Terraform is installed
    $TerraformVersion = terraform version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'Terraform not found. Please install Terraform first.'
    }

    Write-Host "Terraform Version: $($TerraformVersion.Split("`n")[0])" -ForegroundColor Green

    # Check if variables file exists (except for init)
    if ($Action -ne 'init' -and !(Test-Path $VarFile)) {
        Write-Warning "Variables file '$VarFile' not found."
        Write-Host "Please create $VarFile based on terraform.tfvars.example" -ForegroundColor Yellow

        if (Test-Path 'terraform.tfvars.example') {
            Write-Host "`nExample variables file content:" -ForegroundColor Cyan
            Get-Content 'terraform.tfvars.example' | Write-Host -ForegroundColor Gray
        }

        throw "Variables file required for action: $Action"
    }

    switch ($Action) {
        'init' {
            Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
            $InitArgs = @('init')

            # Use backend config from parent directory if it exists
            $BackendConfig = Join-Path $PSScriptRoot '..' 'config' 'backend' 'sandbox.tfbackend'
            if (Test-Path $BackendConfig) {
                $InitArgs += "-backend-config=$BackendConfig"
                Write-Host "Using backend config: $BackendConfig" -ForegroundColor Gray
            }

            terraform @InitArgs
        }

        'plan' {
            Write-Host "`nCreating Terraform plan..." -ForegroundColor Yellow
            terraform plan -var-file="$VarFile" -out="tfplan"
        }

        'apply' {
            Write-Host "`nApplying Terraform configuration..." -ForegroundColor Yellow
            $ApplyArgs = @('apply')

            if ($AutoApprove) {
                $ApplyArgs += '-auto-approve'
            }

            # Use plan file if it exists, otherwise use var file
            if (Test-Path 'tfplan') {
                $ApplyArgs += 'tfplan'
                Write-Host 'Using saved plan file' -ForegroundColor Gray
            }
            else {
                $ApplyArgs += "-var-file=$VarFile"
            }

            terraform @ApplyArgs
        }

        'destroy' {
            Write-Host "`nDestroying Terraform resources..." -ForegroundColor Red
            $DestroyArgs = @('destroy', "-var-file=$VarFile")

            if ($AutoApprove) {
                $DestroyArgs += '-auto-approve'
            }

            terraform @DestroyArgs
        }
    }

    # Check Terraform exit code
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✓ Terraform $Action completed successfully!" -ForegroundColor Green

        # Show outputs for apply action
        if ($Action -eq 'apply') {
            Write-Host "`nTerraform Outputs:" -ForegroundColor Cyan
            terraform output
        }
    }
    else {
        throw "Terraform $Action failed with exit code: $LASTEXITCODE"
    }
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}
finally {
    # Return to original directory
    Pop-Location
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
switch ($Action) {
    'init' {
        Write-Host '1. Create terraform.tfvars with your configuration' -ForegroundColor White
        Write-Host '2. Run: ./Deploy-StoragePolicy.ps1 -Action plan' -ForegroundColor White
    }
    'plan' {
        Write-Host '1. Review the plan output above' -ForegroundColor White
        Write-Host '2. Run: ./Deploy-StoragePolicy.ps1 -Action apply' -ForegroundColor White
    }
    'apply' {
        Write-Host '1. Verify the policy in Azure Portal' -ForegroundColor White
        Write-Host '2. Test compliance with: pwsh ./scripts/Test-PolicyCompliance.ps1' -ForegroundColor White
        Write-Host '3. Create a test storage account to verify the policy works' -ForegroundColor White
    }
    'destroy' {
        Write-Host '1. Verify resources have been removed in Azure Portal' -ForegroundColor White
        Write-Host '2. Clean up any remaining terraform files if needed' -ForegroundColor White
    }
}
