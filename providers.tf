terraform {
  required_version = "~> 1.9"
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~>4.15"
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

