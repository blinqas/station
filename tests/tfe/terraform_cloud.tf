terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.41.0"
    }

    tfe = {
      # https://registry.terraform.io/providers/hashicorp/tfe/latest/docs
      source  = "hashicorp/tfe"
      version = "~> 0.48.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

locals {
  tfe_tests = {
    test = {
      environment_name   = "test"
      tfe = {
        create_project = true
      }
    },
  }
}

module "station-tfe" {
  for_each         = local.tfe_tests
  source           = "../../"
  environment_name = each.value.environment_name
# Step 1: Create GitHub/BitBucket repositories

# Step 2: Federated Identity Credential

# Step 3: Terraform Cloud integration

  #  federated_identity_credential_config = {
  #    "plan" = {
  #      display_name = "plan"
  #      audiences    = ["api://AzureADTokenExchange"]
  #      issuer       = "https://app.terraform.io"
  #      subject      = "organization:managed-devops:project:Station Development:workspace:Test:run_phase:plan"
  #    },
  #    "apply" = {
  #      display_name = "apply"
  #      audiences    = ["api://AzureADTokenExchange"]
  #      issuer       = "https://app.terraform.io"
  #      subject      = "organization:managed-devops:project:Station Development:workspace:Test:run_phase:apply"
  #    }
  #  }

  tfe = {
    project_name          = local.tfe_projects.tfe_tests.project_name
    workspace_name        = "tfe-${each.value.environment_name}"
    workspace_description = "This workspace is for testing Station's TFE integration"
    create_project        = each.value.tfe.create_project
  }

  tags = {
    "owner" = "Kim Iversen"
  }
  depends_on = [
    tfe_project.projects
  ]
}
