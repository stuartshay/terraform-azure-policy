# PSScriptAnalyzer Settings for Azure Policy Testing Project
# This file configures code analysis and formatting rules for PowerShell scripts

@{
    # Include all default rules
    IncludeDefaultRules = $true

    # Severity levels to include in analysis
    Severity            = @(
        'Error',
        'Warning',
        'Information'
    )

    # Rules to exclude (customize based on project needs)
    ExcludeRules        = @(
        'PSAvoidUsingWriteHost',      # We use Write-Host for colored console output
        'PSUseShouldProcessForStateChangingFunctions'  # Some utility functions don't need ShouldProcess
    )

    # Rules to include (in addition to default rules)
    IncludeRules        = @(
        'PSUseCompatibleCmdlets',
        'PSUseCompatibleSyntax',
        'PSUseCompatibleTypes'
    )

    # Custom rule configurations
    Rules               = @{
        # Cmdlet compatibility settings
        PSUseCompatibleCmdlets                         = @{
            Compatibility = @(
                'desktop-5.1.14393.206-windows',
                'core-6.1.0-windows',
                'core-6.1.0-linux',
                'core-6.1.0-macos'
            )
        }

        # Syntax compatibility
        PSUseCompatibleSyntax                          = @{
            Enable         = $true
            TargetVersions = @(
                '5.1',
                '6.2',
                '7.0',
                '7.1',
                '7.2'
            )
        }

        # Type compatibility
        PSUseCompatibleTypes                           = @{
            Enable         = $true
            TargetVersions = @(
                '5.1',
                '6.2',
                '7.0',
                '7.1',
                '7.2'
            )
        }

        # Enforce consistent indentation
        PSUseConsistentIndentation                     = @{
            Enable              = $true
            IndentationSize     = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }

        # Enforce consistent whitespace
        PSUseConsistentWhitespace                      = @{
            Enable                          = $true
            CheckInnerBrace                 = $true
            CheckOpenBrace                  = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $true
            CheckPipe                       = $true
            CheckPipeForRedundantWhitespace = $false
            CheckSeparator                  = $true
            CheckParameter                  = $false
        }

        # Enforce proper case for cmdlets and parameters
        PSUseCorrectCasing                             = @{
            Enable = $true
        }

        # Enforce UTF-8 encoding with BOM for PS 5.1 compatibility
        PSAvoidUsingPlainTextForPassword               = @{
            Enable = $true
        }

        # Ensure proper error handling
        PSAvoidUsingCmdletAliases                      = @{
            Enable    = $true
            Whitelist = @()
        }

        # Avoid using positional parameters
        PSAvoidUsingPositionalParameters               = @{
            Enable           = $true
            CommandAllowList = @()
        }

        # Prefer splatting for multiple parameters
        PSReviewUnusedParameter                        = @{
            Enable = $true
        }

        # Security-related rules
        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Enable = $true
        }

        PSAvoidUsingUsernameAndPasswordParams          = @{
            Enable = $true
        }

        PSAvoidUsingInvokeExpression                   = @{
            Enable = $true
        }

        # Performance-related rules
        PSUseDeclaredVarsMoreThanAssignments           = @{
            Enable = $true
        }

        # Best practices
        PSProvideCommentHelp                           = @{
            Enable                  = $true
            ExportedOnly            = $false
            BlockComment            = $true
            VSCodeSnippetCorrection = $true
            Placement               = 'before'
        }

        PSUseApprovedVerbs                             = @{
            Enable = $true
        }

        PSUseSingularNouns                             = @{
            Enable = $true
        }

        PSReservedCmdletChar                           = @{
            Enable = $true
        }

        PSReservedParams                               = @{
            Enable = $true
        }

        # Azure-specific best practices
        PSUseBOMForUnicodeEncodedFile                  = @{
            Enable = $true
        }
    }

    # Custom settings for this project
    CustomRulePath      = @()

    # Output format settings
    OutputFormat        = 'NUnitXml'

    # Recurse into subdirectories
    Recurse             = $true

    # Suppress specific warnings (file-specific)
    SuppressedOnly      = $false
}
