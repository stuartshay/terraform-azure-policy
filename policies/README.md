# policies

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.45.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_deny_app_service_plan_not_zone_redundant"></a> [deny\_app\_service\_plan\_not\_zone\_redundant](#module\_deny\_app\_service\_plan\_not\_zone\_redundant) | ./app-service/deny-app-service-plan-not-zone-redundant | n/a |
| <a name="module_deny_function_app_anonymous"></a> [deny\_function\_app\_anonymous](#module\_deny\_function\_app\_anonymous) | ./function-app/deny-function-app-anonymous | n/a |
| <a name="module_deny_function_app_https_only"></a> [deny\_function\_app\_https\_only](#module\_deny\_function\_app\_https\_only) | ./function-app/deny-function-app-https-only | n/a |
| <a name="module_deny_network_no_nsg"></a> [deny\_network\_no\_nsg](#module\_deny\_network\_no\_nsg) | ./network/deny-network-no-nsg | n/a |
| <a name="module_deny_network_private_ips"></a> [deny\_network\_private\_ips](#module\_deny\_network\_private\_ips) | ./network/deny-network-private-ips | n/a |
| <a name="module_deny_storage_account_public_access"></a> [deny\_storage\_account\_public\_access](#module\_deny\_storage\_account\_public\_access) | ./storage/deny-storage-account-public-access | n/a |
| <a name="module_deny_storage_https_disabled"></a> [deny\_storage\_https\_disabled](#module\_deny\_storage\_https\_disabled) | ./storage/deny-storage-https-disabled | n/a |
| <a name="module_deny_storage_softdelete"></a> [deny\_storage\_softdelete](#module\_deny\_storage\_softdelete) | ./storage/deny-storage-softdelete | n/a |
| <a name="module_deny_storage_version"></a> [deny\_storage\_version](#module\_deny\_storage\_version) | ./storage/deny-storage-version | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_service_exempted_plans"></a> [app\_service\_exempted\_plans](#input\_app\_service\_exempted\_plans) | List of App Service Plan names that are exempt from the zone redundancy policy | `list(string)` | `[]` | no |
| <a name="input_app_service_minimum_instance_count"></a> [app\_service\_minimum\_instance\_count](#input\_app\_service\_minimum\_instance\_count) | Minimum number of instances required for zone redundancy (must be 2 or more) | `number` | `2` | no |
| <a name="input_app_service_policy_effect"></a> [app\_service\_policy\_effect](#input\_app\_service\_policy\_effect) | The effect for App Service policies (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_app_service_required_sku_tiers"></a> [app\_service\_required\_sku\_tiers](#input\_app\_service\_required\_sku\_tiers) | List of App Service Plan SKU tiers that support and require zone redundancy | `list(string)` | <pre>[<br/>  "PremiumV2",<br/>  "PremiumV3",<br/>  "PremiumV4",<br/>  "IsolatedV2"<br/>]</pre> | no |
| <a name="input_assignment_location"></a> [assignment\_location](#input\_assignment\_location) | Location for policy assignments (required for system-assigned identity) | `string` | `"East US"` | no |
| <a name="input_assignment_scope_id"></a> [assignment\_scope\_id](#input\_assignment\_scope\_id) | The scope ID for policy assignments (resource group ID) | `string` | n/a | yes |
| <a name="input_create_assignments"></a> [create\_assignments](#input\_create\_assignments) | Whether to create policy assignments | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, test, prod) | `string` | `"sandbox"` | no |
| <a name="input_function_app_exempted_apps"></a> [function\_app\_exempted\_apps](#input\_function\_app\_exempted\_apps) | List of Function App names that are exempt from the anonymous policy | `list(string)` | `[]` | no |
| <a name="input_function_app_exempted_resource_groups"></a> [function\_app\_exempted\_resource\_groups](#input\_function\_app\_exempted\_resource\_groups) | List of resource group names that are exempt from the Function App anonymous policy | `list(string)` | `[]` | no |
| <a name="input_function_app_https_exempted_apps"></a> [function\_app\_https\_exempted\_apps](#input\_function\_app\_https\_exempted\_apps) | List of Function App names that are exempt from the HTTPS-only policy | `list(string)` | `[]` | no |
| <a name="input_function_app_https_exempted_resource_groups"></a> [function\_app\_https\_exempted\_resource\_groups](#input\_function\_app\_https\_exempted\_resource\_groups) | List of resource group names that are exempt from the Function App HTTPS-only policy | `list(string)` | `[]` | no |
| <a name="input_function_app_https_policy_effect"></a> [function\_app\_https\_policy\_effect](#input\_function\_app\_https\_policy\_effect) | The effect for Function App HTTPS-only policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_function_app_policy_effect"></a> [function\_app\_policy\_effect](#input\_function\_app\_policy\_effect) | The effect for Function App policies (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where policy definitions will be created (optional) | `string` | `null` | no |
| <a name="input_network_policy_effect"></a> [network\_policy\_effect](#input\_network\_policy\_effect) | The effect for network policies (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policies | `string` | `"Policy-Team"` | no |
| <a name="input_storage_https_account_types"></a> [storage\_https\_account\_types](#input\_storage\_https\_account\_types) | List of storage account types that require HTTPS-only traffic | `list(string)` | <pre>[<br/>  "Standard_LRS",<br/>  "Standard_GRS",<br/>  "Standard_RAGRS",<br/>  "Standard_ZRS",<br/>  "Standard_GZRS",<br/>  "Standard_RAGZRS",<br/>  "Premium_LRS",<br/>  "Premium_ZRS",<br/>  "BlobStorage",<br/>  "BlockBlobStorage",<br/>  "FileStorage"<br/>]</pre> | no |
| <a name="input_storage_https_exempted_accounts"></a> [storage\_https\_exempted\_accounts](#input\_storage\_https\_exempted\_accounts) | List of storage account names that are exempt from the HTTPS-only policy | `list(string)` | `[]` | no |
| <a name="input_storage_https_policy_effect"></a> [storage\_https\_policy\_effect](#input\_storage\_https\_policy\_effect) | The effect for storage HTTPS-only policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_storage_policy_effect"></a> [storage\_policy\_effect](#input\_storage\_policy\_effect) | The effect for storage policies (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_storage_softdelete_policy_effect"></a> [storage\_softdelete\_policy\_effect](#input\_storage\_softdelete\_policy\_effect) | The effect for storage soft delete policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_storage_softdelete_retention_days"></a> [storage\_softdelete\_retention\_days](#input\_storage\_softdelete\_retention\_days) | Minimum number of days for soft delete retention | `number` | `7` | no |
| <a name="input_storage_versioning_account_types"></a> [storage\_versioning\_account\_types](#input\_storage\_versioning\_account\_types) | List of storage account types that require blob versioning | `list(string)` | <pre>[<br/>  "Standard_LRS",<br/>  "Standard_GRS",<br/>  "Standard_RAGRS",<br/>  "Standard_ZRS",<br/>  "Standard_GZRS",<br/>  "Standard_RAGZRS"<br/>]</pre> | no |
| <a name="input_storage_versioning_exempted_accounts"></a> [storage\_versioning\_exempted\_accounts](#input\_storage\_versioning\_exempted\_accounts) | List of storage account names that are exempt from the versioning policy | `list(string)` | `[]` | no |
| <a name="input_storage_versioning_policy_effect"></a> [storage\_versioning\_policy\_effect](#input\_storage\_versioning\_policy\_effect) | The effect for storage versioning policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | The Azure subscription ID where policies will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deny_app_service_plan_not_zone_redundant_assignment_id"></a> [deny\_app\_service\_plan\_not\_zone\_redundant\_assignment\_id](#output\_deny\_app\_service\_plan\_not\_zone\_redundant\_assignment\_id) | The ID of the deny App Service Plan not zone redundant policy assignment |
| <a name="output_deny_app_service_plan_not_zone_redundant_policy_id"></a> [deny\_app\_service\_plan\_not\_zone\_redundant\_policy\_id](#output\_deny\_app\_service\_plan\_not\_zone\_redundant\_policy\_id) | The ID of the deny App Service Plan not zone redundant policy definition |
| <a name="output_deny_function_app_anonymous_assignment_id"></a> [deny\_function\_app\_anonymous\_assignment\_id](#output\_deny\_function\_app\_anonymous\_assignment\_id) | The ID of the deny Function App anonymous policy assignment |
| <a name="output_deny_function_app_anonymous_policy_id"></a> [deny\_function\_app\_anonymous\_policy\_id](#output\_deny\_function\_app\_anonymous\_policy\_id) | The ID of the deny Function App anonymous policy definition |
| <a name="output_deny_function_app_https_only_assignment_id"></a> [deny\_function\_app\_https\_only\_assignment\_id](#output\_deny\_function\_app\_https\_only\_assignment\_id) | The ID of the deny Function App HTTPS-only policy assignment |
| <a name="output_deny_function_app_https_only_policy_id"></a> [deny\_function\_app\_https\_only\_policy\_id](#output\_deny\_function\_app\_https\_only\_policy\_id) | The ID of the deny Function App HTTPS-only policy definition |
| <a name="output_deny_network_no_nsg_assignment_id"></a> [deny\_network\_no\_nsg\_assignment\_id](#output\_deny\_network\_no\_nsg\_assignment\_id) | The ID of the deny network no NSG policy assignment |
| <a name="output_deny_network_no_nsg_policy_id"></a> [deny\_network\_no\_nsg\_policy\_id](#output\_deny\_network\_no\_nsg\_policy\_id) | The ID of the deny network no NSG policy definition |
| <a name="output_deny_network_private_ips_assignment_id"></a> [deny\_network\_private\_ips\_assignment\_id](#output\_deny\_network\_private\_ips\_assignment\_id) | The ID of the deny network private IPs policy assignment |
| <a name="output_deny_network_private_ips_policy_id"></a> [deny\_network\_private\_ips\_policy\_id](#output\_deny\_network\_private\_ips\_policy\_id) | The ID of the deny network private IPs policy definition |
| <a name="output_deny_storage_https_disabled_assignment_id"></a> [deny\_storage\_https\_disabled\_assignment\_id](#output\_deny\_storage\_https\_disabled\_assignment\_id) | The ID of the deny storage HTTPS-disabled policy assignment |
| <a name="output_deny_storage_https_disabled_policy_id"></a> [deny\_storage\_https\_disabled\_policy\_id](#output\_deny\_storage\_https\_disabled\_policy\_id) | The ID of the deny storage HTTPS-disabled policy definition |
| <a name="output_deny_storage_public_access_assignment_id"></a> [deny\_storage\_public\_access\_assignment\_id](#output\_deny\_storage\_public\_access\_assignment\_id) | The ID of the deny storage public access policy assignment |
| <a name="output_deny_storage_public_access_policy_id"></a> [deny\_storage\_public\_access\_policy\_id](#output\_deny\_storage\_public\_access\_policy\_id) | The ID of the deny storage public access policy definition |
| <a name="output_deny_storage_softdelete_assignment_id"></a> [deny\_storage\_softdelete\_assignment\_id](#output\_deny\_storage\_softdelete\_assignment\_id) | The ID of the deny storage soft delete policy assignment |
| <a name="output_deny_storage_softdelete_policy_id"></a> [deny\_storage\_softdelete\_policy\_id](#output\_deny\_storage\_softdelete\_policy\_id) | The ID of the deny storage soft delete policy definition |
| <a name="output_deny_storage_version_assignment_id"></a> [deny\_storage\_version\_assignment\_id](#output\_deny\_storage\_version\_assignment\_id) | The ID of the deny storage versioning policy assignment |
| <a name="output_deny_storage_version_policy_id"></a> [deny\_storage\_version\_policy\_id](#output\_deny\_storage\_version\_policy\_id) | The ID of the deny storage versioning policy definition |
| <a name="output_deployed_assignments"></a> [deployed\_assignments](#output\_deployed\_assignments) | List of deployed policy assignments |
| <a name="output_deployed_policies"></a> [deployed\_policies](#output\_deployed\_policies) | List of deployed policy definitions |
<!-- END_TF_DOCS -->
