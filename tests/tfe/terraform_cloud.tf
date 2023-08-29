terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.71.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

module "station-tfe" {
  source                              = "../../"
  environment_name                    = "test"

  federated_identity_credential_config = {
    "plan" = {
      display_name = "plan"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://app.terraform.io"
      subject      = "organization:managed-devops:project:Station Development:workspace:Test:run_phase:plan"
    },
    "apply" = {
      display_name = "apply"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://app.terraform.io"
      subject      = "organization:managed-devops:project:Station Development:workspace:Test:run_phase:apply"
    }
  }

  tags = {
    "owner" = "Kim Iversen"
  }
}
