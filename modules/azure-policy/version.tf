terraform {
  required_version = ">= 1.13.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.45.0"
    }
  }
}
