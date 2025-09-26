# Azure Policies - Main Deployment Configuration
# This configuration deploys all Azure Policy definitions and assignments

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Deploy Storage Policies
module "deny_storage_account_public_access" {
  source = "./storage/deny-storage-account-public-access"

  # Management Group (optional)
  management_group_id = var.management_group_id

  # Assignment Configuration
  create_assignment              = var.create_assignments
  assignment_scope_id            = var.assignment_scope_id
  policy_assignment_name         = "deny-storage-public-access-assignment"
  policy_assignment_display_name = "Deny Storage Account Public Access Assignment"
  policy_assignment_description  = "This assignment enforces the policy to deny storage accounts with public access enabled."
  assignment_location            = var.assignment_location

  # Policy Configuration
  policy_effect = var.storage_policy_effect

  # Environment
  environment = var.environment
  owner       = var.owner
}

module "deny_storage_softdelete" {
  source = "./storage/deny-storage-softdelete"

  # Management Group (optional)
  management_group_id = var.management_group_id

  # Assignment Configuration
  create_assignment              = var.create_assignments
  assignment_scope_id            = var.assignment_scope_id
  policy_assignment_name         = "deny-storage-softdelete-assignment"
  policy_assignment_display_name = "Deny Storage Account Soft Delete Disabled Assignment"
  policy_assignment_description  = "This assignment enforces the policy to deny storage accounts with soft delete disabled or insufficient retention periods."
  assignment_location            = var.assignment_location

  # Policy Configuration
  policy_effect          = var.storage_softdelete_policy_effect
  minimum_retention_days = var.storage_softdelete_retention_days

  # Environment
  environment = var.environment
  owner       = var.owner
}

# Deploy Network Policies
module "deny_network_no_nsg" {
  source = "./network/deny-network-no-nsg"

  # Management Group (optional)
  management_group_id = var.management_group_id

  # Assignment Configuration
  create_assignment              = var.create_assignments
  assignment_scope_id            = var.assignment_scope_id
  policy_assignment_name         = "deny-network-no-nsg-assignment"
  policy_assignment_display_name = "Deny Network Resources Without NSG Assignment"
  policy_assignment_description  = "This assignment enforces the policy to deny network resources without NSGs."
  assignment_location            = var.assignment_location

  # Policy Configuration
  policy_effect = var.network_policy_effect

  # Exempted subnets configuration
  exempted_subnets = [
    "GatewaySubnet",
    "AzureFirewallSubnet",
    "AzureFirewallManagementSubnet",
    "RouteServerSubnet",
    "AzureBastionSubnet"
  ]

  # Environment
  environment = var.environment
  owner       = var.owner
}

# Add more policy modules here as they are created
# Example:
# module "another_policy" {
#   source = "./category/policy-name"
#   ...
# }
