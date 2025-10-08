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
        'PSUseShouldProcessForStateChangingFunctions',  # Some utility functions don't need ShouldProcess
        'PSAvoidUsingConvertToSecureStringWithPlainText'  # CI/CD scripts use environment variables for service principal auth
    )

    # Custom rule configurations
    Rules               = @{
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

        # Security-related rules
        PSAvoidUsingPlainTextForPassword               = @{
            Enable = $true
        }

        PSAvoidUsingCmdletAliases                      = @{
            Enable    = $true
            Whitelist = @()
        }

        PSAvoidUsingPositionalParameters               = @{
            Enable           = $true
            CommandAllowList = @()
        }

        PSReviewUnusedParameter                        = @{
            Enable = $true
        }

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
}
