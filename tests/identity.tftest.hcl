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
    tfc_project_name = "tests_identity"
  }

  module {
    source = "./tests/setup-tfe-project"
  }
}

run "setup_entraid" {
  module {
    source = "./tests/setup-entraid"
  }

  variables {
    groups = {
      "test" = "station-test"
    }
  }
}

run "setup" {
  module {
    source = "./tests/setup-common"
  }
}

run "overrides" {
  module {
    source = "./tests/overrides"
  }
}

variables {
  tfe = {
    project = {
      name = "tests_identity"
      id   = "# Overwritten in all subsequent run blocks. Terraform limitation"
    }
    organization_name     = "blinq-west-lab"
    workspace_name        = "test_identity"
    workspace_description = "Station Tests for var.identity"
  }

  identity = {
    #name = "station-tests-lz" 
  }
}


run "identity" {
  module {
    source = "./"
  }

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    resource_groups = {
      lz2 = {
        name = "station-test-identity"
      }
    }

    identity = {
      role_assignments = {
        key_vault_reader = {
          scope                = "/subscriptions/${run.overrides.subscription_id}"
          role_definition_name = "Key Vault Reader"
          description          = "Needed to read key vaults"
        }
        key_vault_admin = {
          role_definition_name = "Key Vault Administrator"
          description          = "Needed to manage key vaults"
        }
      }

      group_memberships = {
        "Station Test Group" = run.setup_entraid.groups["test"].object_id
      }

      app_role_assignments = {
        "User.ReadWrite.All" = {
          app_role_id        = run.setup.azuread_service_principal.msgraph.app_role_ids["User.ReadWrite.All"]
          resource_object_id = run.setup.azuread_service_principal.msgraph.object_id
        }
      }

      directory_role_assignments = {
        Reader = {
          role_name = "Directory Readers"
        }
      }
    }
  }

  // Role Assignments
  assert {
    condition     = azurerm_role_assignment.lz_owner["default"].role_definition_name == "Owner"
    error_message = "The Landing Zone identity was not assigned Owner on the default landing zone resource group."
  }

  assert {
    condition     = alltrue([for k, v in var.resource_groups : azurerm_role_assignment.lz_owner[k].role_definition_name == "Owner"])
    error_message = "The Landing Zone identity was not assigned Owner on all resource groups in the Landing Zone."
  }

  // Test for default scope being set on role assignments without scope
  assert {
    condition     = azurerm_role_assignment.lz_identity["key_vault_admin-rg-${var.resource_groups.lz2.name}"].scope == "/subscriptions/${run.overrides.subscription_id}/resourceGroups/rg-${var.resource_groups.lz2.name}"
    error_message = "The role assignments from var.identity.role_assignments without a scope was not created with default scope set to the resource groups created in this Landing Zone."
  }

  // Group Membership
  assert {
    condition     = alltrue([for k, v in module.user_assigned_identity.group_memberships : v.member_object_id == module.user_assigned_identity.principal_id])
    error_message = "The Landing Zone identity is not a member of the groups passed in via var.identity.group_memberships"
  }

  // App Role Assignments
  assert {
    condition     = alltrue([for k, v in var.identity.app_role_assignments : module.user_assigned_identity.app_role_assignments[k].app_role_id == v.app_role_id])
    error_message = "The Landing Zone identity was not assigned all Application Role Assignments from var.identity.app_role_assignments"
  }

  // Directory Role Assignments
  assert {
    condition     = alltrue([for k, v in var.identity.directory_role_assignments : module.user_assigned_identity.directory_role_assignments[k].principal_object_id == module.user_assigned_identity.principal_id])
    error_message = "The Landing Zone identity was not assigned all Directory Role Assignments from var.identity.directory_role_assignment"
  }

  // Name is set correctly
  assert {
    condition     = module.user_assigned_identity.name == "mi-${var.tfe.workspace_name}"
    error_message = "The Landing Zone identity is not given the correct default name of..."
  }
}

run "identity_validation_pim_expiration_mutually_exclusive" {
  command = plan

  module {
    source = "./"
  }

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    identity = {
      role_assignments = {
        invalid = {
          scope                = "/subscriptions/${run.overrides.subscription_id}"
          role_definition_name = "Reader"
          pim = {
            member_type = "Eligible"
            schedule = {
              expiration = {
                duration_days = 7
                end_date_time = "2030-01-01T00:00:00Z"
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [
    var.identity
  ]
}

run "role_assignments_validation_pim_member_type" {
  command = plan

  module {
    source = "./"
  }

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    role_assignments = {
      invalid = {
        scope                = "/subscriptions/${run.overrides.subscription_id}"
        principal_id         = run.setup_entraid.groups["test"].object_id
        role_definition_name = "Reader"
        pim = {
          member_type = "Temporary"
        }
      }
    }
  }

  expect_failures = [
    var.role_assignments
  ]
}

