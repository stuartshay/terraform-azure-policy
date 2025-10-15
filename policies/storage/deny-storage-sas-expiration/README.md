# Deny Storage Account SAS Token Expiration Greater Than Maximum Policy

## Overview

This Azure Policy denies the creation or modification of Azure Storage accounts that have a Shared Access Signature (SAS) token expiration period exceeding the specified maximum (default: 90 days). This policy helps enforce security best practices by limiting the validity period of SAS tokens, reducing the risk if tokens are compromised or leaked.

## Policy Details

### What it does

- **Denies** creation or modification of storage accounts with SAS expiration periods exceeding the maximum
- **Supports** configurable maximum expiration days (7, 14, 30, 60, 90, 180, 365)
- **Allows** exemptions for specific storage accounts that require longer SAS validity periods
- **Evaluates** resources at creation and update time

### Resources Targeted

- `Microsoft.Storage/storageAccounts`

### Key Features

- **Configurable Maximum**: Set maximum SAS expiration from 7 to 365 days
- **Security Focused**: Enforces limited SAS token validity to minimize compromise risk
- **Flexible Exemptions**: Exclude specific storage accounts from the policy
- **Compliance Support**: Helps meet security and governance requirements

## Policy Logic

The policy evaluates storage accounts with the following conditions:

```json
{
  "allOf": [
    {
      "equals": "Microsoft.Storage/storageAccounts",
      "field": "type"
    },
    {
      "not": {
        "field": "name",
        "in": "[parameters('exemptedStorageAccounts')]"
      }
    },
    {
      "anyOf": [
        {
          "field": "Microsoft.Storage/storageAccounts/sasPolicy.sasExpirationPeriod",
          "exists": "false"
        },
        {
          "value": "...",
          "greater": "[parameters('maxSasExpirationDays')]"
        }
      ]
    }
  ]
}
```

The policy triggers when:

1. A storage account is being created or updated
2. The storage account is NOT in the exempted list
3. Either:
   - The `sasExpirationPeriod` is not configured, OR
   - The configured period exceeds the maximum allowed days

## Usage

### Basic Deployment

```hcl
module "deny_storage_sas_expiration" {
  source = "./policies/storage/deny-storage-sas-expiration"

  environment = "production"
  owner       = "Security-Team"
}
```

### Advanced Deployment with Custom Maximum

```hcl
module "deny_storage_sas_expiration" {
  source = "./policies/storage/deny-storage-sas-expiration"

  environment = "production"
  owner       = "Security-Team"

  create_assignment = true
  assignment_scope_id = "/subscriptions/your-subscription-id/resourceGroups/rg-production"
  policy_effect = "Deny"

  # Set maximum to 30 days for stricter security
  max_sas_expiration_days = 30

  # Exempt legacy systems
  exempted_storage_accounts = [
    "legacyintegrationsa",
    "partnerapisa"
  ]
}
```

### Audit Mode Deployment

```hcl
module "deny_storage_sas_expiration" {
  source = "./policies/storage/deny-storage-sas-expiration"

  environment = "sandbox"
  policy_effect = "Audit"
  max_sas_expiration_days = 90

  create_assignment = true
  assignment_scope_id = "/subscriptions/your-subscription-id"
}
```

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `environment` | `string` | `"sandbox"` | Environment name for tagging |
| `owner` | `string` | `"Policy-Team"` | Owner of the policy for governance |
| `management_group_id` | `string` | `null` | Management group where policy is defined |
| `create_assignment` | `bool` | `true` | Whether to create a policy assignment |
| `assignment_scope_id` | `string` | `null` | Scope for policy assignment |
| `assignment_location` | `string` | `"East US"` | Location for policy assignment identity |
| `policy_assignment_name` | `string` | Auto-generated | Name of the policy assignment |
| `policy_assignment_display_name` | `string` | Auto-generated | Display name for the assignment |
| `policy_assignment_description` | `string` | Auto-generated | Description of the assignment |
| `policy_effect` | `string` | `"Deny"` | Policy effect (Audit, Deny, Disabled) |
| `max_sas_expiration_days` | `number` | `90` | Maximum SAS expiration (7, 14, 30, 60, 90, 180, 365) |
| `exempted_storage_accounts` | `list(string)` | `[]` | Storage accounts exempt from policy |

