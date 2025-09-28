# Azure Policies - Main Deployment Configuration
# This configuration deploys all Azure Policy definitions and assignments

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

module "deny_storage_version" {
  source = "./storage/deny-storage-version"

  # Management Group (optional)
  management_group_id = var.management_group_id

  # Assignment Configuration
  create_assignment              = var.create_assignments
  assignment_scope_id            = var.assignment_scope_id
  policy_assignment_name         = "deny-storage-version-assignment"
  policy_assignment_display_name = "Deny Storage Account Without Blob Versioning Assignment"
  policy_assignment_description  = "This assignment enforces the policy to deny storage accounts that have blob versioning disabled."
  assignment_location            = var.assignment_location

  # Policy Configuration
  policy_effect = var.storage_versioning_policy_effect

  # Storage account types that require versioning
  storage_account_types = var.storage_versioning_account_types

  # Exempted storage accounts (optional)
  exempted_storage_accounts = var.storage_versioning_exempted_accounts

  # Environment
  environment = var.environment
  owner       = var.owner
}

module "deny_storage_https_disabled" {
  source = "./storage/deny-storage-https-disabled"

  # Management Group (optional)
  management_group_id = var.management_group_id

  # Assignment Configuration
  create_assignment              = var.create_assignments
  assignment_scope_id            = var.assignment_scope_id
  policy_assignment_name         = "deny-storage-https-disabled-assignment"
  policy_assignment_display_name = "Deny Storage Account Without HTTPS-Only Traffic Assignment"
  policy_assignment_description  = "This assignment enforces the policy to deny storage accounts that do not have HTTPS-only traffic enabled."
  assignment_location            = var.assignment_location

  # Policy Configuration
  policy_effect = var.storage_https_policy_effect

  # Storage account types that require HTTPS-only traffic
  storage_account_types = var.storage_https_account_types

  # Exempted storage accounts (optional)
  exempted_storage_accounts = var.storage_https_exempted_accounts

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

module "deny_network_private_ips" {
  source = "./network/deny-network-private-ips"

  # Management Group (optional)
  management_group_id = var.management_group_id

  # Assignment Configuration
  create_assignment              = var.create_assignments
  assignment_scope_id            = var.assignment_scope_id
  policy_assignment_name         = "deny-network-private-ips-assignment"
  policy_assignment_display_name = "Deny Network Resources with Public IP Addresses Assignment"
  policy_assignment_description  = "This assignment enforces the policy to deny network resources that use public IP addresses."
  assignment_location            = var.assignment_location

  # Policy Configuration
  policy_effect = var.network_policy_effect

  # Exempted resource names configuration
  exempted_resource_names = [
    "AzureFirewallManagementPublicIP",
    "GatewayPublicIP",
    "BastionPublicIP"
  ]

  # Environment
  environment = var.environment
  owner       = var.owner
}

# Deploy Function App Policies
module "deny_function_app_anonymous" {
  source = "./function-app/deny-function-app-anonymous"

  # Management Group (optional)
  management_group_id = var.management_group_id

  # Assignment Configuration
  create_assignment              = var.create_assignments
  assignment_scope_id            = var.assignment_scope_id
  policy_assignment_name         = "deny-function-app-anonymous-assignment"
  policy_assignment_display_name = "Deny Function App Anonymous Access Assignment"
  policy_assignment_description  = "This assignment enforces the policy to deny Function Apps that allow anonymous access."
  assignment_location            = var.assignment_location

  # Policy Configuration
  policy_effect = var.function_app_policy_effect

  # Exempted Function Apps and Resource Groups
  exempted_function_apps   = var.function_app_exempted_apps
  exempted_resource_groups = var.function_app_exempted_resource_groups

  # Environment
  environment = var.environment
  owner       = var.owner
}

module "deny_function_app_https_only" {
  source = "./function-app/deny-function-app-https-only"

  # Management Group (optional)
  management_group_id = var.management_group_id

  # Assignment Configuration
  create_assignment              = var.create_assignments
  assignment_scope_id            = var.assignment_scope_id
  policy_assignment_name         = "deny-function-app-https-only-assignment"
  policy_assignment_display_name = "Deny Function App Non-HTTPS Access Assignment"
  policy_assignment_description  = "This assignment enforces the policy to deny Function Apps that do not require HTTPS-only connections."
  assignment_location            = var.assignment_location

  # Policy Configuration
  policy_effect = var.function_app_https_policy_effect

  # Exempted Function Apps and Resource Groups
  exempted_function_apps   = var.function_app_https_exempted_apps
  exempted_resource_groups = var.function_app_https_exempted_resource_groups

  # Environment
  environment = var.environment
  owner       = var.owner
}

# Deploy App Service Policies
module "deny_app_service_plan_not_zone_redundant" {
  source = "./app-service/deny-app-service-plan-not-zone-redundant"

  # Management Group (optional)
  management_group_id = var.management_group_id

  # Assignment Configuration
  create_assignment              = var.create_assignments
  assignment_scope_id            = var.assignment_scope_id
  policy_assignment_name         = "deny-app-service-plan-not-zone-redundant-assignment"
  policy_assignment_display_name = "Deny App Service Plan Without Zone Redundancy Assignment"
  policy_assignment_description  = "This assignment enforces the policy to deny App Service Plans that do not have zone redundancy enabled."
  assignment_location            = var.assignment_location

  # Policy Configuration
  policy_effect = var.app_service_policy_effect

  # App Service Plan Configuration
  required_sku_tiers         = var.app_service_required_sku_tiers
  exempted_app_service_plans = var.app_service_exempted_plans
  minimum_instance_count     = var.app_service_minimum_instance_count

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
