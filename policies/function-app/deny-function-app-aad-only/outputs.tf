output "policy_definition_id" {
  description = "The ID of the Azure Policy definition"
  value       = module.deny_function_app_aad_only_policy.policy_definition_id
}

output "policy_definition_name" {
  description = "The name of the Azure Policy definition"
  value       = module.deny_function_app_aad_only_policy.policy_definition_name
}

output "policy_assignment_id" {
  description = "The ID of the policy assignment (if created)"
  value       = module.deny_function_app_aad_only_policy.policy_assignment_id
}

output "policy_assignment_name" {
  description = "The name of the policy assignment (if created)"
  value       = module.deny_function_app_aad_only_policy.policy_assignment_name
}
