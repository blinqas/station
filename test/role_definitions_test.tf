module "station_role_definitions" {
  depends_on = [tfe_project.test]
  source     = "./.."

  tfe = {
    project_name          = tfe_project.test.name
    organization_name     = data.tfe_organization.test.name
    workspace_description = "This workspace contains groups_tests from https://github.com/blinqas/station.git"
    workspace_name        = "station-tests-role_definitions"
  }

  role_definitions = {
    minimum = {
      name  = "Minimum Custom Role provisioned with Station"
      scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
    }

    maximum = {
      name              = "Maximum Custom Role provisioned with Station"
      scope             = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
      description       = "This role was provisioned with Station"
      assignable_scopes = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
      permissions = {
        actions          = ["Microsoft.Resources/subscriptions/resourceGroups/read", "Microsoft.Compute/virtualMachines/start/action"]
        data_actions     = ["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"]
        not_actions      = ["Microsoft.Compute/virtualMachines/delete"]
        not_data_actions = ["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete"]
      }
    }
  }
}

