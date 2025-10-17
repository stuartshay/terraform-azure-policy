# azure-policy

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.48.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.49.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_policy_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition) | resource |
| [azurerm_resource_group_policy_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assignment_location"></a> [assignment\_location](#input\_assignment\_location) | Location for the policy assignment (required for system-assigned identity) | `string` | `"East US"` | no |
| <a name="input_assignment_scope_id"></a> [assignment\_scope\_id](#input\_assignment\_scope\_id) | The scope ID for policy assignment (resource group ID) | `string` | `null` | no |
| <a name="input_create_assignment"></a> [create\_assignment](#input\_create\_assignment) | Whether to create a policy assignment | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, test, prod) | `string` | `"sandbox"` | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where the policy definition will be created | `string` | `null` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy | `string` | `"Policy-Team"` | no |
| <a name="input_policy_assignment_description"></a> [policy\_assignment\_description](#input\_policy\_assignment\_description) | Description for the policy assignment | `string` | n/a | yes |
| <a name="input_policy_assignment_display_name"></a> [policy\_assignment\_display\_name](#input\_policy\_assignment\_display\_name) | Display name for the policy assignment | `string` | n/a | yes |
| <a name="input_policy_assignment_name"></a> [policy\_assignment\_name](#input\_policy\_assignment\_name) | Name for the policy assignment | `string` | n/a | yes |
| <a name="input_policy_category"></a> [policy\_category](#input\_policy\_category) | Category for the policy (e.g., Storage, Network, Function App) | `string` | n/a | yes |
| <a name="input_policy_effect"></a> [policy\_effect](#input\_policy\_effect) | The effect of the policy (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_policy_parameters"></a> [policy\_parameters](#input\_policy\_parameters) | Map of policy parameters to pass to the policy assignment | `any` | `{}` | no |
| <a name="input_policy_rule_file"></a> [policy\_rule\_file](#input\_policy\_rule\_file) | Path to the JSON file containing the policy rule definition | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_assignment_id"></a> [policy\_assignment\_id](#output\_policy\_assignment\_id) | The ID of the created policy assignment (if created) |
| <a name="output_policy_assignment_identity"></a> [policy\_assignment\_identity](#output\_policy\_assignment\_identity) | The identity of the created policy assignment (if created) |
| <a name="output_policy_assignment_name"></a> [policy\_assignment\_name](#output\_policy\_assignment\_name) | The name of the created policy assignment (if created) |
| <a name="output_policy_definition_id"></a> [policy\_definition\_id](#output\_policy\_definition\_id) | The ID of the created policy definition |
| <a name="output_policy_definition_name"></a> [policy\_definition\_name](#output\_policy\_definition\_name) | The name of the created policy definition |
<!-- END_TF_DOCS -->
