terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.49"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.36"
    }

    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.48"
    }
  }

  cloud {
    organization = var.tfc_organization
    hostname     = var.tfc_hostname
    workspaces {
      name = var.tfc_workspace
    }
  }
}

provider "azurerm" {
  features {

  }
}

provider "tfe" {
  # Configuration options
}

