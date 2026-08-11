terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0"
    }

    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.48"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
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

provider "github" {
  #GITHUB_TOKEN enviorment varible has to be set for auth
  #GITHUB_OWNER enviorment varible has to be set to select correct org
}
