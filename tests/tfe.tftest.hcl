provider "tfe" {}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias = "connectivity"
  features {}
}

provider "azuread" {}

test {
  parallel = true
}

run "bootstrap_create_tfc_test_project" {
  variables {
    tfc_project_name = "tests_tfe"
  }
  module {
    source = "./tests/setup-tfe-project"
  }
}


variables {
  tfe = {
    project = {
      id   = "# Overridden"
      name = "tests_tfe"
    }
    organization_name     = "blinq-west-lab"
    workspace_name        = "tfe_test"
    workspace_description = "Workspace description for var.tfe"
    workspace_settings = {
      execution_mode = "remote"
      agent_pool_id  = null # Not adding this as it will require us to setup a private runner
    }

    workspace_vars = {
      #Test environment variables
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
      #Test terraform variables
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


run "tfe_create_workspace" {

  variables {
    // Insert the real project id from the generted tfe_project resource in setup-tfe-project (Test module)
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition     = module.station-tfe.workspace.name == "tfe_test"
    error_message = "The workspace name does NOT match the input"
  }

  assert {
    condition     = module.station-tfe.workspace.description == "Workspace description for var.tfe"
    error_message = "The workspace description does NOT match the input"
  }

  assert {
    condition     = module.station-tfe.workspace_settings[0].execution_mode == "remote"
    error_message = "The workspace execution mode does NOT match the input"
  }
}

run "tfe_workspace_variables" {
  variables {
    // Insert the real project id from the generted tfe_project resource in setup-tfe-project (Test module)
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })
  }

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

run "tfe_outputs_to_workspace_variables" {

  variables {
    // Insert the real project id from the generted tfe_project resource in setup-tfe-project (Test module)
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    applications = {
      minimum_tfe_test = {
        display_name = "Station test tfe: minimum"
      }
    }

    resource_groups = {
      test_rg = {
        name     = "station_tfe_test_rg",
        location = "norwayeast"
        tags = {
          testkey1 = "testValue1",
          testkey2 = "testValue2"
        }
      }
    }

    # Added to be able to test the passing of the created groups into the TFC workspace variables
    groups = {
      minimal_tfe_test = {
        display_name     = "Station test: groups minimal"
        security_enabled = true
      }
    }

    # Added to be able to test the passing of the created user_assigned_identities into the TFC workspace variables
    user_assigned_identities = {
      minimum_tfe = {
        name = "tfe-tests"
      }
    }
  }

  #This should output the the creat
  module {
    source = "./"
  }

  # Assertions for the workspace variable when applications are created
  assert {
    condition     = module.station-tfe.workspace_variables.applications.value != null
    error_message = "No applications where added to the workspace variables"
  }

  assert {
    # We have to parse the hcl string to get the variable as a terraform object 
    condition     = jsondecode(replace(module.station-tfe.workspace_variables.applications.value, "/(\\\"[^\"]+\\\") =/", "$1:"))["minimum_tfe_test"].display_name == var.applications["minimum_tfe_test"].display_name
    error_message = "The application name did not match the input variable"
  }

  assert {
    # We have to parse the hcl string to get the variable as a terraform object 
    condition     = jsondecode(replace(module.station-tfe.workspace_variables.applications.value, "/(\\\"[^\"]+\\\") =/", "$1:"))["minimum_tfe_test"].client_id != null
    error_message = "The application client_id is null"
  }

  assert {
    # We have to parse the hcl string to get the variable as a terraform object 
    condition     = jsondecode(replace(module.station-tfe.workspace_variables.applications.value, "/(\\\"[^\"]+\\\") =/", "$1:"))["minimum_tfe_test"].object_id != null
    error_message = "The application object_id is null"
  }

  assert {
    condition     = module.station-tfe.workspace_variables.applications.hcl == true
    error_message = "The application workspace variable is not of type hcl"
  }
  assert {
    condition     = module.station-tfe.workspace_variables.applications.category == "terraform"
    error_message = "The application workspace variable was NOT set as type terraform"
  }

  # Assertions for the output variable from the groups
  assert {
    condition     = module.station-tfe.workspace_variables.groups.value != null
    error_message = "The application output variable is empty."
  }
  assert {
    condition     = module.station-tfe.workspace_variables.groups.hcl == true
    error_message = "The application workspace variable is not of type hcl"
  }
  assert {
    condition     = module.station-tfe.workspace_variables.groups.category == "terraform"
    error_message = "The application workspace variable was NOT set as type terraform"
  }

  # Assertions for the output variable from the user_assigned_identities
  assert {
    condition     = module.station-tfe.workspace_variables.user_assigned_identities.value != null
    error_message = "The application output variable is empty."
  }
  assert {
    condition     = module.station-tfe.workspace_variables.user_assigned_identities.hcl == true
    error_message = "The application workspace variable is not of type hcl"
  }
  assert {
    condition     = module.station-tfe.workspace_variables.user_assigned_identities.category == "terraform"
    error_message = "The application workspace variable was NOT set as type terraform"
  }

  # Assertions for the output variable from the resource_groups
  assert {
    condition     = module.station-tfe.workspace_variables.resource_groups.value != null
    error_message = "The application output variable is empty."
  }
  assert {
    condition     = module.station-tfe.workspace_variables.resource_groups.hcl == true
    error_message = "The application workspace variable is not of type hcl"
  }
  assert {
    condition     = module.station-tfe.workspace_variables.resource_groups.category == "terraform"
    error_message = "The application workspace variable was NOT set as type terraform"
  }
}
