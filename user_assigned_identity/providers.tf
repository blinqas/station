terraform {
  required_version = "~> 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.15"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.13"
    }
  }
}

