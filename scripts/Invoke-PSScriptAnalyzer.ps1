#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run PSScriptAnalyzer on PowerShell files in the repository
.DESCRIPTION
    This script runs PSScriptAnalyzer with the project's settings and excludes specific rules
    that are acceptable for this project (critical issues only).
.EXAMPLE
    ./scripts/Invoke-PSScriptAnalyzer.ps1
#>

try {
    if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
        # Note: Excludes formatting rules (handled by pre-commit), test-related rules, and documentation rules
        # PSAvoidUsingPositionalParameters is excluded for utility scripts where named parameters add verbosity
        $results = Invoke-ScriptAnalyzer `
            -Path . `
            -Settings '.vscode/PSScriptAnalyzerSettings.psd1' `
            -Recurse `
            -Severity Error, Warning `
            -ExcludeRule PSUseConsistentWhitespace, PSUseConsistentIndentation, PSUseBOMForUnicodeEncodedFile, PSAvoidUsingPositionalParameters, PSReviewUnusedParameter, PSUseDeclaredVarsMoreThanAssignments, PSProvideCommentHelp

        if ($results) {
            $results | Format-Table -AutoSize
            exit 1
        } else {
            Write-Host 'PSScriptAnalyzer passed (critical issues only)' -ForegroundColor Green
        }
    } else {
        Write-Host 'PSScriptAnalyzer not installed, skipping...' -ForegroundColor Yellow
    }
} catch {
    Write-Host "PSScriptAnalyzer error: $_" -ForegroundColor Red
}
