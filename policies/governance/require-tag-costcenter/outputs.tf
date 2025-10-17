# Outputs for require-tag-costcenter policy

output "policy_definition_id" {
  description = "The ID of the policy definition"
  value       = module.policy.policy_definition_id
}

output "policy_definition_name" {
  description = "The name of the policy definition"
  value       = module.policy.policy_definition_name
}

output "policy_assignment_id" {
  description = "The ID of the policy assignment (if created)"
  value       = module.policy.policy_assignment_id
}

output "policy_assignment_identity" {
  description = "The identity of the policy assignment (if created)"
  value       = module.policy.policy_assignment_identity
}
