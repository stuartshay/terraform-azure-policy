# Variables for Azure Policies Main Deployment

variable "subscription_id" {
  description = "The Azure subscription ID where policies will be deployed"
  type        = string
  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "The subscription_id must be a valid GUID format."
  }
}

variable "management_group_id" {
  description = "The Azure management group ID where policy definitions will be created (optional)"
  type        = string
  default     = null
}

variable "create_assignments" {
  description = "Whether to create policy assignments"
  type        = bool
  default     = true
}

variable "assignment_scope_id" {
  description = "The scope ID for policy assignments (resource group ID)"
  type        = string
  validation {
    condition     = can(regex("^/subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/resourceGroups/[a-zA-Z0-9-_]+$", var.assignment_scope_id))
    error_message = "The assignment_scope_id must be a valid resource group scope."
  }
}

variable "assignment_location" {
  description = "Location for policy assignments (required for system-assigned identity)"
  type        = string
  default     = "East US"
}

variable "storage_policy_effect" {
  description = "The effect for storage policies (Audit, Deny, or Disabled)"
  type        = string
  default     = "Audit"
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.storage_policy_effect)
    error_message = "Storage policy effect must be one of: Audit, Deny, Disabled."
  }
}

variable "storage_softdelete_policy_effect" {
  description = "The effect for storage soft delete policy (Audit, Deny, or Disabled)"
  type        = string
  default     = "Audit"
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.storage_softdelete_policy_effect)
    error_message = "Storage soft delete policy effect must be one of: Audit, Deny, Disabled."
  }
}

variable "storage_softdelete_retention_days" {
  description = "Minimum number of days for soft delete retention"
  type        = number
  default     = 7
  validation {
    condition     = var.storage_softdelete_retention_days >= 1 && var.storage_softdelete_retention_days <= 365
    error_message = "Storage soft delete retention days must be between 1 and 365."
  }
}

variable "network_policy_effect" {
  description = "The effect for network policies (Audit, Deny, or Disabled)"
  type        = string
  default     = "Audit"
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.network_policy_effect)
    error_message = "Network policy effect must be one of: Audit, Deny, Disabled."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "sandbox"
}

variable "owner" {
  description = "Owner of the policies"
  type        = string
  default     = "Policy-Team"
}
