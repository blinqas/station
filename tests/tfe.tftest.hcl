provider "tfe" {}
provider "azurerm" {
  features { }
}

variables {
    tfe = {
        project_name                         = "tests_tfe"
        organization_name                    = "blinq-west-lab"
        workspace_name                       = "tfe_test"
        workspace_description                = "Workspace description"
        create_federated_identity_credential = true # Configures Federated Credentials on the workload identity for plan and apply phases.
        
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

         workspace_vars = {
            tfe_test_var_1 = {
                value       = "test"
                category    = "terraform"
                description = "Test workspace var from station tests"
                hcl         = false
                sensitive   = false
            },
            tfe_test_var_2 = {
                value       = "tfe_test_var_2_test_value"
                category    = "terraform"
                description = "Test workspace var from station tests. This should be sensitive"
                hcl         = false
                sensitive   = true
            },
            tfe_test_var_3 = {
                value       = "{\"key\": \"value\", \"another_key\": \"another_value\"}"
                category    = "terraform"
                description = "Test workspace var from station tests. Testing hcl format"
                hcl         = true
                sensitive   = false
            }
        }
    }
}

run "setup_create_tfc_test_project" {
    variables {
        project_name                         = "tests_tfe"
        organization_name                    = "blinq-west-lab"
    }
    module {
        source = "./tests/setup-tfe-project"
    }
}


run "tfe_create_workspace" {

    module {
        source = "./"
    }

    assert {
        condition     = module.station-tfe.workspace.name == "tfe_test"
        error_message = "The workspace name does NOT match the input"
    }

    assert {
        condition     = module.station-tfe.workspace.description == "Workspace description"
        error_message = "The workspace description does NOT match the input"
    }
}

run "tfe_workspace_varaibles" {
    module {
        source = "./"
    }

    # Assertions for tfe_test_env_var_1
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_env_var_1.value == "test_env_var"
        error_message = "The workspace_env_vars.tfe_test_env_var_1 had not the expected value"
    }
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_env_var_1.sensitive == false
        error_message = "The workspace_env_vars.tfe_test_env_var_1 was set as sensitive"
    }
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_env_var_1.category == "env"
        error_message = "The workspace_env_vars.tfe_test_env_var_1 was NOT set as type env"
    }

    # Assertions for tfe_test_env_var_2
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_env_var_2.value == ""
        error_message = "We could read the variable and this should not work when it's marked as sensitive"
    }
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_env_var_2.sensitive == true
        error_message = "The workspace_env_vars.tfe_test_env_var_2 was not set as sensitive"
    }
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_env_var_2.category == "env"
        error_message = "The workspace_env_vars.tfe_test_env_var_2 was not of type env"
    }

    # Assertions for tfe_test_var_1
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_var_1.value == "test"
        error_message = "The workspace_vars.tfe_test_var_1 had not the expected value"
    }
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_var_1.sensitive == false
        error_message = "The workspace_vars.tfe_test_var_1 was set as sensitive"
    }

    # Assertions for tfe_test_var_2
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_var_2.value == ""
        error_message = "The workspace_vars.tfe_test_var_2 had not the expected value when sensitive"
    }
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_var_2.sensitive == true
        error_message = "The workspace_vars.tfe_test_var_2 was not set as sensitive"
    }
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_var_2.hcl == false
        error_message = "The workspace_vars.tfe_test_var_2 was set as hcl, but expected hcl == false"
    }

    # Assertions for tfe_test_var_3
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_var_3.value == "{\"key\": \"value\", \"another_key\": \"another_value\"}"
        error_message = "The workspace_vars.tfe_test_var_3 had not the expected value"
    }
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_var_3.sensitive == false
        error_message = "The workspace_vars.tfe_test_var_3 was set as sensitive"
    }
    assert {
        condition     = module.station-tfe.workspace_variables.tfe_test_var_3.hcl == true
        error_message = "The workspace_vars.tfe_test_var_3 was NOT set as hcl"
    }
}

