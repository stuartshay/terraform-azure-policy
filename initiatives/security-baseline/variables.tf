# Variables for Security Baseline Initiative

variable "management_group_id" {
  description = "The Azure management group ID where the initiative will be created"
  type        = string
  default     = null
  validation {
    condition     = var.management_group_id == null || can(regex("^[a-zA-Z0-9-_]+$", var.management_group_id))
    error_message = "The management_group_id must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "create_assignment" {
  description = "Whether to create a policy set assignment"
  type        = bool
  default     = true
}

variable "assignment_name" {
  description = "Name for the policy set assignment"
  type        = string
  default     = "security-baseline-assignment"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,64}$", var.assignment_name))
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
  default     = "Security Baseline Initiative Assignment"
}

variable "assignment_description" {
  description = "Description for the policy set assignment"
  type        = string
  default     = "This assignment enforces the security baseline initiative across the specified scope."
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

# Policy-specific variables
variable "storage_policy_effect" {
  description = "The effect for storage policies (Audit, Deny, or Disabled)"
  type        = string
  default     = "Audit"
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.storage_policy_effect)
    error_message = "Storage policy effect must be one of: Audit, Deny, Disabled."
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

variable "function_app_policy_effect" {
  description = "The effect for Function App policies (Audit, Deny, or Disabled)"
  type        = string
  default     = "Audit"
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.function_app_policy_effect)
    error_message = "Function App policy effect must be one of: Audit, Deny, Disabled."
  }
}

# Exemption variables
variable "exempted_subnets" {
  description = "List of subnet names that are exempt from NSG requirements"
  type        = list(string)
  default = [
    "GatewaySubnet",
    "AzureFirewallSubnet",
    "AzureFirewallManagementSubnet",
    "RouteServerSubnet",
    "AzureBastionSubnet"
  ]
}

variable "exempted_function_apps" {
  description = "List of Function App names that are exempt from HTTPS-only policy"
  type        = list(string)
  default     = []
}

variable "exempted_resource_groups" {
  description = "List of resource group names that are exempt from Function App policies"
  type        = list(string)
  default     = []
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
