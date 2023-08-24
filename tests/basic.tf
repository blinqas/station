data "azurerm_client_config" "current" {}

module "station-basic" {
  source                              = "../"
  environment_name                    = "dev"
  role_definition_name_on_workload_rg = "Owner"

  user_assigned_identities = {
    "station_test" = {
      name = "uai-station-test"
      role_assignments = [
        "User.Read.All"
      ]
    }
  }

  # Federated Identity Credential
  # This is attached to the workload service principal
  federated_identity_credential_config = {
    "apply" = {
      display_name = "fic-station-test"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://token.actions.githubusercontent.com"
      subject      = "repo:kimfy/station:environment:DoesNotExist"
    }
  }

  tags = {
    "owner" = "DevOps kim"
  }

  groups = {
    "dynamic" = {
      settings = {
        display_name     = "Station Testers"
        owners           = [data.azurerm_client_config.current.object_id]
        security_enabled = true
        types            = ["DynamicMembership"]
        dynamic_membership = {
          "station-testers" = {
            enabled = true
            rule    = "user.department -eq \"Station Testers\""
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
}
