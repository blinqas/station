terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.49.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "2.36.0"
    }
  }
}

provider "azurerm" {
  features {

  }
}

data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}