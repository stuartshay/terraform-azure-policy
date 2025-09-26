# Azure Policy Testing Utilities
# Collection of utility functions for Azure policy development and testing

<#
.SYNOPSIS
    Validate Azure policy definition JSON files
.DESCRIPTION
    This script validates policy definition JSON files for syntax and structure
.PARAMETER PolicyPath
    Path to the policy definition file or directory containing policy files
.EXAMPLE
    ./Validate-PolicyDefinitions.ps1 -PolicyPath "./policies"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$PolicyPath = './policies'
)

function Test-PolicyDefinitionSyntax {
    <#
    .SYNOPSIS
    Test the syntax of a policy definition JSON file
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        $Content = Get-Content $FilePath -Raw
        $PolicyDefinition = $Content | ConvertFrom-Json

        # Basic validation
        $RequiredProperties = @('name', 'properties')
        $PolicyProperties = @('displayName', 'description', 'policyType', 'mode', 'policyRule')

        foreach ($Property in $RequiredProperties) {
            if (-not $PolicyDefinition.PSObject.Properties[$Property]) {
                throw "Missing required property: $Property"
            }
        }

        foreach ($Property in $PolicyProperties) {
            if (-not $PolicyDefinition.properties.PSObject.Properties[$Property]) {
                throw "Missing required policy property: $Property"
            }
        }

        # Validate policy rule structure
        if (-not $PolicyDefinition.properties.policyRule.if -or -not $PolicyDefinition.properties.policyRule.then) {
            throw "Policy rule must contain 'if' and 'then' clauses"
        }

        return @{
            IsValid = $true
            Message = 'Policy definition is valid'
        }
    }
    catch {
        return @{
            IsValid = $false
            Message = $_.Exception.Message
        }
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
        return Get-ChildItem -Path $Path -Filter '*.json' -Recurse | ForEach-Object { $_.FullName }
    }
    else {
        throw "Path not found: $Path"
    }
}

# Main execution
try {
    Write-Host 'Validating Azure Policy Definitions...' -ForegroundColor Cyan
    Write-Host "Path: $PolicyPath" -ForegroundColor White

    $PolicyFiles = Get-PolicyFiles -Path $PolicyPath

    if ($PolicyFiles.Count -eq 0) {
        Write-Warning "No policy definition files found in: $PolicyPath"
        exit 0
    }

    $ValidationResults = @()

    foreach ($File in $PolicyFiles) {
        Write-Host "`nValidating: $File" -ForegroundColor Yellow

        $Result = Test-PolicyDefinitionSyntax -FilePath $File
        $ValidationResults += [PSCustomObject]@{
            File    = $File
            IsValid = $Result.IsValid
            Message = $Result.Message
        }

        if ($Result.IsValid) {
            Write-Host '  ✓ Valid' -ForegroundColor Green
        }
        else {
            Write-Host "  ✗ Invalid: $($Result.Message)" -ForegroundColor Red
        }
    }

    # Summary
    $ValidCount = ($ValidationResults | Where-Object { $_.IsValid }).Count
    $InvalidCount = ($ValidationResults | Where-Object { -not $_.IsValid }).Count

    Write-Host "`n=== Validation Summary ===" -ForegroundColor Cyan
    Write-Host "Total Files: $($PolicyFiles.Count)" -ForegroundColor White
    Write-Host "Valid: $ValidCount" -ForegroundColor Green
    Write-Host "Invalid: $InvalidCount" -ForegroundColor Red

    if ($InvalidCount -gt 0) {
        Write-Host "`nInvalid Files:" -ForegroundColor Red
        $ValidationResults | Where-Object { -not $_.IsValid } | ForEach-Object {
            Write-Host "  - $($_.File): $($_.Message)" -ForegroundColor Red
        }
        exit 1
    }
    else {
        Write-Host "`nAll policy definitions are valid! ✓" -ForegroundColor Green
        exit 0
    }
}
catch {
    Write-Error "Validation failed: $($_.Exception.Message)"
    exit 1
}
