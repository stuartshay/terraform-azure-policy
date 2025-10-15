#Requires -Modules Pester

<#
.SYNOPSIS
    Quick unit tests for Deny Storage SAS Expiration policy (no Azure resources required)
.DESCRIPTION
    This test suite validates the Azure Policy JSON definition for SAS expiration
    limits without requiring Azure authentication or resource creation.
.NOTES
    Prerequisites:
    - Pester module only
    - No Azure authentication required
    - No Azure resources created
#>

BeforeAll {
    # Import centralized configuration
    . "$PSScriptRoot\..\..\config\config-loader.ps1"

    # Initialize test configuration for this specific policy
    $script:TestConfig = Initialize-PolicyTestConfig -PolicyCategory 'storage' -PolicyName 'deny-storage-sas-expiration'

    # Set script variables from configuration
    $script:PolicyPath = Get-PolicyDefinitionPath -PolicyCategory 'storage' -PolicyName 'deny-storage-sas-expiration' -TestScriptPath $PSScriptRoot
    $script:ExpectedPolicyName = 'deny-storage-sas-expiration'
    $script:ExpectedDisplayName = 'Deny Storage Account SAS Token Expiration Greater Than Maximum'
}

Describe 'Policy JSON Validation' -Tag @('Unit', 'Fast', 'Static') {

    Context 'File Structure' {
        It 'Should have policy definition file' {
            Test-Path $script:PolicyPath | Should -Be $true
        }

        It 'Should be valid JSON' {
            { Get-Content $script:PolicyPath -Raw | ConvertFrom-Json } | Should -Not -Throw
        }
    }

    Context 'Policy Content Validation' {
        BeforeAll {
            $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        }

        It 'Should have properties section' {
            $script:PolicyJson.properties | Should -Not -BeNullOrEmpty
        }

        It 'Should have display name' {
            $script:PolicyJson.properties.displayName | Should -Be $script:ExpectedDisplayName
        }

        It 'Should have description' {
            $script:PolicyJson.properties.description | Should -Not -BeNullOrEmpty
            $script:PolicyJson.properties.description.Length | Should -BeGreaterThan 10
            $script:PolicyJson.properties.description | Should -Match 'SAS|Shared Access Signature'
        }

        It 'Should have mode set to Indexed' {
            $script:PolicyJson.properties.mode | Should -Be 'Indexed'
        }

        It 'Should have policy rule' {
            $script:PolicyJson.properties.policyRule | Should -Not -BeNullOrEmpty
        }

        It 'Should have metadata section' {
            $script:PolicyJson.properties.metadata | Should -Not -BeNullOrEmpty
        }

        It 'Should have policy name' {
            $script:PolicyJson.name | Should -Be $script:ExpectedPolicyName
        }
    }

    Context 'Policy Parameters Validation' {
        BeforeAll {
            $script:Parameters = (Get-Content $script:PolicyPath -Raw | ConvertFrom-Json).properties.parameters
        }

        It 'Should have effect parameter' {
            $script:Parameters.effect | Should -Not -BeNullOrEmpty
        }

        It 'Should have maxSasExpirationDays parameter' {
            $script:Parameters.maxSasExpirationDays | Should -Not -BeNullOrEmpty
        }

        It 'Should have exemptedStorageAccounts parameter' {
            $script:Parameters.exemptedStorageAccounts | Should -Not -BeNullOrEmpty
        }

        It 'Effect parameter should have correct allowed values' {
            $script:Parameters.effect.allowedValues | Should -Contain 'Audit'
            $script:Parameters.effect.allowedValues | Should -Contain 'Deny'
            $script:Parameters.effect.allowedValues | Should -Contain 'Disabled'
        }

        It 'Effect parameter should default to Deny' {
            $script:Parameters.effect.defaultValue | Should -Be 'Deny'
        }

        It 'MaxSasExpirationDays parameter should have valid allowed values' {
            $script:Parameters.maxSasExpirationDays.allowedValues | Should -Contain 7
            $script:Parameters.maxSasExpirationDays.allowedValues | Should -Contain 14
            $script:Parameters.maxSasExpirationDays.allowedValues | Should -Contain 30
            $script:Parameters.maxSasExpirationDays.allowedValues | Should -Contain 60
            $script:Parameters.maxSasExpirationDays.allowedValues | Should -Contain 90
            $script:Parameters.maxSasExpirationDays.allowedValues | Should -Contain 180
            $script:Parameters.maxSasExpirationDays.allowedValues | Should -Contain 365
        }

        It 'MaxSasExpirationDays parameter should default to 90 days' {
            $script:Parameters.maxSasExpirationDays.defaultValue | Should -Be 90
        }

        It 'MaxSasExpirationDays parameter should be Integer type' {
            $script:Parameters.maxSasExpirationDays.type | Should -Be 'Integer'
        }

        It 'ExemptedStorageAccounts parameter should be Array type' {
            $script:Parameters.exemptedStorageAccounts.type | Should -Be 'Array'
        }

        It 'ExemptedStorageAccounts parameter should default to empty array' {
            $script:Parameters.exemptedStorageAccounts.defaultValue | Should -BeNullOrEmpty
        }
    }

    Context 'Policy Rule Validation' {
        BeforeAll {
            $script:PolicyRule = (Get-Content $script:PolicyPath -Raw | ConvertFrom-Json).properties.policyRule
        }

        It 'Should have if condition' {
            $script:PolicyRule.if | Should -Not -BeNullOrEmpty
        }

        It 'Should have then effect' {
            $script:PolicyRule.then | Should -Not -BeNullOrEmpty
            $script:PolicyRule.then.effect | Should -Not -BeNullOrEmpty
        }

        It 'Should use parameterized effect' {
            $script:PolicyRule.then.effect | Should -Match '^\[parameters\('
        }

        It 'Should target storage accounts' {
            $resourceTypeCondition = $script:PolicyRule.if.allOf | Where-Object {
                $_.field -eq 'type' -and $_.equals -eq 'Microsoft.Storage/storageAccounts'
            }
            $resourceTypeCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should check sasPolicy.sasExpirationPeriod property' {
            $allOfConditions = $script:PolicyRule.if.allOf
            $anyOfCondition = $allOfConditions | Where-Object { $_.anyOf }
            $anyOfCondition | Should -Not -BeNullOrEmpty

            $sasExpirationCheck = $anyOfCondition.anyOf | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/sasPolicy.sasExpirationPeriod'
            }
            $sasExpirationCheck | Should -Not -BeNullOrEmpty
        }

        It 'Should check for missing sasExpirationPeriod' {
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $missingCheck = $anyOfCondition.anyOf | Where-Object {
                $_.field -eq 'Microsoft.Storage/storageAccounts/sasPolicy.sasExpirationPeriod' -and
                $_.exists -eq 'false'
            }
            $missingCheck | Should -Not -BeNullOrEmpty
        }

        It 'Should check for excessive expiration period' {
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $excessiveCheck = $anyOfCondition.anyOf | Where-Object {
                $_.value -match 'sasExpirationPeriod' -and $_.greater
            }
            $excessiveCheck | Should -Not -BeNullOrEmpty
        }

        It 'Should have exemption check for storage accounts' {
            $exemptionCondition = $script:PolicyRule.if.allOf | Where-Object {
                $_.not -and $_.not.field -eq 'name'
            }
            $exemptionCondition | Should -Not -BeNullOrEmpty
            $exemptionCondition.not.in | Should -Match 'parameters\(.*exemptedStorageAccounts'
        }

        It 'Should use allOf for combining conditions' {
            $script:PolicyRule.if.allOf | Should -Not -BeNullOrEmpty
            $script:PolicyRule.if.allOf.Count | Should -BeGreaterThan 1
        }
    }

    Context 'Policy Metadata Validation' {
        BeforeAll {
            $script:Metadata = (Get-Content $script:PolicyPath -Raw | ConvertFrom-Json).properties.metadata
        }

        It 'Should have category set to Storage' {
            $script:Metadata.category | Should -Be 'Storage'
        }

        It 'Should have version' {
            $script:Metadata.version | Should -Not -BeNullOrEmpty
            $script:Metadata.version | Should -Match '^\d+\.\d+\.\d+$'
        }

        It 'Should have source' {
            $script:Metadata.source | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Policy Type Validation' {
        BeforeAll {
            $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        }

        It 'Should be Custom policy type' {
            $script:PolicyJson.properties.policyType | Should -Be 'Custom'
        }
    }
}

