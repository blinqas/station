module "station_tfe_test" {
  depends_on = [tfe_project.test]
  source     = "./.."

  tfe = {
    project_name                         = tfe_project.test.name
    organization_name                    = data.tfe_organization.test.name
    workspace_description                = "This workspace contains groups_tests from https://github.com/blinqas/station.git"
    workspace_name                       = "station-tests-tfe"
    create_federated_identity_credential = true # Configures Federated Credentials on the workload identity for plan and apply phases.

    #vcs_repo has not yet been added

    # Passses the output of the modules to the workloads TFC variables.
    module_outputs_to_workspace_var = {
      role_definitions         = true
      user_assigned_identities = true
      groups                   = true
      applications             = true
      resource_groups          = true
    }

    #Creates environment variables in the terraform workspace
    workspace_env_vars = {
      tfe_test_env_var_1 = {
        value       = "test_env_var"
        category    = "env"
        description = "Test non sensitive env var"
      }
      tfe_test_env_var_2 = {
        value       = "test_env_var"
        category    = "env"
        description = "Test sensitive env var"
        sensitive   = true
      }
    }

    #Creates terraform variables in the terraform workspace
    workspace_vars = {
      tfe_test_var_1 = {
        value       = "test"
        category    = "terraform"
        description = "Test workspace var from station tests"
        hcl         = false
        sensitive   = false
      },
      tfe_test_var_2 = {
        value       = "test"
        category    = "terraform"
        description = "Test workspace var from station tests. This should be sensitive"
        hcl         = false
        sensitive   = true
      }
      tfe_test_var_3 = {
        value       = "{\"key\": \"value\", \"another_key\": \"another_value\"}"
        category    = "terraform"
        description = "Test workspace var from station tests. Testing hcl format"
        hcl         = true
        sensitive   = false
      }
    }
  }

  # Adding the different modules to test the tfe.module_outputs_to_workspace_var
  applications = {
    minimum_tfe = {
      display_name = "Station test tfe: minimum"
    }
  }
  groups = {
    minimal_tfe = {
      display_name     = "Station test tfe: groups minimal"
      security_enabled = true
    }
  }
  role_definitions = {
    minimum_tfe = {
      name  = "Minimum Custom Role for tfe test"
      scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
    }
  }
  user_assigned_identities = {
    minimum_tfe = {
      name = "tfe-test-01"
    }
  }
  resource_groups = {
    test_rg = {
      name     = "station_tfe_test_rg",
      location = "norwayeast"
      tags     = tomap({ testkey1 = "testValue1", testkey2 = "testValue2" })
    }
  }
}

