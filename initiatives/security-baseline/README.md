# Security Baseline Initiative

## Overview

The Security Baseline Initiative is a comprehensive Azure Policy Initiative (Policy Set) that enforces fundamental security policies across Azure resources. This initiative groups multiple security-focused policies to provide a baseline security posture for your Azure environment.

## Included Policies

This initiative includes the following policies:

### 1. Deny Storage Account Public Access

- **Policy**: `deny-storage-account-public-access`
- **Purpose**: Prevents storage accounts from allowing public access
- **Effect**: Configurable (Audit/Deny/Disabled)
- **Reference ID**: `DenyStoragePublicAccess`

### 2. Deny Network Resources Without NSG

- **Policy**: `deny-network-no-nsg`
- **Purpose**: Ensures network resources have Network Security Groups attached
- **Effect**: Configurable (Audit/Deny/Disabled)
- **Reference ID**: `DenyNetworkNoNSG`
- **Exemptions**: Standard Azure service subnets (Gateway, Firewall, etc.)

### 3. Deny Function App Non-HTTPS Access

- **Policy**: `deny-function-app-https-only`
- **Purpose**: Enforces HTTPS-only access for Function Apps
- **Effect**: Configurable (Audit/Deny/Disabled)
- **Reference ID**: `DenyFunctionAppNonHTTPS`
- **Exemptions**: Configurable function apps and resource groups

## Usage

### Basic Usage

```hcl
module "security_baseline" {
  source = "./initiatives/security-baseline"

  # Assignment Configuration
  assignment_scope_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/my-rg"

  # Policy Effects
  storage_policy_effect     = "Deny"
  network_policy_effect     = "Audit"
  function_app_policy_effect = "Deny"

  # Environment
  environment = "production"
  owner       = "Security-Team"
}
```

### Advanced Configuration

```hcl
module "security_baseline" {
  source = "./initiatives/security-baseline"

  # Management Group Deployment
  management_group_id = "my-management-group"

  # Assignment Configuration
  create_assignment       = true
  assignment_name         = "security-baseline-prod"
  assignment_scope_id     = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/production-rg"
  assignment_display_name = "Production Security Baseline"
  assignment_description  = "Security baseline for production environment"
  assignment_location     = "East US"
  enforcement_mode        = true

  # Policy Effects
  storage_policy_effect     = "Deny"
  network_policy_effect     = "Deny"
  function_app_policy_effect = "Audit"

  # Exemptions
  exempted_subnets = [
    "GatewaySubnet",
    "AzureFirewallSubnet",
    "CustomExemptedSubnet"
  ]

  exempted_function_apps = [
    "legacy-function-app"
  ]

  exempted_resource_groups = [
    "development-rg"
  ]

  # Environment
  environment = "production"
  owner       = "Security-Team"
}
```

## Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `assignment_scope_id` | string | The scope ID for policy set assignment (resource group ID) |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `management_group_id` | string | null | Azure management group ID where the initiative will be created |
| `create_assignment` | bool | true | Whether to create a policy set assignment |
| `assignment_name` | string | "security-baseline-assignment" | Name for the policy set assignment |
| `assignment_display_name` | string | "Security Baseline Initiative Assignment" | Display name for the assignment |
| `assignment_description` | string | "This assignment enforces..." | Description for the assignment |
| `assignment_location` | string | "East US" | Location for the assignment |
| `enforcement_mode` | bool | true | Whether to enforce the policy set assignment |
| `storage_policy_effect` | string | "Audit" | Effect for storage policies (Audit/Deny/Disabled) |
| `network_policy_effect` | string | "Audit" | Effect for network policies (Audit/Deny/Disabled) |
| `function_app_policy_effect` | string | "Audit" | Effect for Function App policies (Audit/Deny/Disabled) |
| `exempted_subnets` | list(string) | [Standard Azure subnets] | Subnet names exempt from NSG requirements |
| `exempted_function_apps` | list(string) | [] | Function App names exempt from HTTPS-only policy |
| `exempted_resource_groups` | list(string) | [] | Resource group names exempt from Function App policies |
| `environment` | string | "sandbox" | Environment name |
| `owner` | string | "Policy-Team" | Owner of the policy initiative |

## Outputs

| Output | Description |
|--------|-------------|
| `initiative_id` | The ID of the created security baseline initiative |
| `initiative_name` | The name of the created security baseline initiative |
| `initiative_display_name` | The display name of the created security baseline initiative |
| `assignment_id` | The ID of the created policy set assignment (if created) |
| `assignment_name` | The name of the created policy set assignment (if created) |
| `assignment_identity` | The identity of the created policy set assignment (if created) |
| `storage_policy_id` | The ID of the storage public access policy |
| `network_policy_id` | The ID of the network NSG policy |
| `function_app_policy_id` | The ID of the function app HTTPS policy |

## Deployment Recommendations

### Development Environment

```hcl
storage_policy_effect     = "Audit"
network_policy_effect     = "Audit"
function_app_policy_effect = "Audit"
enforcement_mode          = false
```

### Testing Environment

```hcl
storage_policy_effect     = "Audit"
network_policy_effect     = "Deny"
function_app_policy_effect = "Audit"
enforcement_mode          = true
```

### Production Environment

```hcl
storage_policy_effect     = "Deny"
network_policy_effect     = "Deny"
function_app_policy_effect = "Deny"
enforcement_mode          = true
```

## Compliance and Monitoring

After deploying this initiative:

