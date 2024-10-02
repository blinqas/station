terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.8, < 5"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~>0.48"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {

  }
}

provider "azuread" {

}

provider "tfe" {}