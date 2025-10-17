# azure-policy-initiative

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
| [azurerm_policy_set_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_set_definition) | resource |
| [azurerm_resource_group_policy_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assignment_description"></a> [assignment\_description](#input\_assignment\_description) | Description for the policy set assignment | `string` | `null` | no |
| <a name="input_assignment_display_name"></a> [assignment\_display\_name](#input\_assignment\_display\_name) | Display name for the policy set assignment | `string` | `null` | no |
| <a name="input_assignment_location"></a> [assignment\_location](#input\_assignment\_location) | Location for the policy set assignment (required for system-assigned identity) | `string` | `"East US"` | no |
| <a name="input_assignment_name"></a> [assignment\_name](#input\_assignment\_name) | Name for the policy set assignment | `string` | `null` | no |
| <a name="input_assignment_parameters"></a> [assignment\_parameters](#input\_assignment\_parameters) | Parameters for the policy set assignment | `map(any)` | `null` | no |
| <a name="input_assignment_scope_id"></a> [assignment\_scope\_id](#input\_assignment\_scope\_id) | The scope ID for policy set assignment (resource group ID) | `string` | `null` | no |
| <a name="input_category"></a> [category](#input\_category) | Category for the policy initiative (e.g., Security, Compliance, Cost Management) | `string` | `"General"` | no |
| <a name="input_create_assignment"></a> [create\_assignment](#input\_create\_assignment) | Whether to create a policy set assignment | `bool` | `true` | no |
| <a name="input_enforcement_mode"></a> [enforcement\_mode](#input\_enforcement\_mode) | Whether to enforce the policy set assignment | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, test, prod) | `string` | `"sandbox"` | no |
| <a name="input_initiative_description"></a> [initiative\_description](#input\_initiative\_description) | Description of the policy initiative | `string` | n/a | yes |
| <a name="input_initiative_display_name"></a> [initiative\_display\_name](#input\_initiative\_display\_name) | Display name of the policy initiative | `string` | n/a | yes |
| <a name="input_initiative_name"></a> [initiative\_name](#input\_initiative\_name) | Name of the policy initiative (policy set) | `string` | n/a | yes |
| <a name="input_initiative_parameters"></a> [initiative\_parameters](#input\_initiative\_parameters) | Parameters for the policy initiative | `map(any)` | `null` | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where the initiative will be created | `string` | `null` | no |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Additional metadata for the policy initiative | `map(string)` | `{}` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy initiative | `string` | `"Policy-Team"` | no |
| <a name="input_policy_definitions"></a> [policy\_definitions](#input\_policy\_definitions) | List of policy definitions to include in the initiative | <pre>list(object({<br/>    policy_definition_id = string<br/>    reference_id         = string<br/>    parameters           = map(any)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_assignment_id"></a> [assignment\_id](#output\_assignment\_id) | The ID of the created policy set assignment (if created) |
| <a name="output_assignment_identity"></a> [assignment\_identity](#output\_assignment\_identity) | The identity of the created policy set assignment (if created) |
| <a name="output_assignment_name"></a> [assignment\_name](#output\_assignment\_name) | The name of the created policy set assignment (if created) |
| <a name="output_initiative_display_name"></a> [initiative\_display\_name](#output\_initiative\_display\_name) | The display name of the created policy initiative |
| <a name="output_initiative_id"></a> [initiative\_id](#output\_initiative\_id) | The ID of the created policy initiative (policy set) |
| <a name="output_initiative_name"></a> [initiative\_name](#output\_initiative\_name) | The name of the created policy initiative |
<!-- END_TF_DOCS -->