### Maximum Expiration Options

The policy supports the following maximum expiration periods:

- **7 days**: Highly secure, short-term access
- **14 days**: Short-term projects and integrations
- **30 days**: Monthly access cycles
- **60 days**: Quarterly access requirements
- **90 days** (default): Standard security recommendation
- **180 days**: Semi-annual access patterns
- **365 days**: Annual maximum (use with caution)

## Benefits of Limited SAS Expiration

### Security

- **Reduced Risk Window**: Shorter validity periods limit exposure if tokens are compromised
- **Forced Rotation**: Regular token regeneration improves security posture
- **Audit Trail**: Frequent renewals create better audit and access logs

### Compliance

- **Regulatory Requirements**: Many regulations require limited credential validity
- **Security Standards**: Aligns with NIST, ISO 27001, and CIS benchmarks
- **Data Governance**: Enforces temporal access controls

### Operational

- **Access Control**: Forces regular review of who needs SAS access
- **Incident Response**: Limits blast radius of token leaks
- **Monitoring**: Easier to correlate access patterns with specific tokens

## SAS Expiration Period Format

Azure Storage uses the format `DD.HH:MM:SS` for SAS expiration periods:

- **90 days**: `90.00:00:00`
- **30 days**: `30.00:00:00`
- **7 days, 12 hours**: `7.12:00:00`

The policy evaluates the days component to enforce the maximum.

## Testing

### Unit Tests

```bash
# Run policy structure validation tests
Invoke-Pester ./tests/storage/Storage.Unit-DenyStorageSasExpiration.Tests.ps1
```

### Integration Tests

```bash
# Run compliance tests against live Azure resources
Invoke-Pester ./tests/storage/Storage.Integration-DenyStorageSasExpiration.Tests.ps1
```

### Manual Testing

```powershell
# Create storage account with SAS policy (compliant - 30 days)
New-AzStorageAccount `
  -ResourceGroupName "rg-test" `
  -Name "testsa001" `
  -Location "eastus" `
  -SkuName "Standard_LRS" `
  -SasExpirationPeriod "30.00:00:00"

# Create storage account with SAS policy (non-compliant - 180 days with 90 day max)
New-AzStorageAccount `
  -ResourceGroupName "rg-test" `
  -Name "testsa002" `
  -Location "eastus" `
  -SkuName "Standard_LRS" `
  -SasExpirationPeriod "180.00:00:00"  # This will be denied
```

## Implementation Best Practices

### Start with Audit Mode

```hcl
policy_effect = "Audit"
max_sas_expiration_days = 90
```

Monitor for 30-60 days to understand current SAS usage patterns.

### Gradual Enforcement

1. **Phase 1**: Audit mode with 180 days maximum
2. **Phase 2**: Switch to Deny mode with 180 days
3. **Phase 3**: Reduce to 90 days (standard recommendation)
4. **Phase 4**: Consider 30 days for high-security environments

### Exemption Management

- Document why each storage account is exempted
- Review exemptions quarterly
- Set expiration dates for temporary exemptions
- Use naming conventions for exempt accounts

### Integration with Access Controls

- Combine with least privilege access policies
- Use Azure RBAC to limit who can configure SAS policies
- Implement SAS token monitoring and alerting
- Regular access reviews

## Security Considerations

### SAS Token Best Practices

1. **Use User Delegation SAS**: Secured with Azure AD credentials (most secure)
2. **Set Signed Start Time**: Always specify when the SAS becomes valid
3. **Limit Permissions**: Grant only required permissions (read, write, etc.)
4. **Use HTTPS Only**: Require secure transport
5. **IP Restrictions**: Limit SAS usage to specific IP ranges when possible
6. **Set Expiration Action**: Configure Log or Block action for policy violations

