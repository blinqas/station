terraform {
  required_version = "~> 1.12"
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~>5.0"
      configuration_aliases = [azurerm.connectivity]
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.6"
    }
  }
}