1. **Monitor Compliance**: Use Azure Policy compliance dashboard to track adherence
2. **Review Violations**: Regularly review policy violations and exemption requests
3. **Update Exemptions**: Maintain exemption lists based on business requirements
4. **Remediation**: Use policy remediation tasks for automatic compliance

## Support

For questions or issues with this security baseline initiative:

1. Review individual policy documentation in the `policies/` directory
2. Check Azure Policy compliance reports
3. Contact the Policy Team for exemption requests or modifications

## Version History

- **v1.0.0**: Initial security baseline initiative with storage, network, and function app policies

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_function_app_https_policy"></a> [function\_app\_https\_policy](#module\_function\_app\_https\_policy) | ../../policies/function-app/deny-function-app-https-only | n/a |
| <a name="module_network_nsg_policy"></a> [network\_nsg\_policy](#module\_network\_nsg\_policy) | ../../policies/network/deny-network-no-nsg | n/a |
| <a name="module_security_baseline_initiative"></a> [security\_baseline\_initiative](#module\_security\_baseline\_initiative) | ../../modules/azure-policy-initiative | n/a |
| <a name="module_storage_public_access_policy"></a> [storage\_public\_access\_policy](#module\_storage\_public\_access\_policy) | ../../policies/storage/deny-storage-account-public-access | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assignment_description"></a> [assignment\_description](#input\_assignment\_description) | Description for the policy set assignment | `string` | `"This assignment enforces the security baseline initiative across the specified scope."` | no |
| <a name="input_assignment_display_name"></a> [assignment\_display\_name](#input\_assignment\_display\_name) | Display name for the policy set assignment | `string` | `"Security Baseline Initiative Assignment"` | no |
| <a name="input_assignment_location"></a> [assignment\_location](#input\_assignment\_location) | Location for the policy set assignment (required for system-assigned identity) | `string` | `"East US"` | no |
| <a name="input_assignment_name"></a> [assignment\_name](#input\_assignment\_name) | Name for the policy set assignment | `string` | `"security-baseline-assignment"` | no |
| <a name="input_assignment_parameters"></a> [assignment\_parameters](#input\_assignment\_parameters) | Parameters for the policy set assignment | `map(any)` | `null` | no |
| <a name="input_assignment_scope_id"></a> [assignment\_scope\_id](#input\_assignment\_scope\_id) | The scope ID for policy set assignment (resource group ID) | `string` | `null` | no |
| <a name="input_create_assignment"></a> [create\_assignment](#input\_create\_assignment) | Whether to create a policy set assignment | `bool` | `true` | no |
| <a name="input_enforcement_mode"></a> [enforcement\_mode](#input\_enforcement\_mode) | Whether to enforce the policy set assignment | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, test, prod) | `string` | `"sandbox"` | no |
| <a name="input_exempted_function_apps"></a> [exempted\_function\_apps](#input\_exempted\_function\_apps) | List of Function App names that are exempt from HTTPS-only policy | `list(string)` | `[]` | no |
| <a name="input_exempted_resource_groups"></a> [exempted\_resource\_groups](#input\_exempted\_resource\_groups) | List of resource group names that are exempt from Function App policies | `list(string)` | `[]` | no |
| <a name="input_exempted_subnets"></a> [exempted\_subnets](#input\_exempted\_subnets) | List of subnet names that are exempt from NSG requirements | `list(string)` | <pre>[<br/>  "GatewaySubnet",<br/>  "AzureFirewallSubnet",<br/>  "AzureFirewallManagementSubnet",<br/>  "RouteServerSubnet",<br/>  "AzureBastionSubnet"<br/>]</pre> | no |
| <a name="input_function_app_policy_effect"></a> [function\_app\_policy\_effect](#input\_function\_app\_policy\_effect) | The effect for Function App policies (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_management_group_id"></a> [management\_group\_id](#input\_management\_group\_id) | The Azure management group ID where the initiative will be created | `string` | `null` | no |
| <a name="input_network_policy_effect"></a> [network\_policy\_effect](#input\_network\_policy\_effect) | The effect for network policies (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the policy initiative | `string` | `"Policy-Team"` | no |
| <a name="input_storage_policy_effect"></a> [storage\_policy\_effect](#input\_storage\_policy\_effect) | The effect for storage policies (Audit, Deny, or Disabled) | `string` | `"Audit"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_assignment_id"></a> [assignment\_id](#output\_assignment\_id) | The ID of the created policy set assignment (if created) |
| <a name="output_assignment_identity"></a> [assignment\_identity](#output\_assignment\_identity) | The identity of the created policy set assignment (if created) |
| <a name="output_assignment_name"></a> [assignment\_name](#output\_assignment\_name) | The name of the created policy set assignment (if created) |
| <a name="output_function_app_policy_id"></a> [function\_app\_policy\_id](#output\_function\_app\_policy\_id) | The ID of the function app HTTPS policy |
| <a name="output_initiative_display_name"></a> [initiative\_display\_name](#output\_initiative\_display\_name) | The display name of the created security baseline initiative |
| <a name="output_initiative_id"></a> [initiative\_id](#output\_initiative\_id) | The ID of the created security baseline initiative |
| <a name="output_initiative_name"></a> [initiative\_name](#output\_initiative\_name) | The name of the created security baseline initiative |
| <a name="output_network_policy_id"></a> [network\_policy\_id](#output\_network\_policy\_id) | The ID of the network NSG policy |
| <a name="output_storage_policy_id"></a> [storage\_policy\_id](#output\_storage\_policy\_id) | The ID of the storage public access policy |
<!-- END_TF_DOCS -->