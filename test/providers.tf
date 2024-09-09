terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.1"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.45"
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