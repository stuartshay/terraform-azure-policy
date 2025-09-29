variable "policy_name" {
  description = "The name of the Azure Policy Definition for denying VNET external DNS"
  type        = string
  default     = "deny-vnet-external-dns"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,64}$", var.policy_name))
    error_message = "Policy name must be 1-64 characters and can only contain letters, numbers, hyphens, and underscores."
  }
}

variable "policy_display_name" {
  description = "The display name of the Azure Policy Definition for denying VNET external DNS"
  type        = string
  default     = "Deny VNET External DNS"

  validation {
    condition     = length(var.policy_display_name) <= 128
    error_message = "Policy display name must be 128 characters or less."
  }
}

variable "policy_description" {
  description = "The description of the Azure Policy Definition for denying VNET external DNS"
  type        = string
  default     = "This policy ensures that Virtual Networks use DNS servers within their address space rather than external DNS servers to improve security and reduce dependencies on external services. Corresponds to Checkov policy CKV_AZURE_183."

  validation {
    condition     = length(var.policy_description) <= 512
    error_message = "Policy description must be 512 characters or less."
  }
}

variable "policy_category" {
  description = "The category of the Azure Policy Definition"
  type        = string
  default     = "Network"

  validation {
    condition = contains([
      "API Management", "App Configuration", "App Platform", "App Service", "Automation",
      "Backup", "Batch", "Bot Service", "Cache", "CDN", "Cognitive Services", "Compute",
      "Container Instance", "Container Registry", "Cosmos DB", "Custom Provider",
      "Data Box", "Data Factory", "Data Lake", "Database", "Event Grid", "Event Hub",
      "General", "Guest Configuration", "HDInsight", "Internet of Things", "Key Vault",
      "Kubernetes", "Logic Apps", "Machine Learning", "Managed Application",
      "Media Services", "Migrate", "Monitoring", "Network", "Portal", "Redis Cache",
      "Resource Manager", "Search", "Security Center", "Service Bus", "Service Fabric",
      "SignalR", "SQL", "Storage", "Stream Analytics", "Tags", "VM Image Builder",
      "Web PubSub"
    ], var.policy_category)
    error_message = "Policy category must be a valid Azure Policy category."
  }
}

variable "policy_version" {
  description = "The version of the Azure Policy Definition"
  type        = string
  default     = "1.0.0"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.policy_version))
    error_message = "Policy version must follow semantic versioning format (e.g., 1.0.0)."
  }
}

variable "management_group_id" {
  description = "The management group ID where the policy definition will be created"
  type        = string
  default     = null
}
