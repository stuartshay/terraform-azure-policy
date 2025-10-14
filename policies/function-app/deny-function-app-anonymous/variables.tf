# Variables for the Function App Anonymous Access Policy Module

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
  default     = "deny-function-app-anonymous-assignment"
}

variable "policy_assignment_display_name" {
  description = "Display name for the policy assignment"
  type        = string
  default     = "Deny Function App Anonymous Access Assignment"
}

variable "policy_assignment_description" {
  description = "Description for the policy assignment"
  type        = string
  default     = "This assignment enforces the policy to deny Function Apps that allow anonymous access."
}

# Policy Configuration
variable "policy_effect" {
  description = "The effect of the policy (AuditIfNotExists or Disabled)"
  type        = string
  default     = "AuditIfNotExists"

  validation {
    condition     = contains(["AuditIfNotExists", "Disabled"], var.policy_effect)
    error_message = "The policy_effect must be one of: AuditIfNotExists or Disabled."
  }
}

variable "exempted_function_apps" {
  description = "List of Function App names that are exempt from this policy"
  type        = list(string)
  default     = []
}

variable "exempted_resource_groups" {
  description = "List of resource group names that are exempt from this policy"
  type        = list(string)
  default     = []
}
