# Variables for the Storage HTTPS-Only Policy Module

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
  default     = "deny-storage-https-disabled-assignment"
}

variable "policy_assignment_display_name" {
  description = "Display name for the policy assignment"
  type        = string
  default     = "Deny Storage Account Without HTTPS-Only Traffic Assignment"
}

variable "policy_assignment_description" {
  description = "Description for the policy assignment"
  type        = string
  default     = "This assignment enforces the policy to deny storage accounts that do not have HTTPS-only traffic enabled."
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

variable "storage_account_types" {
  description = "List of storage account types that require HTTPS-only traffic"
  type        = list(string)
  default = [
    "Standard_LRS",
    "Standard_GRS",
    "Standard_RAGRS",
    "Standard_ZRS",
    "Standard_GZRS",
    "Standard_RAGZRS",
    "Premium_LRS",
    "Premium_ZRS",
    "BlobStorage",
    "BlockBlobStorage",
    "FileStorage"
  ]

  validation {
    condition = alltrue([
      for type in var.storage_account_types : contains([
        "Standard_LRS", "Standard_GRS", "Standard_RAGRS", "Standard_ZRS",
        "Premium_LRS", "Premium_ZRS", "Standard_GZRS", "Standard_RAGZRS",
        "BlobStorage", "BlockBlobStorage", "FileStorage"
      ], type)
    ])
    error_message = "All storage account types must be valid Azure storage account SKUs."
  }
}

variable "exempted_storage_accounts" {
  description = "List of storage account names that are exempt from this policy"
  type        = list(string)
  default     = []
}
