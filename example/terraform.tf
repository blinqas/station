terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {
    
  }
}

module "station" {
  source = "../"

  environment_name                    = "dev"
  role_definition_name_on_workload_rg = "Owner"
  station_resource_group_name         = "rg-terraform-station"
  #federated_identity_credential_config = {
  #  create    = true
  #  audiences = ["api://AzureADTokenExchange"]
  #  issuer    = "https://token.actions.githubusercontent.com"
  #  subject   = "repo:kimfy/station:environment:dev"
  #}

  tags = {
    "repoUrl" = "https://github.com/kimfy/station.git"
    "owner"   = "platform-engineer"
  }

  applications = {
    "backstage-azure-integration" = {
      client_config = data.azurerm_client_config.current
      user_type = "null"

      settings = {
        application_name = "backstage-azure-integration"
      }

      #azuread_api_permissions = [
      #  {
      #    resource_app_id = "00000003-0000-0000-c000-000000000000"
      #    resource_access = [
      #      {
      #        id   = "98830695-27a2-44f7-8c18-0c3ebc9698f6" # GroupMember.Read.All
      #        type = "Role"
      #      },
      #      {
      #        id   = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
      #        type = "Role"
      #      }
      #    ]
      #  }
      #]
    }
  }
}

data "azurerm_client_config" "current" {}
