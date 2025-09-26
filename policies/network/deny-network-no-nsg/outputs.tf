# Outputs for deny-network-no-nsg policy

# Policy Definition Outputs
output "policy_definition_id" {
  description = "The ID of the created policy definition"
  value       = azurerm_policy_definition.this.id
}

output "policy_definition_name" {
  description = "The name of the created policy definition"
  value       = azurerm_policy_definition.this.name
}

output "policy_definition_display_name" {
  description = "The display name of the created policy definition"
  value       = azurerm_policy_definition.this.display_name
}

# Policy Assignment Outputs (only if assignment is created)
output "policy_assignment_id" {
  description = "The ID of the created policy assignment"
  value       = var.create_assignment ? azurerm_resource_group_policy_assignment.this[0].id : null
}

output "policy_assignment_name" {
  description = "The name of the created policy assignment"
  value       = var.create_assignment ? azurerm_resource_group_policy_assignment.this[0].name : null
}

output "policy_assignment_principal_id" {
  description = "The principal ID of the system assigned identity"
  value       = var.create_assignment ? azurerm_resource_group_policy_assignment.this[0].identity[0].principal_id : null
  sensitive   = true
}
