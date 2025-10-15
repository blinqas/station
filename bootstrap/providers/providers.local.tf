terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~>2.5"
    }
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
}

provider "azurerm" {
  features {}
  subscription_id                 = var.config.subscription_id
  resource_provider_registrations = "none"
}

provider "azurerm" {
  features {}
  subscription_id                 = var.config.subscription_id
  alias                           = "connectivity"
  resource_provider_registrations = "none"
}

provider "local" {
  # Configuration options
}

provider "github" {
  owner = var.config.github.owner
  app_auth {
    id              = var.config.github.provider.id
    installation_id = var.config.github.provider.installation_id
    pem_file        = base64decode(filebase64(var.config.github.pem_file_path))
  }
}

provider "tfe" {
  organization = var.config.terraform_cloud.organization_name
  token        = var.tfe_token
}
