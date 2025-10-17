# Variables for enforce-naming-convention-storage policy

variable "management_group_id" {
  description = "The Azure management group ID where the policy definition will be created"
  type        = string
  default     = null
  validation {
    condition     = var.management_group_id == null || can(regex("^[a-zA-Z0-9-_]+$", var.management_group_id))
    error_message = "The management_group_id must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "create_assignment" {
  description = "Whether to create a policy assignment"
  type        = bool
  default     = true
}

variable "assignment_scope_id" {
  description = "The scope ID for policy assignment (resource group ID)"
  type        = string
  default     = null
  validation {
    condition     = var.assignment_scope_id == null || can(regex("^/subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/resourceGroups/[a-zA-Z0-9-_]+$", var.assignment_scope_id))
    error_message = "The assignment_scope_id must be a valid resource group scope."
  }
}

variable "policy_assignment_name" {
  description = "Name for the policy assignment"
  type        = string
  default     = "enforce-storage-naming-assignment"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,64}$", var.policy_assignment_name))
    error_message = "Policy assignment name must be 1-64 characters and contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "policy_assignment_display_name" {
  description = "Display name for the policy assignment"
  type        = string
  default     = "Enforce Storage Account Naming Convention Assignment"
}

variable "policy_assignment_description" {
  description = "Description for the policy assignment"
  type        = string
  default     = "This assignment enforces naming conventions for Azure Storage Accounts."
}

variable "assignment_location" {
  description = "Location for the policy assignment (required for system-assigned identity)"
  type        = string
  default     = "East US"
}

variable "policy_effect" {
  description = "The effect of the policy (Audit, Deny, or Disabled)"
  type        = string
  default     = "Audit"
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.policy_effect)
    error_message = "Policy effect must be one of: Audit, Deny, Disabled."
  }
}

variable "name_pattern" {
  description = "Regular expression pattern that storage account names must match"
  type        = string
  default     = "^st[a-z0-9]{4,22}$"
  validation {
    condition     = can(regex(var.name_pattern, "stdevweb001"))
    error_message = "The name_pattern must be a valid regular expression."
  }
}

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
