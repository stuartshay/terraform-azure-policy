# Variables for the Azure Policy Initiative module

variable "initiative_name" {
  description = "Name of the policy initiative (policy set)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,64}$", var.initiative_name))
    error_message = "Initiative name must be 1-64 characters and contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "initiative_display_name" {
  description = "Display name of the policy initiative"
  type        = string
}

variable "initiative_description" {
  description = "Description of the policy initiative"
  type        = string
}

variable "category" {
  description = "Category for the policy initiative (e.g., Security, Compliance, Cost Management)"
  type        = string
  default     = "General"
}

variable "management_group_id" {
  description = "The Azure management group ID where the initiative will be created"
  type        = string
  default     = null
  validation {
    condition     = var.management_group_id == null || can(regex("^[a-zA-Z0-9-_]+$", var.management_group_id))
    error_message = "The management_group_id must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "policy_definitions" {
  description = "List of policy definitions to include in the initiative"
  type = list(object({
    policy_definition_id = string
    reference_id         = string
    parameters           = map(any)
  }))
}

variable "initiative_parameters" {
  description = "Parameters for the policy initiative"
  type        = map(any)
  default     = null
}

variable "metadata" {
  description = "Additional metadata for the policy initiative"
  type        = map(string)
  default     = {}
}

variable "create_assignment" {
  description = "Whether to create a policy set assignment"
  type        = bool
  default     = true
}

variable "assignment_name" {
  description = "Name for the policy set assignment"
  type        = string
  default     = null
  validation {
    condition     = var.assignment_name == null || can(regex("^[a-zA-Z0-9-_]{1,64}$", var.assignment_name))
    error_message = "Assignment name must be 1-64 characters and contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "assignment_scope_id" {
  description = "The scope ID for policy set assignment (resource group ID)"
  type        = string
  default     = null
  validation {
    condition     = var.assignment_scope_id == null || can(regex("^/subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/resourceGroups/[a-zA-Z0-9-_]+$", var.assignment_scope_id))
    error_message = "The assignment_scope_id must be a valid resource group scope."
  }
}

variable "assignment_display_name" {
  description = "Display name for the policy set assignment"
  type        = string
  default     = null
}

variable "assignment_description" {
  description = "Description for the policy set assignment"
  type        = string
  default     = null
}

variable "assignment_location" {
  description = "Location for the policy set assignment (required for system-assigned identity)"
  type        = string
  default     = "East US"
}

variable "assignment_parameters" {
  description = "Parameters for the policy set assignment"
  type        = map(any)
  default     = null
}

variable "enforcement_mode" {
  description = "Whether to enforce the policy set assignment"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "sandbox"
}

variable "owner" {
  description = "Owner of the policy initiative"
  type        = string
  default     = "Policy-Team"
}
