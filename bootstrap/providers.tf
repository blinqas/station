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

    github = {
      source  = "integrations/github"
      version = "~> 5.38"
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