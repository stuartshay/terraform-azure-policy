# Azure Policy Assignment for Storage Account Public Access
# This Terraform configuration creates a policy assignment

# Create the Azure Policy Assignment
resource "azurerm_resource_group_policy_assignment" "deny_storage_public_access" {
  name                 = var.policy_assignment_name
  resource_group_id    = var.scope_id
  policy_definition_id = azurerm_policy_definition.deny_storage_public_access.id
  display_name         = var.policy_assignment_display_name
  description          = var.policy_assignment_description
  location             = "East US" # Required when using system-assigned identity

  # Policy parameters
  parameters = jsonencode({
    effect = {
      value = var.policy_effect
    }
  })

  # Assignment metadata
  metadata = jsonencode({
    category    = "Storage"
    assignedBy  = "Terraform"
    environment = var.environment
    owner       = var.owner
    createdDate = timestamp()
  })

  # Enable system assigned identity for remediation tasks
  identity {
    type = "SystemAssigned"
  }

  # Enforcement mode - can be Default or DoNotEnforce
  enforce = var.policy_effect != "Disabled"
}

# Output the policy assignment details
output "policy_assignment_id" {
  description = "The ID of the created policy assignment"
  value       = azurerm_resource_group_policy_assignment.deny_storage_public_access.id
}

output "policy_assignment_name" {
  description = "The name of the created policy assignment"
  value       = azurerm_resource_group_policy_assignment.deny_storage_public_access.name
}

output "policy_assignment_principal_id" {
  description = "The principal ID of the system assigned identity"
  value       = azurerm_resource_group_policy_assignment.deny_storage_public_access.identity[0].principal_id
  sensitive   = true
}
