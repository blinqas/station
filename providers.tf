terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.8, < 5"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0"
    }
  }
}

