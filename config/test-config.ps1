# Azure Policy Test Configuration
# This file contains centralized configuration settings for all policy functional tests

<#
.SYNOPSIS
    Centralized configuration for Azure Policy functional tests
.DESCRIPTION
    This configuration file provides a single source of truth for all test settings,
    including Azure environment settings, timeouts, and test behavior flags.
.NOTES
    This file should be dot-sourced by all test files to ensure consistent configuration.
#>

# Azure Environment Configuration
$script:TestConfig = @{
    # Azure Environment Settings
    Azure    = @{
        # Target resource group for all policy testing
        ResourceGroupName           = 'rg-azure-policy-testing'

        # Default location for test resources (will be overridden by resource group location)
        DefaultLocation             = 'East US'

        # Subscription validation settings
        RequireValidSubscription    = $true
        ValidateResourceGroupExists = $true
    }

    # Test Timing Configuration
    Timeouts = @{
        # How long to wait for Azure Policy evaluation (seconds)
        PolicyEvaluationWaitSeconds      = 60

        # How long to wait for compliance scan completion (seconds)
        ComplianceScanWaitSeconds        = 30

        # How long to wait after remediation actions (seconds)
        RemediationWaitSeconds           = 30

        # Extended wait time for complex policy evaluations (seconds)
        ExtendedEvaluationWaitSeconds    = 120

        # Wait time for Function App deployments (seconds)
        FunctionAppDeploymentWaitSeconds = 180

        # Wait time for re-evaluation after configuration changes (seconds)
        ReEvaluationWaitSeconds          = 45
    }

    # Test Behavior Configuration
    Behavior = @{
        # Whether to clean up test resources after completion
        CleanupTestResources              = $true

        # Whether to skip long-running tests (useful for quick validation)
        SkipLongRunningTests              = $false

        # Whether to output verbose information during tests
        VerboseOutput                     = $true

        # Whether to continue tests if resource creation fails
        ContinueOnResourceCreationFailure = $true

        # Whether to attempt automatic remediation testing
        EnableRemediationTests            = $true

        # Whether to run performance and scale tests
        RunPerformanceTests               = $false
    }

    # Resource Naming Configuration
    Naming   = @{
        # Timestamp format for unique resource names
        TimestampFormat       = 'yyyyMMddHHmmss'

        # Maximum length for Azure resource names
        MaxResourceNameLength = 24

        # Prefix for all test resources to identify them easily
        TestResourcePrefix    = 'testpolicy'
    }

    # Azure PowerShell Module Configuration
    Modules  = @{
        # Required modules for all tests
        Required    = @(
            'Az.Accounts',
            'Az.Resources',
            'Az.PolicyInsights'
        )

        # Policy-specific modules (loaded as needed)
        Storage     = @('Az.Storage')
        FunctionApp = @('Az.Functions', 'Az.Websites')
        Network     = @('Az.Network')

        # Force reload modules (useful for development)
        ForceReload = $true
    }

    # Test Organization
    Tags     = @{
        # Default test tags for categorization
        Unit             = @('Unit', 'Fast', 'PolicyDefinition')
        Integration      = @('Integration', 'Slow', 'Compliance', 'RequiresCleanup')
        PolicyLogic      = @('Unit', 'Fast', 'PolicyLogic')
        PolicyAssignment = @('Integration', 'Fast', 'PolicyAssignment')
        Remediation      = @('Integration', 'Slow', 'Remediation', 'RequiresCleanup')
        Performance      = @('Performance', 'Scale', 'Optional')
    }
}

<#
.SYNOPSIS
    Gets the centralized test configuration
.DESCRIPTION
    Returns the complete test configuration object for use in test files
.OUTPUTS
    Hashtable containing all test configuration settings
#>
function Get-PolicyTestConfig {
    return $script:TestConfig
}

<#
.SYNOPSIS
    Validates the test environment and Azure context
.DESCRIPTION
    Performs validation checks for Azure context, subscription, and resource group
.PARAMETER Config
    The test configuration object (optional, uses default if not provided)
.OUTPUTS
    Hashtable containing validation results and Azure context information
