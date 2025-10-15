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

variable "storage_versioning_policy_effect" {
  description = "The effect for storage versioning policy (Audit, Deny, or Disabled)"
  type        = string
  default     = "Audit"
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.storage_versioning_policy_effect)
    error_message = "Storage versioning policy effect must be one of: Audit, Deny, Disabled."
  }
}

variable "storage_versioning_account_types" {
  description = "List of storage account types that require blob versioning"
  type        = list(string)
  default = [
    "Standard_LRS",
    "Standard_GRS",
    "Standard_RAGRS",
    "Standard_ZRS",
    "Standard_GZRS",
    "Standard_RAGZRS"
  ]
  validation {
    condition = alltrue([
      for type in var.storage_versioning_account_types : contains([
        "Standard_LRS", "Standard_GRS", "Standard_RAGRS", "Standard_ZRS",
        "Premium_LRS", "Premium_ZRS", "Standard_GZRS", "Standard_RAGZRS"
      ], type)
    ])
    error_message = "All storage account types must be valid Azure storage account SKUs."
  }
}

variable "storage_versioning_exempted_accounts" {
  description = "List of storage account names that are exempt from the versioning policy"
  type        = list(string)
  default     = []
}

variable "storage_https_policy_effect" {
  description = "The effect for storage HTTPS-only policy (Audit, Deny, or Disabled)"
  type        = string
  default     = "Audit"
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.storage_https_policy_effect)
    error_message = "Storage HTTPS policy effect must be one of: Audit, Deny, Disabled."
  }
}

variable "storage_https_account_types" {
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
      for type in var.storage_https_account_types : contains([
        "Standard_LRS", "Standard_GRS", "Standard_RAGRS", "Standard_ZRS",
        "Premium_LRS", "Premium_ZRS", "Standard_GZRS", "Standard_RAGZRS",
        "BlobStorage", "BlockBlobStorage", "FileStorage"
      ], type)
    ])
    error_message = "All storage account types must be valid Azure storage account SKUs."
  }
}

variable "storage_https_exempted_accounts" {
  description = "List of storage account names that are exempt from the HTTPS-only policy"
  type        = list(string)
  default     = []
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

variable "function_app_https_policy_effect" {
  description = "The effect for Function App HTTPS-only policy (Audit, Deny, or Disabled)"
  type        = string
  default     = "Audit"
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.function_app_https_policy_effect)
    error_message = "Function App HTTPS policy effect must be one of: Audit, Deny, Disabled."
  }
}

variable "function_app_https_exempted_apps" {
  description = "List of Function App names that are exempt from the HTTPS-only policy"
  type        = list(string)
  default     = []
}

variable "function_app_https_exempted_resource_groups" {
  description = "List of resource group names that are exempt from the Function App HTTPS-only policy"
  type        = list(string)
  default     = []
}

variable "app_service_policy_effect" {
  description = "The effect for App Service policies (Audit, Deny, or Disabled)"
  type        = string
  default     = "Audit"
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.app_service_policy_effect)
    error_message = "App Service policy effect must be one of: Audit, Deny, Disabled."
  }
}

variable "app_service_required_sku_tiers" {
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
      for tier in var.app_service_required_sku_tiers : contains([
        "PremiumV2", "PremiumV3", "PremiumV4", "IsolatedV2"
      ], tier)
    ])
    error_message = "All SKU tiers must be valid Azure App Service Plan tiers that support zone redundancy."
  }
}

variable "app_service_exempted_plans" {
  description = "List of App Service Plan names that are exempt from the zone redundancy policy"
  type        = list(string)
  default     = []
}

variable "app_service_minimum_instance_count" {
  description = "Minimum number of instances required for zone redundancy (must be 2 or more)"
  type        = number
  default     = 2
  validation {
    condition     = var.app_service_minimum_instance_count >= 2
    error_message = "The minimum instance count must be 2 or more for zone redundancy."
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
