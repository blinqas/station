terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.45"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.15"
    }
  }
}

