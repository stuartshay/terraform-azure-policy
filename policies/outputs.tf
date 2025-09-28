# Outputs for Azure Policies Main Deployment

# Storage Policy Outputs
output "deny_storage_public_access_policy_id" {
  description = "The ID of the deny storage public access policy definition"
  value       = module.deny_storage_account_public_access.policy_definition_id
}

output "deny_storage_public_access_assignment_id" {
  description = "The ID of the deny storage public access policy assignment"
  value       = module.deny_storage_account_public_access.policy_assignment_id
}

output "deny_storage_softdelete_policy_id" {
  description = "The ID of the deny storage soft delete policy definition"
  value       = module.deny_storage_softdelete.policy_definition_id
}

output "deny_storage_softdelete_assignment_id" {
  description = "The ID of the deny storage soft delete policy assignment"
  value       = module.deny_storage_softdelete.policy_assignment_id
}

output "deny_storage_version_policy_id" {
  description = "The ID of the deny storage versioning policy definition"
  value       = module.deny_storage_version.policy_definition_id
}

output "deny_storage_version_assignment_id" {
  description = "The ID of the deny storage versioning policy assignment"
  value       = module.deny_storage_version.policy_assignment_id
}

output "deny_storage_https_disabled_policy_id" {
  description = "The ID of the deny storage HTTPS-disabled policy definition"
  value       = module.deny_storage_https_disabled.policy_definition_id
}

output "deny_storage_https_disabled_assignment_id" {
  description = "The ID of the deny storage HTTPS-disabled policy assignment"
  value       = module.deny_storage_https_disabled.policy_assignment_id
}

# Network Policy Outputs
output "deny_network_no_nsg_policy_id" {
  description = "The ID of the deny network no NSG policy definition"
  value       = module.deny_network_no_nsg.policy_definition_id
}

output "deny_network_no_nsg_assignment_id" {
  description = "The ID of the deny network no NSG policy assignment"
  value       = module.deny_network_no_nsg.policy_assignment_id
}

output "deny_network_private_ips_policy_id" {
  description = "The ID of the deny network private IPs policy definition"
  value       = module.deny_network_private_ips.policy_definition_id
}

output "deny_network_private_ips_assignment_id" {
  description = "The ID of the deny network private IPs policy assignment"
  value       = module.deny_network_private_ips.policy_assignment_id
}

# Function App Policy Outputs
output "deny_function_app_anonymous_policy_id" {
  description = "The ID of the deny Function App anonymous policy definition"
  value       = module.deny_function_app_anonymous.policy_definition_id
}

output "deny_function_app_anonymous_assignment_id" {
  description = "The ID of the deny Function App anonymous policy assignment"
  value       = module.deny_function_app_anonymous.policy_assignment_id
}

output "deny_function_app_https_only_policy_id" {
  description = "The ID of the deny Function App HTTPS-only policy definition"
  value       = module.deny_function_app_https_only.policy_definition_id
}

output "deny_function_app_https_only_assignment_id" {
  description = "The ID of the deny Function App HTTPS-only policy assignment"
  value       = module.deny_function_app_https_only.policy_assignment_id
}

# App Service Policy Outputs
output "deny_app_service_plan_not_zone_redundant_policy_id" {
  description = "The ID of the deny App Service Plan not zone redundant policy definition"
  value       = module.deny_app_service_plan_not_zone_redundant.policy_definition_id
}

output "deny_app_service_plan_not_zone_redundant_assignment_id" {
  description = "The ID of the deny App Service Plan not zone redundant policy assignment"
  value       = module.deny_app_service_plan_not_zone_redundant.policy_assignment_id
}

# Summary Outputs
output "deployed_policies" {
  description = "List of deployed policy definitions"
  value = [
    {
      name = module.deny_storage_account_public_access.policy_definition_name
      id   = module.deny_storage_account_public_access.policy_definition_id
    },
    {
      name = module.deny_storage_softdelete.policy_definition_name
      id   = module.deny_storage_softdelete.policy_definition_id
    },
    {
      name = module.deny_storage_version.policy_definition_name
      id   = module.deny_storage_version.policy_definition_id
    },
    {
      name = module.deny_storage_https_disabled.policy_definition_name
      id   = module.deny_storage_https_disabled.policy_definition_id
    },
    {
      name = module.deny_network_no_nsg.policy_definition_name
      id   = module.deny_network_no_nsg.policy_definition_id
    },
    {
      name = module.deny_network_private_ips.policy_definition_name
      id   = module.deny_network_private_ips.policy_definition_id
    },
    {
      name = module.deny_function_app_anonymous.policy_definition_name
      id   = module.deny_function_app_anonymous.policy_definition_id
    },
    {
      name = module.deny_function_app_https_only.policy_definition_name
      id   = module.deny_function_app_https_only.policy_definition_id
    },
    {
      name = module.deny_app_service_plan_not_zone_redundant.policy_definition_name
      id   = module.deny_app_service_plan_not_zone_redundant.policy_definition_id
    }
  ]
}

output "deployed_assignments" {
  description = "List of deployed policy assignments"
  value = [
    {
      name = module.deny_storage_account_public_access.policy_assignment_name
      id   = module.deny_storage_account_public_access.policy_assignment_id
    },
    {
      name = module.deny_storage_softdelete.policy_assignment_name
      id   = module.deny_storage_softdelete.policy_assignment_id
    },
    {
      name = module.deny_storage_version.policy_assignment_name
      id   = module.deny_storage_version.policy_assignment_id
    },
    {
      name = module.deny_storage_https_disabled.policy_assignment_name
      id   = module.deny_storage_https_disabled.policy_assignment_id
    },
    {
      name = module.deny_network_no_nsg.policy_assignment_name
      id   = module.deny_network_no_nsg.policy_assignment_id
    },
    {
      name = module.deny_network_private_ips.policy_assignment_name
      id   = module.deny_network_private_ips.policy_assignment_id
    },
    {
      name = module.deny_function_app_anonymous.policy_assignment_name
      id   = module.deny_function_app_anonymous.policy_assignment_id
    },
    {
      name = module.deny_function_app_https_only.policy_assignment_name
      id   = module.deny_function_app_https_only.policy_assignment_id
    },
    {
      name = module.deny_app_service_plan_not_zone_redundant.policy_assignment_name
      id   = module.deny_app_service_plan_not_zone_redundant.policy_assignment_id
    }
  ]
}
