# Configuration Loader Module for Azure Policy Tests
# This module provides helper functions to load and work with test configurations

<#
.SYNOPSIS
    Configuration loader module for Azure Policy functional tests
.DESCRIPTION
    This module provides functions to load the centralized test configuration,
    policy-specific settings, and environment configurations.
.NOTES
    This module should be imported by test files that need access to centralized configuration.
#>

# Import the main test configuration
. "$PSScriptRoot\test-config.ps1"

<#
.SYNOPSIS
    Loads policy-specific configuration from the policies.json file
.DESCRIPTION
    Reads and parses the policies.json configuration file
.OUTPUTS
    PSCustomObject containing the policy configuration
#>
function Get-PolicyConfiguration {
    $configPath = Join-Path $PSScriptRoot 'policies.json'

    if (-not (Test-Path $configPath)) {
        throw "Policy configuration file not found at: $configPath"
    }

    try {
        $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
        return $configContent
    }
    catch {
        throw "Failed to parse policy configuration: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Gets configuration for a specific policy
.DESCRIPTION
    Returns the configuration settings for a specific policy by category and name
.PARAMETER PolicyCategory
    The policy category (e.g., 'storage', 'function-app', 'network')
.PARAMETER PolicyName
    The specific policy name within the category
.OUTPUTS
    PSCustomObject containing the policy-specific configuration
.EXAMPLE
    Get-PolicyConfig -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access'
#>
function Get-PolicyConfig {
    param(
        [Parameter(Mandatory)]
        [string]$PolicyCategory,

        [Parameter(Mandatory)]
        [string]$PolicyName
    )

    $policyConfig = Get-PolicyConfiguration

    if (-not $policyConfig.policies.$PolicyCategory) {
        throw "Policy category '$PolicyCategory' not found in configuration"
    }

    if (-not $policyConfig.policies.$PolicyCategory.$PolicyName) {
        throw "Policy '$PolicyName' not found in category '$PolicyCategory'"
    }

    return $policyConfig.policies.$PolicyCategory.$PolicyName
}

<#
.SYNOPSIS
    Gets environment-specific configuration
.DESCRIPTION
    Returns configuration settings for a specific environment (dev, staging, prod)
.PARAMETER Environment
    The environment name ('dev', 'staging', 'prod')
.OUTPUTS
    PSCustomObject containing environment-specific configuration
.EXAMPLE
    Get-EnvironmentConfig -Environment 'dev'
#>
function Get-EnvironmentConfig {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('dev', 'staging', 'prod')]
        [string]$Environment
    )

    $policyConfig = Get-PolicyConfiguration

    if (-not $policyConfig.environments.$Environment) {
        throw "Environment '$Environment' not found in configuration"
    }

    return $policyConfig.environments.$Environment
}

<#
.SYNOPSIS
    Initializes a complete test configuration for a specific policy
.DESCRIPTION
    Combines the general test configuration with policy-specific settings
.PARAMETER PolicyCategory
    The policy category (e.g., 'storage', 'function-app', 'network')
.PARAMETER PolicyName
    The specific policy name within the category
.PARAMETER Environment
    The target environment (optional, defaults to 'prod')
.OUTPUTS
    Hashtable containing the complete test configuration
.EXAMPLE
    Initialize-PolicyTestConfig -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access'
#>
function Initialize-PolicyTestConfig {
    param(
        [Parameter(Mandatory)]
        [string]$PolicyCategory,

        [Parameter(Mandatory)]
        [string]$PolicyName,

        [ValidateSet('dev', 'staging', 'prod')]
        [string]$Environment = 'prod'
    )

    # Get base test configuration
    $baseConfig = Get-PolicyTestConfig

    # Get policy-specific configuration
    $policyConfig = Get-PolicyConfig -PolicyCategory $PolicyCategory -PolicyName $PolicyName

    # Get environment configuration
    $envConfig = Get-EnvironmentConfig -Environment $Environment

    # Merge configurations
    $mergedConfig = $baseConfig.Clone()

    # Override Azure settings with environment-specific values
    if ($envConfig.resourceGroupName) {
        $mergedConfig.Azure.ResourceGroupName = $envConfig.resourceGroupName
    }
    if ($envConfig.location) {
        $mergedConfig.Azure.DefaultLocation = $envConfig.location
    }
    if ($envConfig.subscriptionId) {
        $mergedConfig.Azure.SubscriptionId = $envConfig.subscriptionId
    }

    # Add policy-specific settings
    $mergedConfig.Policy = @{
        Name           = $policyConfig.name
        DisplayName    = $policyConfig.displayName
        Category       = $policyConfig.category
        PolicyPath     = $policyConfig.policyPath
        ResourcePrefix = $policyConfig.resourcePrefix
        TestConfig     = $policyConfig.testConfig
    }

    return $mergedConfig
}

