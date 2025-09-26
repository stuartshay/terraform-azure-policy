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

# Network Policy Outputs
output "deny_network_no_nsg_policy_id" {
  description = "The ID of the deny network no NSG policy definition"
  value       = module.deny_network_no_nsg.policy_definition_id
}

output "deny_network_no_nsg_assignment_id" {
  description = "The ID of the deny network no NSG policy assignment"
  value       = module.deny_network_no_nsg.policy_assignment_id
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
      name = module.deny_network_no_nsg.policy_definition_name
      id   = module.deny_network_no_nsg.policy_definition_id
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
      name = module.deny_network_no_nsg.policy_assignment_name
      id   = module.deny_network_no_nsg.policy_assignment_id
    }
  ]
}
