# Azure Policy Testing Project - PowerShell Module Requirements
# This file defines the required PowerShell modules for the project

@{
    # Required PowerShell modules for Azure policy development and testing
    RequiredModules              = @(
        @{
            ModuleName    = 'Az.Accounts'
            ModuleVersion = '2.12.1'
            Description   = 'Azure authentication and account management'
        },

        @{
            ModuleName    = 'Az.Resources'
            ModuleVersion = '6.6.0'
            Description   = 'Azure resource management including policy definitions'
        },
        @{
            ModuleName    = 'Az.PolicyInsights'
            ModuleVersion = '1.6.1'
            Description   = 'Azure policy compliance and insights'
        },
        @{
            ModuleName    = 'Az.Storage'
            ModuleVersion = '6.0.0'
            Description   = 'Azure storage account management (required for integration tests)'
        },
        @{
            ModuleName    = 'PSScriptAnalyzer'
            ModuleVersion = '1.21.0'
            Description   = 'PowerShell code analysis and linting'
        },
        @{
            ModuleName    = 'Pester'
            ModuleVersion = '5.4.0'
            Description   = 'PowerShell testing framework'
        },
        @{
            ModuleName    = 'PowerShellGet'
            ModuleVersion = '2.2.5'
            Description   = 'PowerShell module management'
        },
        @{
            ModuleName    = 'PackageManagement'
            ModuleVersion = '1.4.8.1'
            Description   = 'Package management for PowerShell'
        }
    )

    # Optional modules that enhance functionality
    OptionalModules              = @(
        @{
            ModuleName    = 'Az.ResourceGraph'
            ModuleVersion = '0.13.0'
            Description   = 'Azure Resource Graph queries for advanced policy analysis'
        },
        @{
            ModuleName    = 'ImportExcel'
            ModuleVersion = '7.8.4'
            Description   = 'Excel import/export for policy compliance reports'
        },
        @{
            ModuleName    = 'PSWriteColor'
            ModuleVersion = '1.0.1'
            Description   = 'Enhanced console output with colors'
        }
    )

    # PowerShell version requirements
    PowerShellVersion            = '5.1'

    # Compatibility information
    CompatiblePSEditions         = @('Desktop', 'Core')

    # Module metadata
    ModuleVersion                = '1.0.0'
    Description                  = 'Azure Policy Testing Project Requirements'
    Author                       = 'Azure Policy Testing Team'
    CompanyName                  = 'Organization'
    Copyright                    = '© 2025 Organization. All rights reserved.'

    # Installation preferences
    InstallationPolicy           = 'Trusted'
    Repository                   = 'PSGallery'
    Scope                        = 'CurrentUser'

    # Environment variables that should be set
    RequiredEnvironmentVariables = @(
        'ARM_SUBSCRIPTION_ID',
        'ARM_MANAGEMENT_GROUP_ID'
    )

    # Recommended VS Code extensions
    RecommendedExtensions        = @(
        'ms-vscode.powershell',
        'hashicorp.terraform',
        'ms-vscode.azure-account',
        'ms-azuretools.vscode-azureresourcegroups',
        'redhat.vscode-yaml',
        'ms-vscode.vscode-json'
    )
}
