terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0"
    }
    github = {
      source  = "integrations/github"
      version = "~>6.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~>0.65"
    }
  }
   cloud {}
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

provider "github" {
  owner = var.github_owner
  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id
    pem_file        = base64decode(var.github_app_pem_file)
  }
}

provider "tfe" {}
