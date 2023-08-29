terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.41.0"
    }
  }
}

data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}
