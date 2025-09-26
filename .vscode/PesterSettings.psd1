# Pester Settings for VS Code Extension
# This file is automatically detected by the Pester Test extension

@{
    # Test Discovery Settings
    IncludeVSCodeMarker = $true

    # Test File Patterns
    TestNamePattern     = '*.Tests.ps1'

    # Paths to include in test discovery
    TestPaths           = @(
        'tests\storage\*.Tests.ps1'
        'tests\network\*.Tests.ps1'
    )

    # Paths to exclude from test discovery
    ExcludePaths        = @(
        'tests\PolicyTestConfig.ps1'
        'reports\*'
        'config\*'
        '.terraform\*'
    )

    # Additional Pester arguments
    AdditionalArguments = @(
        '-CI'
    )

    # Enable code lens for individual tests
    EnableCodeLens      = $true

    # Auto-refresh tests when files change
    AutoDiscoverTests   = $true

    # Output settings
    OutputVerbosity     = 'Detailed'

    # Test execution settings
    MaxParallelJobs     = 1  # Policy tests should run sequentially to avoid conflicts

    # Tags to run by default (empty means all)
    DefaultTags         = @()

    # Tags to exclude by default
    ExcludeTags         = @('Slow', 'Manual', 'RequiresCleanup')
}
