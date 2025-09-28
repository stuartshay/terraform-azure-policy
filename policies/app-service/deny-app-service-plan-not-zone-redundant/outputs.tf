# Outputs for deny-app-service-plan-not-zone-redundant policy

# Policy Definition Outputs
output "policy_definition_id" {
  description = "The ID of the created policy definition"
  value       = module.policy.policy_definition_id
}

output "policy_definition_name" {
  description = "The name of the created policy definition"
  value       = module.policy.policy_definition_name
}

# Policy Assignment Outputs (only if assignment is created)
output "policy_assignment_id" {
  description = "The ID of the created policy assignment"
  value       = module.policy.policy_assignment_id
}

output "policy_assignment_name" {
  description = "The name of the created policy assignment"
  value       = module.policy.policy_assignment_name
}

output "policy_assignment_identity" {
  description = "The identity of the created policy assignment"
  value       = module.policy.policy_assignment_identity
}