#>
function Initialize-PolicyTestEnvironment {
    param(
        [hashtable]$Config = $script:TestConfig
    )

    $result = @{
        Success        = $true
        Context        = $null
        SubscriptionId = $null
        ResourceGroup  = $null
        Errors         = @()
    }

    try {
        # Validate Azure context
        $result.Context = Get-AzContext
        if (-not $result.Context) {
            $result.Success = $false
            $result.Errors += 'No Azure context found. Please run Connect-AzAccount first.'
            return $result
        }

        $result.SubscriptionId = $result.Context.Subscription.Id
        Write-Host "Running tests in subscription: $($result.Context.Subscription.Name) ($($result.SubscriptionId))" -ForegroundColor Green

        # Validate resource group if required
        if ($Config.Azure.ValidateResourceGroupExists) {
            $result.ResourceGroup = Get-AzResourceGroup -Name $Config.Azure.ResourceGroupName -ErrorAction SilentlyContinue
            if (-not $result.ResourceGroup) {
                $result.Success = $false
                $result.Errors += "Resource group '$($Config.Azure.ResourceGroupName)' not found. Please create it first."
                return $result
            }
        }

        return $result
    }
    catch {
        $result.Success = $false
        $result.Errors += "Failed to initialize test environment: $($_.Exception.Message)"
        return $result
    }
}

<#
.SYNOPSIS
    Imports required Azure PowerShell modules
.DESCRIPTION
    Imports the required modules for policy testing with optional force reload
.PARAMETER ModuleType
    The type of modules to load ('Required', 'Storage', 'FunctionApp', 'Network')
.PARAMETER Config
    The test configuration object (optional, uses default if not provided)
#>
function Import-PolicyTestModule {
    param(
        [string[]]$ModuleTypes = @('Required'),
        [hashtable]$Config = $script:TestConfig
    )

    $allModules = @()

    foreach ($moduleType in $ModuleTypes) {
        if ($Config.Modules.ContainsKey($moduleType)) {
            $allModules += $Config.Modules[$moduleType]
        }
    }

    foreach ($module in $allModules) {
        try {
            if ($Config.Modules.ForceReload) {
                Import-Module $module -Force
            }
            else {
                Import-Module $module
            }
            Write-Verbose "Imported module: $module"
        }
        catch {
            Write-Warning "Failed to import module $module`: $($_.Exception.Message)"
        }
    }
}

<#
.SYNOPSIS
    Generates a unique resource name with proper validation
.DESCRIPTION
    Creates a unique resource name using the configured prefix, timestamp, and suffix
.PARAMETER BaseName
    The base name for the resource
.PARAMETER Suffix
    Optional suffix to append to the name
.PARAMETER MaxLength
    Maximum length for the resource name (uses config default if not specified)
.OUTPUTS
    String containing the generated unique resource name
#>
function New-UniqueResourceName {
    param(
        [Parameter(Mandatory)]
        [string]$BaseName,

        [string]$Suffix = '',

        [int]$MaxLength = $script:TestConfig.Naming.MaxResourceNameLength
    )

    $timestamp = Get-Date -Format $script:TestConfig.Naming.TimestampFormat
    $prefix = $script:TestConfig.Naming.TestResourcePrefix

    # Build name ensuring suffix is preserved by calculating available space
    $reservedLength = $prefix.Length + $Suffix.Length
    $availableForBaseAndTime = $MaxLength - $reservedLength

    # Combine base and timestamp
    $baseAndTime = "$BaseName$timestamp"

    # If too long, truncate the base+timestamp part, not the suffix
    if ($baseAndTime.Length -gt $availableForBaseAndTime) {
        # Prioritize keeping more timestamp chars (at least last 8 chars for uniqueness)
        $minTimestampChars = 8
        if ($timestamp.Length -gt $minTimestampChars) {
            $keepTimestamp = $minTimestampChars
        }
        else {
            $keepTimestamp = $timestamp.Length
        }

        $availableForBase = $availableForBaseAndTime - $keepTimestamp
        if ($availableForBase -gt 0) {
            $trimmedBase = $BaseName.Substring(0, [Math]::Min($BaseName.Length, $availableForBase))
            $trimmedTimestamp = $timestamp.Substring($timestamp.Length - $keepTimestamp, $keepTimestamp)
            $baseAndTime = "$trimmedBase$trimmedTimestamp"
        }
        else {
            $baseAndTime = $timestamp.Substring($timestamp.Length - $availableForBaseAndTime, $availableForBaseAndTime)
        }
    }

    $fullName = "$prefix$baseAndTime$Suffix"

    # Ensure name is lowercase
    $fullName = $fullName.ToLower()

    return $fullName
}

# Configuration is available as a script variable for internal use
