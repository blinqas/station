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
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 18.0"
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

provider "azurerm" {
  features {}
  alias = "connectivity"
}

provider "azuread" {}

provider "gitlab" {}

provider "tfe" {}
