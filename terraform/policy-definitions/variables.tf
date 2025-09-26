# Variables for Azure Policy Terraform Configuration

variable "subcription_id" {
  description = "The Azure subscription ID where the policy will be deployed (can be GUID or full path)"
  type        = string
  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subcription_id)) || can(regex("^/subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subcription_id))
    error_message = "The subscription_id must be a valid GUID format or full subscription path (/subscriptions/guid)."
  }
}

variable "mangement_group_id" {
  description = "The Azure management group ID where the policy definition will be created"
  type        = string
  default     = null
  validation {
    condition     = var.mangement_group_id == null || can(regex("^[a-zA-Z0-9-_]+$", var.mangement_group_id))
    error_message = "The management_group_id must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "scope_id" {
  description = "The scope ID for policy assignment (subscription, management group, or resource group)"
  type        = string
  validation {
    condition     = can(regex("^(/subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(/resourceGroups/[a-zA-Z0-9-_]+)?|/providers/Microsoft.Management/managementGroups/.+)$", var.scope_id))
    error_message = "The scope_id must be a valid subscription, resource group, or management group scope."
  }
}

variable "policy_assignment_name" {
  description = "Name for the policy assignment"
  type        = string
  default     = "deny-storage-public-access-assignment"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,64}$", var.policy_assignment_name))
    error_message = "Policy assignment name must be 1-64 characters and contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "policy_assignment_display_name" {
  description = "Display name for the policy assignment"
  type        = string
  default     = "Deny Storage Account Public Access Assignment"
}

variable "policy_assignment_description" {
  description = "Description for the policy assignment"
  type        = string
  default     = "This assignment enforces the policy to deny storage accounts with public access enabled."
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

variable "exempted_resource_groups" {
  description = "List of resource groups that are exempt from this policy"
  type        = list(string)
  default     = []
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
