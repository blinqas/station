provider "tfe" {}

provider "azuread" {}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias = "connectivity"
  features {}
}

run "bootstrap_create_tfc_test_project" {
  variables {
    tfc_project_name = "tests_station_uai"
  }
  module {
    source = "./tests/setup-tfe-project"
  }
}

run "bootstrap_uai" {
  variables {
    group_display_name = "station-uai-test-group"
  }
  module {
    source = "./tests/setup-uai"
  }
}

run "setup" {
  module {
    source = "./tests/setup-common"
  }
}

variables {
  tfe = {
    project = {
      id   = "# Overridden"
      name = "tests_station_uai"
    }
    organization_name     = "blinq-west-lab"
    workspace_name        = "station-tests-uai_tests"
    workspace_description = "Test for station-uai module"
    workspace_settings = {
      execution_mode = "remote"
    }
  }

  user_assigned_identities = {
    minimum = {
      name = "uai-01"
    },
    maximum = {
      name     = "uai-02"
      location = "norwayeast"
    }
  }
}

run "user_assigned_identity" {
  variables {
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
    condition = alltrue([
      module.user_assigned_identities["minimum"].name == var.user_assigned_identities.minimum.name,
      module.user_assigned_identities["maximum"].name == var.user_assigned_identities.maximum.name
    ])
    error_message = "The name of the user-assigned identities does not match the expected values."
  }

  assert {
    condition = alltrue([
      module.user_assigned_identities["minimum"].location == azurerm_resource_group.workload.location, //Defaults to RG location,
      module.user_assigned_identities["maximum"].location == var.user_assigned_identities.maximum.location
    ])
    error_message = "The location of the user-assigned identities does not match the expected values."
  }
}

run "app_role_assignments" {
  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    user_assigned_identities = merge(var.user_assigned_identities, {
      maximum = merge(var.user_assigned_identities.maximum, {
        app_role_assignments = {
          "User.Read.All" = {
            app_role_id        = run.setup.azuread_service_principal.msgraph.app_role_ids["User.Read.All"]
            resource_object_id = run.setup.azuread_service_principal.msgraph.object_id
          }
        }
      })
    })
  }

  module {
    source = "./"
  }

  // Maximum
  assert {
    condition     = module.user_assigned_identities["maximum"].app_role_assignments["User.Read.All"].app_role_id == run.setup.azuread_service_principal.msgraph.app_role_ids["User.Read.All"]
    error_message = "The app role assignments for the user-assigned identity do not match."
  }

  // Minimum
  assert {
    condition     = length(module.user_assigned_identities["minimum"].app_role_assignments) == 0
    error_message = "The app role assignments for the user-assigned identity should be null when `var.user_assigned_identities[*].app_role_assignments` is not configured."
  }
}

run "role_assignments" {
  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    user_assigned_identities = merge(var.user_assigned_identities, {
      maximum = merge(var.user_assigned_identities.maximum, {
        role_assignments = {
          subscription_reader = {
            role_definition_name = "Reader"
            scope                = run.bootstrap_uai.current_subscription.id
          }
        }
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition     = try(length(module.user_assigned_identities["minimum"].identity.role_assignments), 0) == 0
    error_message = "The minimum user-assigned identity should not have any role assignments."
  }

  assert {
    condition = alltrue([
      module.user_assigned_identities["maximum"].role_assignments["subscription_reader"].role_definition_name == var.user_assigned_identities.maximum.role_assignments.subscription_reader.role_definition_name,
      module.user_assigned_identities["maximum"].role_assignments["subscription_reader"].scope == var.user_assigned_identities.maximum.role_assignments.subscription_reader.scope
    ])
    error_message = "The role assignments for the user-assigned identity do not match."
  }
}

run "group_memberships" {
  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    user_assigned_identities = merge(var.user_assigned_identities, {
      maximum = merge(var.user_assigned_identities.maximum, {
        group_memberships = {
          static = run.bootstrap_uai.azuread_group.object_id
        }
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition     = module.user_assigned_identities["maximum"].group_memberships["static"].group_object_id == run.bootstrap_uai.azuread_group.object_id
    error_message = "The user-assigned identity was not added to the correct static group."
  }
}
