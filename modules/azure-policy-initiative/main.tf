# Azure Policy Initiative (Policy Set) Module
# This module creates Azure Policy Set Definitions (Initiatives) and assignments

# Create the Azure Policy Set Definition (Initiative)
resource "azurerm_policy_set_definition" "this" {
  name                = var.initiative_name
  policy_type         = "Custom"
  display_name        = var.initiative_display_name
  description         = var.initiative_description
  management_group_id = var.management_group_id

  # Dynamic policy definition references
  dynamic "policy_definition_reference" {
    for_each = var.policy_definitions
    content {
      policy_definition_id = policy_definition_reference.value.policy_definition_id
      reference_id         = policy_definition_reference.value.reference_id
      parameter_values     = jsonencode(policy_definition_reference.value.parameters)
    }
  }

  # Initiative metadata
  metadata = jsonencode(merge(var.metadata, {
    category    = var.category
    environment = var.environment
    owner       = var.owner
    createdBy   = "Terraform"
    createdDate = timestamp()
  }))

  # Initiative parameters (if any)
  parameters = var.initiative_parameters != null ? jsonencode(var.initiative_parameters) : null
}

# Create the Azure Policy Set Assignment (conditional)
resource "azurerm_resource_group_policy_assignment" "this" {
  count                = var.create_assignment ? 1 : 0
  name                 = var.assignment_name
  resource_group_id    = var.assignment_scope_id
  policy_definition_id = azurerm_policy_set_definition.this.id
  display_name         = var.assignment_display_name
  description          = var.assignment_description
  location             = var.assignment_location

  # Assignment parameters
  parameters = var.assignment_parameters != null ? jsonencode(var.assignment_parameters) : null

  # Assignment metadata
  metadata = jsonencode({
    category    = var.category
    assignedBy  = "Terraform"
    environment = var.environment
    owner       = var.owner
    createdDate = timestamp()
  })

  # Enable system assigned identity for remediation tasks
  identity {
    type = "SystemAssigned"
  }

  # Enforcement mode
  enforce = var.enforcement_mode
}
