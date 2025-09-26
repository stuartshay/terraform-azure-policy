# policies

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_deny_network_no_nsg"></a> [deny\_network\_no\_nsg](#module\_deny\_network\_no\_nsg) | ./network/deny-network-no-nsg | n/a |
| <a name="module_deny_storage_account_public_access"></a> [deny\_storage\_account\_public\_access](#module\_deny\_storage\_account\_public\_access) | ./storage/deny-storage-account-public-access | n/a |
| <a name="module_deny_storage_softdelete"></a> [deny\_storage\_softdelete](#module\_deny\_storage\_softdelete) | ./storage/deny-storage-softdelete | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assignment_location"></a> [assignment\_location](#input\_assignment\_location) | Location for policy assignments (required for system-assigned identity) | `string` | `"East US"` | no |
| <a name="input_assignment_scope_id"></a> [assignment\_scope\_id](#input\_assignment\_scope\_id) | The scope ID for policy assignments (resource group ID) | `string` | n/a | yes |
| <a name="input_create_assignments"></a> [create\_assignments](#input\_create\_assignments) | Whether to create policy assignments | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, test, prod) | `string` | `"sandbox"` | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where policy definitions will be created (optional) | `string` | `null` | no |
| <a name="input_network_policy_effect"></a> [network\_policy\_effect](#input\_network\_policy\_effect) | The effect for network policies (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policies | `string` | `"Policy-Team"` | no |
| <a name="input_storage_policy_effect"></a> [storage\_policy\_effect](#input\_storage\_policy\_effect) | The effect for storage policies (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_storage_softdelete_policy_effect"></a> [storage\_softdelete\_policy\_effect](#input\_storage\_softdelete\_policy\_effect) | The effect for storage soft delete policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_storage_softdelete_retention_days"></a> [storage\_softdelete\_retention\_days](#input\_storage\_softdelete\_retention\_days) | Minimum number of days for soft delete retention | `number` | `7` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | The Azure subscription ID where policies will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deny_network_no_nsg_assignment_id"></a> [deny\_network\_no\_nsg\_assignment\_id](#output\_deny\_network\_no\_nsg\_assignment\_id) | The ID of the deny network no NSG policy assignment |
| <a name="output_deny_network_no_nsg_policy_id"></a> [deny\_network\_no\_nsg\_policy\_id](#output\_deny\_network\_no\_nsg\_policy\_id) | The ID of the deny network no NSG policy definition |
| <a name="output_deny_storage_public_access_assignment_id"></a> [deny\_storage\_public\_access\_assignment\_id](#output\_deny\_storage\_public\_access\_assignment\_id) | The ID of the deny storage public access policy assignment |
| <a name="output_deny_storage_public_access_policy_id"></a> [deny\_storage\_public\_access\_policy\_id](#output\_deny\_storage\_public\_access\_policy\_id) | The ID of the deny storage public access policy definition |
| <a name="output_deny_storage_softdelete_assignment_id"></a> [deny\_storage\_softdelete\_assignment\_id](#output\_deny\_storage\_softdelete\_assignment\_id) | The ID of the deny storage soft delete policy assignment |
| <a name="output_deny_storage_softdelete_policy_id"></a> [deny\_storage\_softdelete\_policy\_id](#output\_deny\_storage\_softdelete\_policy\_id) | The ID of the deny storage soft delete policy definition |
| <a name="output_deployed_assignments"></a> [deployed\_assignments](#output\_deployed\_assignments) | List of deployed policy assignments |
| <a name="output_deployed_policies"></a> [deployed\_policies](#output\_deployed\_policies) | List of deployed policy definitions |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
