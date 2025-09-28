# Outputs for the shared Azure Policy module

output "policy_definition_id" {
  description = "The ID of the created policy definition"
  value       = azurerm_policy_definition.this.id
}

output "policy_definition_name" {
  description = "The name of the created policy definition"
  value       = azurerm_policy_definition.this.name
}

output "policy_assignment_id" {
  description = "The ID of the created policy assignment (if created)"
  value       = var.create_assignment ? azurerm_resource_group_policy_assignment.this[0].id : null
}

output "policy_assignment_name" {
  description = "The name of the created policy assignment (if created)"
  value       = var.create_assignment ? azurerm_resource_group_policy_assignment.this[0].name : null
}

output "policy_assignment_identity" {
  description = "The identity of the created policy assignment (if created)"
  value       = var.create_assignment ? azurerm_resource_group_policy_assignment.this[0].identity : null
}