Describe 'Policy Logic Validation' -Tag @('Unit', 'Fast', 'Logic') {

    BeforeAll {
        $script:PolicyJson = Get-Content $script:PolicyPath -Raw | ConvertFrom-Json
        $script:PolicyRule = $script:PolicyJson.properties.policyRule
    }

    Context 'Expiration Period Calculation' {
        It 'Should parse days from DD.HH:MM:SS format' {
            $valueExpression = ($script:PolicyRule.if.allOf | Where-Object { $_.anyOf }).anyOf |
                Where-Object { $_.value -match 'sasExpirationPeriod' -and $_.greater }

            $valueExpression.value | Should -Match 'split.*\.'
            $valueExpression.value | Should -Match '\[0\]'
        }

        It 'Should compare days to maxSasExpirationDays parameter' {
            $comparisonExpression = ($script:PolicyRule.if.allOf | Where-Object { $_.anyOf }).anyOf |
                Where-Object { $_.value -match 'sasExpirationPeriod' -and $_.greater }

            $comparisonExpression.greater | Should -Match 'parameters\(.*maxSasExpirationDays'
        }
    }

    Context 'Exemption Logic' {
        It 'Should exclude storage accounts in exemption list' {
            $exemptionCondition = $script:PolicyRule.if.allOf | Where-Object {
                $_.not -and $_.not.field -eq 'name'
            }

            $exemptionCondition.not | Should -Not -BeNullOrEmpty
            $exemptionCondition.not.in | Should -Match 'exemptedStorageAccounts'
        }
    }

    Context 'Trigger Conditions' {
        It 'Should trigger on missing SAS expiration policy' {
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $missingCondition = $anyOfCondition.anyOf | Where-Object { $_.exists -eq 'false' }

            $missingCondition | Should -Not -BeNullOrEmpty
        }

        It 'Should trigger on excessive expiration period' {
            $anyOfCondition = $script:PolicyRule.if.allOf | Where-Object { $_.anyOf }
            $excessiveCondition = $anyOfCondition.anyOf | Where-Object { $_.greater }

            $excessiveCondition | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Additional Policy Files Validation' -Tag @('Unit', 'Fast', 'Files') {

    Context 'Policy Parameters File' {
        BeforeAll {
            $paramsPath = Join-Path (Split-Path $script:PolicyPath -Parent) 'policy-params.json'
            $script:ParamsFileExists = Test-Path $paramsPath
            if ($script:ParamsFileExists) {
                $script:ParamsJson = Get-Content $paramsPath -Raw | ConvertFrom-Json
            }
        }

        It 'Should have policy-params.json file' {
            $script:ParamsFileExists | Should -Be $true
        }

        It 'Should have valid JSON in policy-params.json' -Skip:(-not $script:ParamsFileExists) {
            $script:ParamsJson | Should -Not -BeNullOrEmpty
        }

        It 'Should have matching parameters in policy-params.json' -Skip:(-not $script:ParamsFileExists) {
            $script:ParamsJson.properties.parameters.effect | Should -Not -BeNullOrEmpty
            $script:ParamsJson.properties.parameters.maxSasExpirationDays | Should -Not -BeNullOrEmpty
            $script:ParamsJson.properties.parameters.exemptedStorageAccounts | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Policy Rule Only File' {
        BeforeAll {
            $ruleOnlyPath = Join-Path (Split-Path $script:PolicyPath -Parent) 'policy-rule-only.json'
            $script:RuleOnlyFileExists = Test-Path $ruleOnlyPath
            if ($script:RuleOnlyFileExists) {
                $script:RuleOnlyJson = Get-Content $ruleOnlyPath -Raw | ConvertFrom-Json
            }
        }

        It 'Should have policy-rule-only.json file' {
            $script:RuleOnlyFileExists | Should -Be $true
        }

        It 'Should have valid JSON in policy-rule-only.json' -Skip:(-not $script:RuleOnlyFileExists) {
            $script:RuleOnlyJson | Should -Not -BeNullOrEmpty
        }

        It 'Should have if and then sections in policy-rule-only.json' -Skip:(-not $script:RuleOnlyFileExists) {
            $script:RuleOnlyJson.if | Should -Not -BeNullOrEmpty
            $script:RuleOnlyJson.then | Should -Not -BeNullOrEmpty
        }
    }
}
