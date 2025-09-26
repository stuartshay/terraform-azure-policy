# Backend configuration for Terraform state
# This configuration stores the Terraform state in Azure Storage

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-azure-policy-testing"
    storage_account_name = "staazurepolicytesting"
    container_name       = "state-files-sandbox"
    key                  = "storage-policy/terraform.tfstate"
  }
}
