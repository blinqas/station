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
          scope                = "/subscriptions/${var.subscription_id}"
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
    condition     = azurerm_role_assignment.lz_identity["key_vault_admin-rg-${var.resource_groups.lz2.name}"].scope == "/subscriptions/${var.subscription_id}/resourceGroups/rg-${var.resource_groups.lz2.name}"
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

run "var_role_assignments_pim" {
  module {
    source = "./"
  }

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    # Role assignments for a specific principal (e.g., a group)
    role_assignments = {
      pim_eligible_for_group = {
        scope                = "/subscriptions/${var.subscription_id}"
        role_definition_name = "Reader"
        principal_id         = run.setup_entraid.groups["test"].object_id
        description          = "PIM Eligible Reader for test group"
        pim = {
          member_type = "Eligible"
          expiration = {
            duration_days = 120
          }
          justification = "Test PIM on var.role_assignments"
        }
      }
      pim_active_for_group = {
        scope                = "/subscriptions/${var.subscription_id}"
        role_definition_name = "Contributor"
        principal_id         = run.setup_entraid.groups["test"].object_id
        description          = "PIM Active Contributor for test group"
        pim = {
          member_type = "Active"
          expiration = {
            duration_days = 180
          }
          justification = "Test PIM active on var.role_assignments"
          ticket_number = "TICKET-456"
          ticket_system = "JIRA"
        }
      }
      pim_eligible_with_role_id = {
        scope              = "/subscriptions/${var.subscription_id}"
        role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c" # Contributor role
        principal_id       = run.setup_entraid.groups["test"].object_id
        description        = "PIM Eligible using role_definition_id"
        pim = {
          member_type = "Eligible"
          expiration = {
            duration_hours = 48
          }
          justification = "Test PIM with role_definition_id"
        }
      }
      non_pim_for_group = {
        scope                = "/subscriptions/${var.subscription_id}"
        role_definition_name = "Reader"
        principal_id         = run.setup_entraid.groups["test"].object_id
        description          = "Non-PIM Reader for test group"
      }
    }
  }

  # Assert PIM eligible role assignment exists for var.role_assignments
  assert {
    condition     = can(azurerm_pim_eligible_role_assignment.others["pim_eligible_for_group"])
    error_message = "PIM eligible role assignment for var.role_assignments was not created"
  }

  # Assert PIM active role assignment exists for var.role_assignments
  assert {
    condition     = can(azurerm_pim_active_role_assignment.others["pim_active_for_group"])
    error_message = "PIM active role assignment for var.role_assignments was not created"
  }

  # Assert non-PIM role assignment exists for var.role_assignments
  assert {
    condition     = can(azurerm_role_assignment.others["non_pim_for_group"])
    error_message = "Non-PIM role assignment for var.role_assignments was not created"
  }

  # Assert PIM eligible assignment has correct principal
  assert {
    condition     = azurerm_pim_eligible_role_assignment.others["pim_eligible_for_group"].principal_id == run.setup_entraid.groups["test"].object_id
    error_message = "PIM eligible role assignment has incorrect principal_id"
  }

  # Assert PIM active assignment has correct principal
  assert {
    condition     = azurerm_pim_active_role_assignment.others["pim_active_for_group"].principal_id == run.setup_entraid.groups["test"].object_id
    error_message = "PIM active role assignment has incorrect principal_id"
  }

  # Assert PIM eligible with role_definition_id works
  assert {
    condition     = can(azurerm_pim_eligible_role_assignment.others["pim_eligible_with_role_id"])
    error_message = "PIM eligible role assignment using role_definition_id was not created"
  }
}

