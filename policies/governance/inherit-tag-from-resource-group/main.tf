# Azure Policy Definition and Assignment for Inheriting Tags from Resource Group
# This Terraform configuration creates a custom Azure Policy definition and assignment
# Note: This policy uses the Modify effect to automatically add tags to resources

module "policy" {
  source = "../../../modules/azure-policy"

  # Policy Configuration
  policy_rule_file = "${path.module}/rule.json"
  policy_category  = "Governance"

  # Management Group (optional)
  management_group_id = var.management_group_id

  # Assignment Configuration
  create_assignment              = var.create_assignment
  assignment_scope_id            = var.assignment_scope_id
  policy_assignment_name         = var.policy_assignment_name
  policy_assignment_display_name = var.policy_assignment_display_name
  policy_assignment_description  = var.policy_assignment_description
  assignment_location            = var.assignment_location

  # Policy Parameters (this policy uses Modify effect hardcoded in rule.json)
  # Note: policy_effect is not passed because "modify" is hardcoded in rule.json
  # The module validation only accepts Audit/Deny/Disabled, but this policy
  # has a fixed "modify" effect defined in its policy rule
  policy_parameters = {
    tagName = {
      value = var.tag_name
    }
  }

  # Environment
  environment = var.environment
  owner       = var.owner
}
