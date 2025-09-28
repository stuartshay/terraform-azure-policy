# Azure Policy Definition and Assignment for Deny Storage Softdelete
# This Terraform configuration creates a custom Azure Policy definition and assignment

module "policy" {
  source = "../../../modules/azure-policy"

  # Policy Configuration
  policy_rule_file = "${path.module}/rule.json"
  policy_category  = "Storage"

  # Management Group (optional)
  management_group_id = var.management_group_id

  # Assignment Configuration
  create_assignment              = var.create_assignment
  assignment_scope_id            = var.assignment_scope_id
  policy_assignment_name         = var.policy_assignment_name
  policy_assignment_display_name = var.policy_assignment_display_name
  policy_assignment_description  = var.policy_assignment_description
  assignment_location            = var.assignment_location

  # Policy Parameters
  policy_effect = var.policy_effect
  policy_parameters = {
    effect = {
      value = var.policy_effect
    }
    minimumRetentionDays = {
      value = var.minimum_retention_days
    }
  }

  # Environment
  environment = var.environment
  owner       = var.owner
}
