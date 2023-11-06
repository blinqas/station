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
      scope = data.azurerm_client_config.current.subscription_id
    }

    maximum = {
      name        = "Maximum Custom Role provisioned with Station"
      scope       = data.azurerm_client_config.current.subscription_id
      description = "This role was provisioned with Station"
      permissions = {
        # actions
        # not_actions
        # data_actions
        # not_data_actions
      }
    }
  }
}

