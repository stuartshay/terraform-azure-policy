# Shared Azure Policy Module
# This module creates Azure Policy definitions and assignments with common patterns

# Local values for policy configuration
locals {
  policy_definition_file = var.policy_rule_file
  policy_definition      = jsondecode(file(local.policy_definition_file))

  # Extract policy metadata
  policy_name         = local.policy_definition.name
  policy_display_name = local.policy_definition.properties.displayName
  policy_description  = local.policy_definition.properties.description
  policy_metadata     = local.policy_definition.properties.metadata
  policy_parameters   = local.policy_definition.properties.parameters
  policy_rule         = local.policy_definition.properties.policyRule
}

# Create the Azure Policy Definition
resource "azurerm_policy_definition" "this" {
  name                = local.policy_name
  policy_type         = "Custom"
  mode                = "All"
  display_name        = local.policy_display_name
  description         = local.policy_description
  management_group_id = var.management_group_id

  metadata = jsonencode(merge(local.policy_metadata, {
    environment = var.environment
    owner       = var.owner
  }))

  parameters = jsonencode(local.policy_parameters)

  policy_rule = jsonencode(local.policy_rule)
}

# Create the Azure Policy Assignment (conditional)
resource "azurerm_resource_group_policy_assignment" "this" {
  count                = var.create_assignment ? 1 : 0
  name                 = var.policy_assignment_name
  resource_group_id    = var.assignment_scope_id
  policy_definition_id = azurerm_policy_definition.this.id
  display_name         = var.policy_assignment_display_name
  description          = var.policy_assignment_description
  location             = var.assignment_location

  # Policy parameters - dynamically constructed based on provided parameters
  parameters = jsonencode(var.policy_parameters)

  # Assignment metadata
  metadata = jsonencode({
    category    = var.policy_category
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
  enforce = var.policy_effect != "Disabled"
}
