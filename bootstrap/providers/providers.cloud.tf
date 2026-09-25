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
  owner = try(var.config.github.owner, null)

  dynamic "app_auth" {
    for_each = local.use_github ? [1] : []

    content {
      id              = var.config.github.provider.id
      installation_id = var.config.github.provider.installation_id
      pem_file        = base64decode(var.github_app_pem_file)
    }
  }
}

provider "gitlab" {
  token            = local.use_github ? "inactive-provider" : var.gitlab_token
  early_auth_check = !local.use_github
}

provider "tfe" {
  organization = var.config.terraform_cloud.organization_name
  token        = var.tfe_token
}
