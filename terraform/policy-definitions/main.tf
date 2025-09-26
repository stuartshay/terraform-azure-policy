# Azure Policy Definition for Storage Account Public Access
# This Terraform configuration creates a custom Azure Policy definition

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Local values for subscription handling
locals {
  # Extract subscription GUID from path if needed
  subscription_guid = can(regex("^/subscriptions/", var.subcription_id)) ? regex("/subscriptions/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})", var.subcription_id)[0] : var.subcription_id
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = local.subscription_guid
}

# Local values for policy configuration
locals {
  policy_definition_file = "${path.module}/../../policies/storage/deny-storage-account-public-access.json"
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
resource "azurerm_policy_definition" "deny_storage_public_access" {
  name                = local.policy_name
  policy_type         = "Custom"
  mode                = "All"
  display_name        = local.policy_display_name
  description         = local.policy_description
  management_group_id = var.mangement_group_id != null ? var.mangement_group_id : null

  metadata = jsonencode(merge(local.policy_metadata, {
    environment = var.environment
    owner       = var.owner
  }))

  parameters = jsonencode(local.policy_parameters)

  policy_rule = jsonencode(local.policy_rule)
}

# Output the policy definition details
output "policy_definition_id" {
  description = "The ID of the created policy definition"
  value       = azurerm_policy_definition.deny_storage_public_access.id
}

output "policy_definition_name" {
  description = "The name of the created policy definition"
  value       = azurerm_policy_definition.deny_storage_public_access.name
}

output "policy_definition_display_name" {
  description = "The display name of the created policy definition"
  value       = azurerm_policy_definition.deny_storage_public_access.display_name
}
