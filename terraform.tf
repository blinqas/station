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

    tfe = {
      # https://registry.terraform.io/providers/hashicorp/tfe/latest/docs
      source  = "hashicorp/tfe"
      version = "~> 0.48.0"
    }
  }
}

provider "azurerm" {
  features {

  }
}

data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}
