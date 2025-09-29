# CKV_AZURE_183: Ensure that VNET uses local DNS addresses
# This policy ensures Virtual Networks use DNS servers within their address space
# rather than external DNS servers to improve security and reduce dependencies

resource "azurerm_policy_definition" "deny_vnet_external_dns" {
  name         = var.policy_name
  policy_type  = "Custom"
  mode         = "All"
  display_name = var.policy_display_name
  description  = var.policy_description

  metadata = jsonencode({
    category   = var.policy_category
    version    = var.policy_version
    preview    = false
    deprecated = false
    checkov_id = "CKV_AZURE_183"
    source     = "https://github.com/bridgecrewio/checkov/blob/main/checkov/terraform/checks/resource/azure/VnetLocalDNS.py"
  })

  policy_rule = jsonencode(jsondecode(file("${path.module}/rule.json")).properties.policyRule)

  parameters = jsonencode(jsondecode(file("${path.module}/rule.json")).properties.parameters)
}
