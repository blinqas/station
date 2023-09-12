terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.49"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.36"
    }
  }
}

data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}
