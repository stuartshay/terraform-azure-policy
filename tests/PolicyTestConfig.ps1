# Azure Policy Test Configuration
# This file contains configuration settings for policy testing

# Test Environment Settings
$script:TestConfig = @{
    # Target resource group for testing
    ResourceGroup = "rg-azure-policy-testing"

    # Policy configuration
    PolicyName = "deny-storage-account-public-access"
    PolicyDisplayName = "Deny Storage Account Public Access"

    # Test storage account settings
    StorageAccountPrefix = "testpolicysa"
    StorageAccountSku = "Standard_LRS"

    # Test timeouts and delays
    PolicyEvaluationWaitSeconds = 60
    ComplianceScanWaitSeconds = 30
    RemediationWaitSeconds = 30

    # Test behavior flags
    CleanupTestResources = $true
    SkipLongRunningTests = $false
    VerboseOutput = $true
}

# Export configuration for use in tests
$script:TestConfig
