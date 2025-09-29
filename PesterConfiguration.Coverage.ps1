# Pester Configuration with Code Coverage Enabled
# Enhanced configuration for Azure Policy Testing Project with coverage analysis

[CmdletBinding()]
param()

# Pester Configuration with Coverage
$PesterPreference = [PesterConfiguration]@{
    # Run configuration
    Run          = @{
        Path        = @(
            "$PSScriptRoot/tests"
        )
        ExcludePath = @(
            "$PSScriptRoot/tests/PolicyTestConfig.ps1"
        )
        PassThru    = $true
        SkipRun     = $false
    }

    # Filter configuration
    Filter       = @{
        Tag         = @()
        ExcludeTag  = @('Slow', 'Integration') # pragma: allowlist secret
        Line        = @()
        ExcludeLine = @()
        FullName    = @()
    }

    # Output configuration
    Output       = @{
        Verbosity           = 'Detailed'
        StackTraceVerbosity = 'Filtered'
        CIFormat            = 'Auto'
    }

    # Test result configuration
    TestResult   = @{
        Enabled        = $true
        OutputFormat   = 'JUnitXml'
        OutputPath     = "$PSScriptRoot/reports/TestResults.xml"
        OutputEncoding = 'UTF8'
        TestSuiteName  = 'Azure Policy Tests'
    }

    # Code Coverage configuration (ENABLED for PowerShell scripts)
    CodeCoverage = @{
        Enabled               = $true
        OutputFormat          = 'JaCoCo'
        OutputPath            = "$PSScriptRoot/reports/coverage.xml"
        OutputEncoding        = 'UTF8'
        Path                  = @(
            "$PSScriptRoot/scripts/*.ps1"
            "$PSScriptRoot/PowerShell/*.ps1"
        )
        ExcludeTests          = $true
        RecursePaths          = $true
        CoveragePercentTarget = 80.0
        UseBreakpoints        = $false
        SingleHitBreakpoints  = $false
    }

    # Should configuration
    Should       = @{
        ErrorAction = 'Stop'
    }

    # Debug configuration
    Debug        = @{
        ShowFullErrors         = $false
        WriteDebugMessages     = $false
        WriteDebugMessagesFrom = @()
        ShowNavigationMarkers  = $false
        ReturnRawResultObject  = $false
    }
}

# Export the configuration
$PesterPreference
