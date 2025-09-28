# Outputs for Security Baseline Initiative

output "initiative_id" {
  description = "The ID of the created security baseline initiative"
  value       = module.security_baseline_initiative.initiative_id
}

output "initiative_name" {
  description = "The name of the created security baseline initiative"
  value       = module.security_baseline_initiative.initiative_name
}

output "initiative_display_name" {
  description = "The display name of the created security baseline initiative"
  value       = module.security_baseline_initiative.initiative_display_name
}

output "assignment_id" {
  description = "The ID of the created policy set assignment (if created)"
  value       = module.security_baseline_initiative.assignment_id
}

output "assignment_name" {
  description = "The name of the created policy set assignment (if created)"
  value       = module.security_baseline_initiative.assignment_name
}

output "assignment_identity" {
  description = "The identity of the created policy set assignment (if created)"
  value       = module.security_baseline_initiative.assignment_identity
}

# Individual policy outputs
output "storage_policy_id" {
  description = "The ID of the storage public access policy"
  value       = module.storage_public_access_policy.policy_definition_id
}

output "network_policy_id" {
  description = "The ID of the network NSG policy"
  value       = module.network_nsg_policy.policy_definition_id
}

output "function_app_policy_id" {
  description = "The ID of the function app HTTPS policy"
  value       = module.function_app_https_policy.policy_definition_id
}
