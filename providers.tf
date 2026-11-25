terraform {
  required_version = "~> 1.12"
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~>4.65"
      configuration_aliases = [azurerm.connectivity]
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0"
    }

    msgraph = {
      source  = "microsoft/msgraph"
      version = "~> 0.6.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.6"
    }
  }
}
