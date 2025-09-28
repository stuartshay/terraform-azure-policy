# Security Baseline Initiative
# This initiative groups security-focused policies for baseline compliance

# First, we need to reference the individual policies
module "storage_public_access_policy" {
  source = "../../policies/storage/deny-storage-account-public-access"

  # Policy Configuration
  management_group_id = var.management_group_id
  create_assignment   = false # We'll assign through the initiative

  # Environment
  environment = var.environment
  owner       = var.owner
}

module "network_nsg_policy" {
  source = "../../policies/network/deny-network-no-nsg"

  # Policy Configuration
  management_group_id = var.management_group_id
  create_assignment   = false # We'll assign through the initiative

  # Environment
  environment = var.environment
  owner       = var.owner
}

module "function_app_https_policy" {
  source = "../../policies/function-app/deny-function-app-https-only"

  # Policy Configuration
  management_group_id = var.management_group_id
  create_assignment   = false # We'll assign through the initiative

  # Environment
  environment = var.environment
  owner       = var.owner
}

# Create the Security Baseline Initiative
locals {
  policy_definitions = [
    {
      policy_definition_id = module.storage_public_access_policy.policy_definition_id
      reference_id         = "DenyStoragePublicAccess"
      parameters = {
        effect = {
          value = var.storage_policy_effect
        }
      }
    }
  ]
}

module "security_baseline_initiative" {
  source = "../../modules/azure-policy-initiative"

  initiative_name         = "security-baseline-initiative"
  initiative_display_name = "Security Baseline Initiative"
  initiative_description  = "A comprehensive security baseline initiative for Azure resources"
  category                = "Security Center"
  management_group_id     = var.management_group_id

  # Policy Definitions to include in the initiative
  policy_definitions = local.policy_definitions

  # Initiative Assignment Configuration
  create_assignment       = var.create_assignment
  assignment_name         = var.assignment_name
  assignment_scope_id     = var.assignment_scope_id
  assignment_display_name = var.assignment_display_name
  assignment_description  = var.assignment_description
  assignment_location     = var.assignment_location
  enforcement_mode        = var.enforcement_mode

  # Assignment Parameters (override individual policy parameters if needed)
  assignment_parameters = var.assignment_parameters

  # Environment
  environment = var.environment
  owner       = var.owner

  # Additional metadata
  metadata = {
    version    = "1.0.0"
    compliance = "Security Baseline"
    framework  = "Custom"
  }
}
