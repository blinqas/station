provider "tfe" {}
provider "azuread" {}
provider "azurerm" {
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
      name                 = "uai-02"
      location             = "norwayeast"
      app_role_assignments = ["User.Read.All"]
      group_memberships = {
        static = "This should be overwritten"
      }
      role_assignments = {
        subscription_reader = {
          role_definition_name = "Reader"
          scope                = "This should be overwritten"
        }
      }
    }
  }
}

run "station-uai-main" {
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
        },
        role_assignments = merge(var.user_assigned_identities.maximum.role_assignments, {
          subscription_reader = merge(var.user_assigned_identities.maximum.role_assignments.subscription_reader, {
            scope = run.bootstrap_uai.current_subscription.id
          })
        })
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition = alltrue([
      module.user_assigned_identities["minimum"].identity.name == var.user_assigned_identities.minimum.name,
      module.user_assigned_identities["maximum"].identity.name == var.user_assigned_identities.maximum.name
    ])
    error_message = "The name of the user-assigned identities does not match the expected values."
  }

  assert {
    condition = alltrue([
      module.user_assigned_identities["minimum"].identity.location == azurerm_resource_group.workload.location, //Defaults to RG location,
      module.user_assigned_identities["maximum"].identity.location == var.user_assigned_identities.maximum.location
    ])
    error_message = "The location of the user-assigned identities does not match the expected values."
  }

  assert {
    condition     = module.user_assigned_identities["maximum"].identity.group_memberships["static"] == run.bootstrap_uai.azuread_group.object_id
    error_message = "The user-assigned identity was not added to the correct static group."
  }

  assert {
    condition     = module.user_assigned_identities["maximum"].identity.app_role_assignments["User.Read.All"].app_role_id == "df021288-bdef-4463-88db-98f22de89214" //User.Read.All
    error_message = "The app role assignments for the user-assigned identity do not match."
  }

  assert {
    condition = alltrue([
      module.user_assigned_identities["maximum"].identity.role_assignments["subscription_reader"].role_definition_name == var.user_assigned_identities.maximum.role_assignments.subscription_reader.role_definition_name,
      module.user_assigned_identities["maximum"].identity.role_assignments["subscription_reader"].scope == var.user_assigned_identities.maximum.role_assignments.subscription_reader.scope
    ])
    error_message = "The role assignments for the user-assigned identity do not match."
  }
}

run "station-uai-app_role_assignments" {
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
        },
        role_assignments = merge(var.user_assigned_identities.maximum.role_assignments, {
          subscription_reader = merge(var.user_assigned_identities.maximum.role_assignments.subscription_reader, {
            scope = run.bootstrap_uai.current_subscription.id
          })
        })
      })
    })
  }

  module {
    source = "./"
  }
  assert {
    condition     = module.user_assigned_identities["maximum"].identity.app_role_assignments["User.Read.All"].app_role_id == "df021288-bdef-4463-88db-98f22de89214" //User.Read.All
    error_message = "The app role assignments for the user-assigned identity do not match."
  }

  assert {
    condition     = try(module.user_assigned_identities["minimum"].identity.app_role_assignments["User.Read.All"], 0) == 0
    error_message = "The app role assignments for the user-assigned identity should null."
  }

  assert {
    condition = alltrue([
      module.user_assigned_identities["maximum"].identity.role_assignments["subscription_reader"].role_definition_name == var.user_assigned_identities.maximum.role_assignments.subscription_reader.role_definition_name,
      module.user_assigned_identities["maximum"].identity.role_assignments["subscription_reader"].scope == var.user_assigned_identities.maximum.role_assignments.subscription_reader.scope
    ])
    error_message = "The role assignments for the user-assigned identity do not match."
  }
}

run "station-uai-role_assignments" {
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
        },
        role_assignments = merge(var.user_assigned_identities.maximum.role_assignments, {
          subscription_reader = merge(var.user_assigned_identities.maximum.role_assignments.subscription_reader, {
            scope = run.bootstrap_uai.current_subscription.id
          })
        })
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition     = try(lenght(module.user_assigned_identities["minimum"].identity.role_assignments), 0) == 0
    error_message = "The minimum user-assigned identity should not have any role assignments."
  }

  assert {
    condition = alltrue([
      module.user_assigned_identities["maximum"].identity.role_assignments["subscription_reader"].role_definition_name == var.user_assigned_identities.maximum.role_assignments.subscription_reader.role_definition_name,
      module.user_assigned_identities["maximum"].identity.role_assignments["subscription_reader"].scope == var.user_assigned_identities.maximum.role_assignments.subscription_reader.scope
    ])
    error_message = "The role assignments for the user-assigned identity do not match."
  }
}

run "station-uai-group_memberships" {
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
        },
        role_assignments = merge(var.user_assigned_identities.maximum.role_assignments, {
          subscription_reader = merge(var.user_assigned_identities.maximum.role_assignments.subscription_reader, {
            scope = run.bootstrap_uai.current_subscription.id
          })
        })
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition     = module.user_assigned_identities["maximum"].identity.group_memberships["static"] == run.bootstrap_uai.azuread_group.object_id
    error_message = "The user-assigned identity was not added to the correct static group."
  }

  assert {
    condition     = module.user_assigned_identities["maximum"].identity.app_role_assignments["User.Read.All"].app_role_id == "df021288-bdef-4463-88db-98f22de89214" //User.Read.All
    error_message = "The app role assignments for the user-assigned identity do not match."
  }

  assert {
    condition = alltrue([
      module.user_assigned_identities["maximum"].identity.role_assignments["subscription_reader"].role_definition_name == var.user_assigned_identities.maximum.role_assignments.subscription_reader.role_definition_name,
      module.user_assigned_identities["maximum"].identity.role_assignments["subscription_reader"].scope == var.user_assigned_identities.maximum.role_assignments.subscription_reader.scope
    ])
    error_message = "The role assignments for the user-assigned identity do not match."
  }
}
