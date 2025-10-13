# Azure Policy Module for Deny Function App AAD Only
# This module creates an Azure Policy definition and optionally assigns it to a scope

module "deny_function_app_aad_only_policy" {
  source = "../../../modules/azure-policy"

  # Policy Definition Configuration
  policy_rule_file = "${path.module}/rule.json"
  policy_category  = "Function App"

  # Management Group (optional)
  management_group_id = var.management_group_id

  # Policy Assignment Configuration
  create_assignment   = var.create_assignment
  assignment_scope_id = var.assignment_scope_id
  assignment_location = var.assignment_location

  # Policy Assignment Details
  policy_assignment_name         = var.policy_assignment_name
  policy_assignment_display_name = var.policy_assignment_display_name
  policy_assignment_description  = var.policy_assignment_description

  # Policy Effect and Parameters
  policy_effect = var.policy_effect
  # Policy parameters passed to the assignment
  policy_parameters = {
    effect = {
      value = var.policy_effect
    }
  }

  # Tags
  environment = var.environment
  owner       = var.owner
}
