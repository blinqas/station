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

  user_assigned_identities = {
    "container-app-x" = {
      name = "id-ca-x"
      role_assignments = [
        "GroupMember.Read.All",
        "User.Read.All"
      ]
    }
  }

  federated_identity_credential_config = {
    "plan" = {
      display_name = "station-example-tfc-plan"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://example.com"
      subject      = "repo:kimfy/station-deployments"
    },
    "apply" = {
      display_name = "station-example-tfc-apply"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://example.com"
      subject      = "repo:station-deployments"
  } }

  tags = {
    "repoUrl" = "https://github.com/kimfy/station.git"
    "owner"   = "platform-engineer"
  }

  groups = {
    "dynamic" = {
      settings = {
        display_name     = "admins"
        owners           = [data.azurerm_client_config.current.object_id]
        security_enabled = true
        types            = ["DynamicMembership"]
        dynamic_membership = {
          "JuniorDevOpsNoAccess" = {
            enabled = true
            rule    = "user.department -eq \"Sales\""
          }
        }
      }
    },
    "static" = {
      settings = {
        display_name     = "static"
        owners           = [data.azurerm_client_config.current.object_id]
        security_enabled = true
        members          = [data.azurerm_client_config.current.object_id]
      }
    }
  }

  applications = {
    "web" = {
      client_config = data.azurerm_client_config.current
      user_type     = "null"

      settings = {
        application_name = "station-example-web"

        web = {
          redirect_uris = ["http://localhost:7007/api/auth/microsoft/handler/frame"]

          implicit_grant = {
            access_token_issuance_enabled = true
            id_token_issuance_enabled     = true
          }
        }
      }

    },
    "backstage-azure-integration" = {
      // Caller is added as owner on the application.
      client_config = data.azurerm_client_config.current
      // Unsure what this is used for.
      user_type = "null"

      // See aztfmod's docs (see variables.tf file for link)
      settings = {
        application_name = "backstage-azure-integration"
      }

      // required_resource_access: see https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application
      azuread_api_permissions = [
        {
          resource_app_id = "00000003-0000-0000-c000-000000000000"
          resource_access = [
            {
              id   = "98830695-27a2-44f7-8c18-0c3ebc9698f6" # GroupMember.Read.All
              type = "Role"
            },
            {
              id   = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
              type = "Role"
            }
          ]
        }
      ]
    }
  }
}

data "azurerm_client_config" "current" {}

output "applications" {
  value = module.station.applications
}

output "workload_service_principal_object_id" {
  value = module.station.workload_service_principal_object_id
}

output "user_assigned_identities" {
  value = module.station.user_assigned_identities
}
