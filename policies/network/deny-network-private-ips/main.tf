# Terraform configuration for deny-network-private-ips policy

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Local values for policy configuration
locals {
  policy_definition_file = "${path.module}/rule.json"
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
    deployed_by = "terraform"
    policy_type = "network-security"
  }))

  parameters = jsonencode(local.policy_parameters)

  policy_rule = jsonencode(local.policy_rule)
}

# Create policy assignment if requested
resource "azurerm_resource_group_policy_assignment" "this" {
  count = var.create_assignment ? 1 : 0

  name                 = var.policy_assignment_name
  display_name         = var.policy_assignment_display_name
  description          = var.policy_assignment_description
  resource_group_id    = var.assignment_scope_id
  policy_definition_id = azurerm_policy_definition.this.id
  location             = var.assignment_location

  # Use system-assigned identity for potential remediation
  identity {
    type = "SystemAssigned"
  }

  # Policy parameters
  parameters = jsonencode({
    effect = {
      value = var.policy_effect
    }
    exemptedResourceNames = {
      value = var.exempted_resource_names
    }
  })

  # Metadata for the assignment
  metadata = jsonencode({
    environment   = var.environment
    owner         = var.owner
    deployed_by   = "terraform"
    creation_date = timestamp()
  })
}
