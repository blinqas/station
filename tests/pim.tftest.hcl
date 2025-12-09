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
    tfc_project_name = "tests_pim"
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
      "pim_test" = "station-test-pim"
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
      name = "tests_pim"
      id   = "# Overwritten in all subsequent run blocks. Terraform limitation"
    }
    organization_name     = "blinq-west-lab"
    workspace_name        = "test_pim"
    workspace_description = "Station Tests for PIM role assignments"
  }

  # Test PIM eligible assignment on Landing Zone identity
  identity = {
    role_assignments = {
      pim_eligible_reader = {
        scope                = null # Will default to workload resource group
        role_definition_name = "Reader"
        description          = "PIM Eligible Reader role"
        pim = {
          member_type = "Eligible"
          expiration = {
            duration_days = 90
          }
          justification = "Test PIM eligible assignment"
        }
      }
      pim_active_contributor = {
        scope                = "/subscriptions/${var.subscription_id}"
        role_definition_name = "Contributor"
        description          = "PIM Active Contributor role"
        pim = {
          member_type = "Active"
          expiration = {
            duration_hours = 8
          }
          justification = "Test PIM active assignment"
        }
      }
      non_pim_reader = {
        scope                = "/subscriptions/${var.subscription_id}"
        role_definition_name = "Reader"
        description          = "Regular non-PIM role assignment"
      }
    }
  }

  # Test PIM on groups
  groups = {
    pim_eligible_group = {
      display_name     = "Station test: PIM Eligible Group"
      security_enabled = true
      description      = "Group with PIM eligible role assignments"

      role_assignments = {
        pim_eligible_storage = {
          scope                = null # Will default to subscription
          role_definition_name = "Storage Blob Data Reader"
          description          = "PIM Eligible Storage access"
          pim = {
            member_type = "Eligible"
            expiration = {
              duration_days = 30
            }
            justification = "Test group PIM eligible assignment"
            ticket_number = "TICKET-123"
            ticket_system = "ServiceNow"
          }
        }
        pim_active_reader = {
          scope                = null
          role_definition_name = "Reader"
          description          = "PIM Active Reader role"
          pim = {
            member_type = "Active"
            expiration = {
              duration_days = 60
            }
            justification = "Test group PIM active assignment"
          }
        }
      }
    }
    non_pim_group = {
      display_name     = "Station test: Non-PIM Group"
      security_enabled = true
      description      = "Group with regular role assignments"

      role_assignments = {
        regular_reader = {
          scope                = null
          role_definition_name = "Reader"
          description          = "Regular reader role"
        }
      }
    }
  }

  # Test PIM on user_assigned_identities
  user_assigned_identities = {
    pim_uai = {
      name     = "uai-pim-test"
      location = "norwayeast"
      role_assignments = {
        pim_eligible_keyvault = {
          scope                = "/subscriptions/${var.subscription_id}"
          role_definition_name = "Key Vault Reader"
          description          = "PIM Eligible Key Vault Reader"
          pim = {
            member_type = "Eligible"
            expiration = {
              duration_days = 45
            }
            justification = "Test UAI PIM eligible assignment"
          }
        }
        pim_active_secrets = {
          scope                = "/subscriptions/${var.subscription_id}"
          role_definition_name = "Key Vault Secrets User"
          description          = "PIM Active Key Vault Secrets User"
          pim = {
            member_type = "Active"
            expiration = {
              duration_hours = 24
            }
            justification = "Test UAI PIM active assignment"
          }
        }
      }
    }
  }
}

