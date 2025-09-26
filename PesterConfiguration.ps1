# Pester Configuration for Azure Policy Testing Project
# This configuration file helps the Pester Test extension discover and run tests

[CmdletBinding()]
param()

# Pester Configuration
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
        ExcludeTag  = @('Slow', 'Integration')
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

    # Coverage configuration (disabled for policy tests)
    CodeCoverage = @{
        Enabled = $false
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