<#
.SYNOPSIS
    Generates unique resource names for policy tests
.DESCRIPTION
    Creates unique resource names using policy-specific prefixes and test configuration
.PARAMETER PolicyCategory
    The policy category
.PARAMETER PolicyName
    The specific policy name
.PARAMETER ResourceType
    The type of resource ('compliant', 'nonCompliant', 'exempted')
.PARAMETER Environment
    The target environment (optional, defaults to 'prod')
.OUTPUTS
    String containing the unique resource name
.EXAMPLE
    New-PolicyTestResourceName -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access' -ResourceType 'compliant'
#>
function New-PolicyTestResourceName {
    param(
        [Parameter(Mandatory)]
        [string]$PolicyCategory,

        [Parameter(Mandatory)]
        [string]$PolicyName,

        [Parameter(Mandatory)]
        [ValidateSet('compliant', 'nonCompliant', 'exempted')]
        [string]$ResourceType,

        [ValidateSet('dev', 'staging', 'prod')]
        [string]$Environment = 'prod'
    )

    $config = Initialize-PolicyTestConfig -PolicyCategory $PolicyCategory -PolicyName $PolicyName -Environment $Environment
    $policyConfig = $config.Policy

    # Determine suffix based on resource type
    $suffix = switch ($ResourceType) {
        'compliant' { $policyConfig.TestConfig.compliantSuffix }
        'nonCompliant' { $policyConfig.TestConfig.nonCompliantSuffix }
        'exempted' { $policyConfig.TestConfig.exemptedSuffix }
    }

    # Generate unique name using the base function
    return New-UniqueResourceName -BaseName $policyConfig.ResourcePrefix -Suffix $suffix
}

<#
.SYNOPSIS
    Gets the full path to a policy definition file
.DESCRIPTION
    Resolves the relative policy path to an absolute path from the test script location
.PARAMETER PolicyCategory
    The policy category
.PARAMETER PolicyName
    The specific policy name
.PARAMETER TestScriptPath
    The path of the calling test script (use $PSScriptRoot)
.OUTPUTS
    String containing the absolute path to the policy definition file
.EXAMPLE
    Get-PolicyDefinitionPath -PolicyCategory 'storage' -PolicyName 'deny-storage-account-public-access' -TestScriptPath $PSScriptRoot
#>
function Get-PolicyDefinitionPath {
    param(
        [Parameter(Mandatory)]
        [string]$PolicyCategory,

        [Parameter(Mandatory)]
        [string]$PolicyName,

        [Parameter(Mandatory)]
        [string]$TestScriptPath
    )

    $policyConfig = Get-PolicyConfig -PolicyCategory $PolicyCategory -PolicyName $PolicyName

    # Build the full path relative to the test script location
    $policyPath = Join-Path $TestScriptPath '..\..\' $policyConfig.policyPath

    # Resolve the path to handle relative components
    return Resolve-Path $policyPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
}

<#
.SYNOPSIS
    Validates that all required configuration files exist
.DESCRIPTION
    Checks that the test configuration and policy configuration files are present and valid
.OUTPUTS
    Boolean indicating whether all configurations are valid
#>
function Test-ConfigurationFile {
    $errors = @()

    # Check main test configuration
    try {
        $testConfig = Get-PolicyTestConfig
        if (-not $testConfig) {
            $errors += 'Test configuration is empty or invalid'
        }
    }
    catch {
        $errors += "Failed to load test configuration: $($_.Exception.Message)"
    }

    # Check policy configuration
    try {
        $policyConfig = Get-PolicyConfiguration
        if (-not $policyConfig) {
            $errors += 'Policy configuration is empty or invalid'
        }

        # Validate structure
        if (-not $policyConfig.policies) {
            $errors += "Policy configuration missing 'policies' section"
        }
        if (-not $policyConfig.environments) {
            $errors += "Policy configuration missing 'environments' section"
        }
    }
    catch {
        $errors += "Failed to load policy configuration: $($_.Exception.Message)"
    }

    if ($errors.Count -gt 0) {
        Write-Warning 'Configuration validation errors:'
        foreach ($errorMsg in $errors) {
            Write-Warning "  - $errorMsg"
        }
        return $false
    }

    return $true
}

# Functions are now available in the global scope when this file is dot-sourced
