# Variables for Function App HTTP Version Policy

variable "management_group_id" {
  description = "The management group ID for policy definition scope"
  type        = string
  default     = null
}

variable "create_assignment" {
  description = "Whether to create a policy assignment"
  type        = bool
  default     = false
}

variable "assignment_scope_id" {
  description = "The scope ID for policy assignment"
  type        = string
  default     = null
}

variable "policy_assignment_name" {
  description = "The name of the policy assignment"
  type        = string
  default     = "deny-function-app-http-version"
}

variable "policy_assignment_display_name" {
  description = "The display name of the policy assignment"
  type        = string
  default     = "Deny Function App Outdated HTTP Version"
}

variable "policy_assignment_description" {
  description = "The description of the policy assignment"
  type        = string
  default     = "This policy assignment denies Function Apps that do not use HTTP/2 to ensure optimal performance and security."
}

variable "assignment_location" {
  description = "The location for policy assignment (required for managed identity)"
  type        = string
  default     = null
}

variable "policy_effect" {
  description = "The effect of the policy (Audit, Deny, or Disabled)"
  type        = string
  default     = "Deny"
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.policy_effect)
    error_message = "Policy effect must be one of: Audit, Deny, Disabled."
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

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner name for tagging"
  type        = string
  default     = "platform-team"
}
