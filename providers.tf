terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.45"
    }
  }
}

