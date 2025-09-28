# Outputs for the Azure Policy Initiative module

output "initiative_id" {
  description = "The ID of the created policy initiative (policy set)"
  value       = azurerm_policy_set_definition.this.id
}

output "initiative_name" {
  description = "The name of the created policy initiative"
  value       = azurerm_policy_set_definition.this.name
}

output "initiative_display_name" {
  description = "The display name of the created policy initiative"
  value       = azurerm_policy_set_definition.this.display_name
}

output "assignment_id" {
  description = "The ID of the created policy set assignment (if created)"
  value       = var.create_assignment ? azurerm_resource_group_policy_assignment.this[0].id : null
}

output "assignment_name" {
  description = "The name of the created policy set assignment (if created)"
  value       = var.create_assignment ? azurerm_resource_group_policy_assignment.this[0].name : null
}

output "assignment_identity" {
  description = "The identity of the created policy set assignment (if created)"
  value       = var.create_assignment ? azurerm_resource_group_policy_assignment.this[0].identity : null
}
