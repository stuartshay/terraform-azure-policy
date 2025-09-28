# Variables for the App Service Plan Zone Redundancy Policy Module

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "sandbox"
}

variable "owner" {
  description = "Owner of the policy"
  type        = string
  default     = "Policy-Team"
}

variable "management_group_id" {
  description = "The Azure management group ID where the policy definition will be created"
  type        = string
  default     = null
}

# Policy Assignment Configuration
variable "create_assignment" {
  description = "Whether to create a policy assignment"
  type        = bool
  default     = true
}

variable "assignment_scope_id" {
  description = "The scope ID for policy assignment (resource group ID)"
  type        = string
  default     = null
}

variable "assignment_location" {
  description = "Location for the policy assignment (required for system-assigned identity)"
  type        = string
  default     = "East US"
}

variable "policy_assignment_name" {
  description = "Name for the policy assignment"
  type        = string
  default     = "deny-app-service-plan-not-zone-redundant-assignment"
}

variable "policy_assignment_display_name" {
  description = "Display name for the policy assignment"
  type        = string
  default     = "Deny App Service Plan Without Zone Redundancy Assignment"
}

variable "policy_assignment_description" {
  description = "Description for the policy assignment"
  type        = string
  default     = "This assignment enforces the policy to deny App Service Plans that do not have zone redundancy enabled."
}

# Policy Configuration
variable "policy_effect" {
  description = "The effect of the policy (Audit, Deny, or Disabled)"
  type        = string
  default     = "Audit"

  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.policy_effect)
    error_message = "The policy_effect must be one of: Audit, Deny, or Disabled."
  }
}

variable "required_sku_tiers" {
  description = "List of App Service Plan SKU tiers that support and require zone redundancy"
  type        = list(string)
  default = [
    "PremiumV2",
    "PremiumV3",
    "PremiumV4",
    "IsolatedV2"
  ]

  validation {
    condition = alltrue([
      for tier in var.required_sku_tiers : contains([
        "PremiumV2", "PremiumV3", "PremiumV4", "IsolatedV2"
      ], tier)
    ])
    error_message = "All SKU tiers must be valid Azure App Service Plan tiers that support zone redundancy."
  }
}

variable "exempted_app_service_plans" {
  description = "List of App Service Plan names that are exempt from this policy"
  type        = list(string)
  default     = []
}

variable "minimum_instance_count" {
  description = "Minimum number of instances required for zone redundancy (must be 2 or more)"
  type        = number
  default     = 2

  validation {
    condition     = var.minimum_instance_count >= 2
    error_message = "The minimum_instance_count must be 2 or more for zone redundancy."
  }
}