### Storage Account Configuration

```powershell
# Set SAS expiration policy on storage account
Set-AzStorageAccount `
  -ResourceGroupName "rg-prod" `
  -Name "prodsa" `
  -SasExpirationPeriod "90.00:00:00" `
  -SasExpirationAction "Block"
```

### Monitoring

- Enable Azure Monitor logging for SAS usage
- Set up alerts for policy violations
- Track SAS creation and expiration patterns
- Monitor for anomalous SAS token usage

## Troubleshooting

### Common Issues

#### Policy Violation: SAS Expiration Too Long

**Error**: Storage account creation denied due to SAS expiration period exceeding maximum.

**Solution**:

```powershell
# Set compliant SAS expiration
Set-AzStorageAccount `
  -Name "storageaccount" `
  -ResourceGroupName "rg-name" `
  -SasExpirationPeriod "90.00:00:00"
```

#### No SAS Policy Configured

**Error**: Storage account denied because SAS policy is not set.

**Solution**:

```powershell
# Configure SAS expiration policy
Set-AzStorageAccount `
  -Name "storageaccount" `
  -ResourceGroupName "rg-name" `
  -SasExpirationPeriod "30.00:00:00" `
  -SasExpirationAction "Log"
```

#### Exemption Not Working

**Issue**: Storage account still denied despite being in exemption list.

**Check**:

- Verify storage account name exactly matches exemption list entry
- Names are case-sensitive
- Check for typos or extra spaces

## References

- [Azure SAS Expiration Policy Documentation](https://learn.microsoft.com/en-us/azure/storage/common/sas-expiration-policy)
- [Shared Access Signatures Best Practices](https://learn.microsoft.com/en-us/azure/storage/common/storage-sas-overview)
- [Azure Storage Security Guide](https://learn.microsoft.com/en-us/azure/storage/blobs/security-recommendations)

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_policy"></a> [policy](#module\_policy) | ../../../modules/azure-policy | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assignment_location"></a> [assignment\_location](#input\_assignment\_location) | Location for the policy assignment (required for system-assigned identity) | `string` | `"East US"` | no |
| <a name="input_assignment_scope_id"></a> [assignment\_scope\_id](#input\_assignment\_scope\_id) | The scope ID for policy assignment (resource group ID) | `string` | `null` | no |
| <a name="input_create_assignment"></a> [create\_assignment](#input\_create\_assignment) | Whether to create a policy assignment | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, test, prod) | `string` | `"sandbox"` | no |
| <a name="input_exempted_storage_accounts"></a> [exempted\_storage\_accounts](#input\_exempted\_storage\_accounts) | List of storage account names that are exempt from this policy | `list(string)` | `[]` | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where the policy definition will be created | `string` | `null` | no |
| <a name="input_max_sas_expiration_days"></a> [max\_sas\_expiration\_days](#input\_max\_sas\_expiration\_days) | Maximum allowed SAS token expiration period in days | `number` | `90` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | `"This assignment enforces the policy to deny storage accounts with SAS token expiration periods exceeding the maximum allowed."` | no |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | `"Deny Storage Account SAS Token Expiration Greater Than Maximum Assignment"` | no |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | `"deny-storage-sas-expiration-assignment"` | no |
| <a name="input_policy_effect"></a> [policy\_effect](#input\_policy\_effect) | The effect of the policy (Audit, Deny, or Disabled) | `string` | `"Deny"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the created policy assignment |
| <a name="output_policy_assignment_identity"></a> [policy\_assignment\_identity](#output\_policy\_assignment\_identity) | The identity of the created policy assignment |
| <a name="output_policy_assignment_name"></a> [policy\_assignment\_name](#output\_policy\_assignment\_name) | The name of the created policy assignment |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the created policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the created policy definition |
<!-- END_TF_DOCS -->