# Test PIM role assignments on var.role_assignments (user-specified principals)
run "pim_role_assignments_others" {
  module {
    source = "./"
  }

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    identity = var.identity

    # Role assignments for a specific principal (e.g., a group)
    role_assignments = {
      pim_eligible_for_group = {
        scope                = "/subscriptions/${var.subscription_id}"
        role_definition_name = "Reader"
        principal_id         = run.setup_entraid.groups["pim_test"].object_id
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
        principal_id         = run.setup_entraid.groups["pim_test"].object_id
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
      non_pim_for_group = {
        scope                = "/subscriptions/${var.subscription_id}"
        role_definition_name = "Reader"
        principal_id         = run.setup_entraid.groups["pim_test"].object_id
        description          = "Non-PIM Reader for test group"
      }
    }
  }

  # Assert PIM eligible role assignment exists for var.role_assignments
  assert {
    condition     = can(azurerm_pim_eligible_role_assignment.others["pim_eligible_for_group"])
    error_message = "PIM eligible role assignment for 'pim_eligible_for_group' was not created"
  }

  # Assert PIM active role assignment exists for var.role_assignments
  assert {
    condition     = can(azurerm_pim_active_role_assignment.others["pim_active_for_group"])
    error_message = "PIM active role assignment for 'pim_active_for_group' was not created"
  }

  # Assert non-PIM role assignment exists for var.role_assignments
  assert {
    condition     = can(azurerm_role_assignment.others["non_pim_for_group"])
    error_message = "Non-PIM role assignment for 'non_pim_for_group' was not created"
  }

  # Assert PIM eligible assignment has correct principal
  assert {
    condition     = azurerm_pim_eligible_role_assignment.others["pim_eligible_for_group"].principal_id == run.setup_entraid.groups["pim_test"].object_id
    error_message = "PIM eligible role assignment has incorrect principal_id"
  }

  # Assert PIM active assignment has correct principal
  assert {
    condition     = azurerm_pim_active_role_assignment.others["pim_active_for_group"].principal_id == run.setup_entraid.groups["pim_test"].object_id
    error_message = "PIM active role assignment has incorrect principal_id"
  }
}

# Test PIM role assignments on Landing Zone identity
run "pim_identity_role_assignments" {
  module {
    source = "./"
  }

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    identity = var.identity
  }

  # Assert PIM eligible role assignment exists for Landing Zone identity
  assert {
    condition     = can(azurerm_pim_eligible_role_assignment.lz_identity["pim_eligible_reader"])
    error_message = "PIM eligible role assignment for Landing Zone identity was not created"
  }

  # Assert PIM active role assignment exists for Landing Zone identity
  assert {
    condition     = can(azurerm_pim_active_role_assignment.lz_identity["pim_active_contributor"])
    error_message = "PIM active role assignment for Landing Zone identity was not created"
  }

  # Assert non-PIM role assignment exists for Landing Zone identity
  assert {
    condition     = can(azurerm_role_assignment.lz_identity["non_pim_reader"])
    error_message = "Non-PIM role assignment for Landing Zone identity was not created"
  }

  # Assert PIM eligible assignment has correct principal (Landing Zone identity)
  assert {
    condition     = azurerm_pim_eligible_role_assignment.lz_identity["pim_eligible_reader"].principal_id == module.user_assigned_identity.principal_id
    error_message = "PIM eligible role assignment for Landing Zone identity has incorrect principal_id"
  }

  # Assert PIM active assignment has correct principal (Landing Zone identity)
  assert {
    condition     = azurerm_pim_active_role_assignment.lz_identity["pim_active_contributor"].principal_id == module.user_assigned_identity.principal_id
    error_message = "PIM active role assignment for Landing Zone identity has incorrect principal_id"
  }
}

# Test PIM role assignments on groups
run "pim_group_role_assignments" {
  module {
    source = "./"
  }

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    groups = var.groups
  }

  # Assert PIM eligible role assignment exists for group
  assert {
    condition     = can(module.ad_groups.pim_eligible_group.role_assignments["pim_eligible_storage"])
    error_message = "PIM eligible role assignment for group was not created"
  }

  # Assert PIM active role assignment exists for group
  assert {
    condition     = can(module.ad_groups.pim_eligible_group.role_assignments["pim_active_reader"])
    error_message = "PIM active role assignment for group was not created"
  }

  # Assert non-PIM role assignment exists for non-PIM group
  assert {
    condition     = can(module.ad_groups.non_pim_group.role_assignments["regular_reader"])
    error_message = "Non-PIM role assignment for group was not created"
  }
}

# Test PIM role assignments on user_assigned_identities
run "pim_uai_role_assignments" {
  module {
    source = "./"
  }

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    user_assigned_identities = var.user_assigned_identities
  }

  # Assert PIM eligible role assignment exists for UAI
  assert {
    condition     = can(module.user_assigned_identities["pim_uai"].role_assignments["pim_eligible_keyvault"])
    error_message = "PIM eligible role assignment for user assigned identity was not created"
  }

  # Assert PIM active role assignment exists for UAI
  assert {
    condition     = can(module.user_assigned_identities["pim_uai"].role_assignments["pim_active_secrets"])
    error_message = "PIM active role assignment for user assigned identity was not created"
  }
}
