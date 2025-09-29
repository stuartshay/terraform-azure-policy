output "policy_id" {
  description = "The ID of the Azure Policy Definition for denying VNET external DNS"
  value       = azurerm_policy_definition.deny_vnet_external_dns.id
}

output "policy_name" {
  description = "The name of the Azure Policy Definition for denying VNET external DNS"
  value       = azurerm_policy_definition.deny_vnet_external_dns.name
}

output "policy_display_name" {
  description = "The display name of the Azure Policy Definition for denying VNET external DNS"
  value       = azurerm_policy_definition.deny_vnet_external_dns.display_name
}

output "policy_description" {
  description = "The description of the Azure Policy Definition for denying VNET external DNS"
  value       = azurerm_policy_definition.deny_vnet_external_dns.description
}

output "policy_metadata" {
  description = "The metadata of the Azure Policy Definition for denying VNET external DNS"
  value       = azurerm_policy_definition.deny_vnet_external_dns.metadata
}

output "checkov_id" {
  description = "The Checkov policy ID for security compliance tracking"
  value       = "CKV_AZURE_183"
}
