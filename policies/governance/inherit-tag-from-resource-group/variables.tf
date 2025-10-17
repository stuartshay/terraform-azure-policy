# Variables for inherit-tag-from-resource-group policy

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
  default     = "inherit-tags-assignment"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,64}$", var.policy_assignment_name))
    error_message = "Policy assignment name must be 1-64 characters and contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "policy_assignment_display_name" {
  description = "Display name for the policy assignment"
  type        = string
  default     = "Inherit Tags from Resource Group Assignment"
}

variable "policy_assignment_description" {
  description = "Description for the policy assignment"
  type        = string
  default     = "This assignment automatically inherits tags from resource groups to child resources."
}

variable "assignment_location" {
  description = "Location for the policy assignment (required for system-assigned identity)"
  type        = string
  default     = "East US"
}

variable "tag_name" {
  description = "The name of the tag to inherit from resource group"
  type        = string
  default     = "Environment"
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
