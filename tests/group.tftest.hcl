provider "tfe" {}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias = "connectivity"
  features {}
}

provider "azuread" {}

variable "subscription_id" {
  type = string
}

test {
  parallel = true
}

run "bootstrap_create_tfc_test_project" {
  variables {
    tfc_project_name = "tests_group"
  }
  module {
    source = "./tests/setup-tfe-project"
  }
}

run "setup" {
  module {
    source = "./tests/setup-common"
  }
}

run "bootstrap_groups" {
  variables {
    user = {
      user_principal_name = "stationtestuser"
      display_name        = "Test User"
      job_title           = "DevOps Engineer" # This has to match the rule in the dynamic group bellow
    }
  }
  module {
    source = "./tests/setup-groups"
  }
}

variables {
  tfe = {
    project = {
      id   = "# Overridden"
      name = "tests_group"
    }
    organization_name     = "blinq-west-lab"
    workspace_name        = "tests_group"
    workspace_description = "This is a test for the group module."
  }

  groups = {
    minimal = {
      display_name     = "Station test: groups minimal"
      security_enabled = true
    },
    static = {
      display_name     = "Station test: groups static"
      security_enabled = true
      description      = "This group is static"
      owners           = ["overriden"]
      members          = ["overriden"]
    },
    dynamic = {
      display_name     = "Station test: groups dynamic"
      security_enabled = true
      description      = "This group is dynamic"
      types            = ["DynamicMembership"]
      dynamic_membership = {
        enabled = true
        rule    = "user.jobTitle -eq \"DevOps Engineer\""
      }
    },
    minimal_with_role_assignments = {
      display_name     = "Station test: groups minimal roles"
      security_enabled = true

      role_assignments = {
        subscription_reader = {
          scope                = null
          role_definition_name = "Reader"
          description          = "Reader on the subscription"
        },
        backup_sa_contributor = {
          scope                = null
          role_definition_name = "Storage Blob Data Contributor"
          description          = "Storage Blob Data Contributor on the storage account"
        }
      }
    },
    with_directory_role_assignments = {
      display_name       = "Station test: groups with directory roles"
      security_enabled   = true
      assignable_to_role = true

      directory_role_assignments = {
        directory_reader = {
          role_name = "Directory Readers"
        }
      }
    }
  }
}

run "app_role_assignments" {
  module {
    source = "./"
  }

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    groups = merge(var.groups, {
      static = merge(var.groups.static, {
        owners  = toset([run.bootstrap_groups.current.object_id]),
        members = toset([run.bootstrap_groups.current.object_id, run.bootstrap_groups.test_user_object_id])
      })
    })
  }

  assert {
    condition     = var.groups == {} ? true : module.user_assigned_identity.app_role_assignments["User.ReadBasic.All"].principal_object_id == module.user_assigned_identity.principal_id && module.user_assigned_identity.app_role_assignments["Group.Read.All"].principal_object_id == module.user_assigned_identity.principal_id
    error_message = "The Landing Zone identity was not assigned User.ReadBasic.All and Group.Read.All when `var.groups` was configured. These roles are required when managing Entra ID groups."
  }
}

run "groups-main" {
  variables {
    // Override project ID from `bootstrap_create_tfc_test_project`
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    // Override `owners` and `members` in `groups.static`
    groups = merge(var.groups, {
      static = merge(var.groups.static, {
        owners  = toset([run.bootstrap_groups.current.object_id]),
        members = toset([run.bootstrap_groups.current.object_id, run.bootstrap_groups.test_user_object_id])
      })
    })
  }

  module {
    source = "./"
  }

  # Assertions for minimal group
  assert {
    condition     = module.ad_groups.minimal.display_name == var.groups.minimal.display_name
    error_message = "The display name for the minimal group is incorrect (var.groups.minimal.display_name)"
  }

  assert {
    condition     = module.ad_groups.minimal.group.security_enabled == var.groups.minimal.security_enabled
    error_message = "The security_enabled setting for the minimal group is incorrect"
  }

  # Assertions for static group
  assert {
    condition     = module.ad_groups.static.group.display_name == var.groups.static.display_name
    error_message = "The display name for the static group is incorrect"
  }

  assert {
    condition     = module.ad_groups.static.group.security_enabled == var.groups.static.security_enabled
    error_message = "The security_enabled setting for the static group is incorrect"
  }

  assert {
    condition     = module.ad_groups.static.group.description == var.groups.static.description
    error_message = "The description for the static group is incorrect"
  }

  assert {
    condition     = module.ad_groups.static.group.owners == toset(concat(var.groups.static.owners, [output.workload_service_principal_object_id]))
    error_message = "The group does not have the correct owners (var.groups.static.owners)"
  }

  assert {
    condition     = contains(module.ad_groups.static.group.members, run.bootstrap_groups.current.object_id)
    error_message = "The user executing the tests  was not added as a member to the group"
  }

  assert {
    condition     = contains(module.ad_groups.static.group.members, run.bootstrap_groups.current.object_id)
    error_message = "The test user was not added as a member to the group"
  }
  # Assertions for dynamic group
  assert {
    condition     = module.ad_groups.dynamic.group.display_name == var.groups.dynamic.display_name
    error_message = "The group does not have the correct display_name (var.groups.dynamic.display_name)"
  }

  assert {
    condition     = module.ad_groups.dynamic.group.security_enabled == var.groups.dynamic.security_enabled
    error_message = "The group does not have the correct security_enabled (var.groups.dynamic.security_enabled)"
  }
  assert {
    condition     = module.ad_groups.dynamic.group.description == var.groups.dynamic.description
    error_message = "The group does not have the correct description (var.groups.dynamic.description)"
  }

  assert {
    condition     = module.ad_groups.dynamic.group.types == toset(var.groups.dynamic.types)
    error_message = "The group does not have the correct types (var.groups.dynamic.types)"
  }
  /*   assert { //This test was dissabled because we cant get the group members that are added without having to add a datablock to the module
    condition     = contains(module.ad_groups.dynamic.members, run.bootstrap_groups.test_user_object_id)
    error_message = "The test user was not dynamicaly added as a member to the group. The user should be added if the job title matches the config for the dynamic group"
  } */
}

run "groups-role_assignments" {
  variables {
    // Override project ID from `bootstrap_create_tfc_test_project`
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    // Override `owners` and `members` in `groups.static`
    groups = merge(var.groups, {
      static = merge(var.groups.static, {
        owners  = toset([run.bootstrap_groups.current.object_id]),
        members = toset([run.bootstrap_groups.current.object_id, run.bootstrap_groups.test_user_object_id])
      })
    })
  }

  module {
    source = "./"
  }

  # Ensure "Reader" role is assigned
  assert {
    condition     = contains([for role_assignment in values(module.ad_groups.minimal_with_role_assignments.role_assignments) : role_assignment.role_definition_name], "Reader")
    error_message = "No 'Reader' role assignments found for the group"
  }

  # Ensure "Storage Blob Data Contributor" role is assigned
  assert {
    condition     = contains([for role_assignment in values(module.ad_groups.minimal_with_role_assignments.role_assignments) : role_assignment.role_definition_name], "Storage Blob Data Contributor")
    error_message = "No 'Storage Blob Data Contributor' role assignments found for the minimal group with role assignments"
  }

  # Ensure "Owner" role is NOT assigned
  assert {
    condition     = !contains([for role_assignment in values(module.ad_groups.minimal_with_role_assignments.role_assignments) : role_assignment.role_definition_name], "Owner")
    error_message = "Unassigned role found for the minimal group with role assignments"
  }
}

run "groups-directory_role_assignments" {
  variables {
    // Override project ID from `bootstrap_create_tfc_test_project`
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    // Override `owners` and `members` in `groups.static`
    groups = merge(var.groups, {
      static = merge(var.groups.static, {
        owners  = toset([run.bootstrap_groups.current.object_id]),
        members = toset([run.bootstrap_groups.current.object_id, run.bootstrap_groups.test_user_object_id])
      })
    })
  }

  module {
    source = "./"
  }

  # Ensure Directory Readers role is assigned
  assert {
    condition     = length(module.ad_groups.with_directory_role_assignments.directory_role_assignments) > 0
    error_message = "No directory role assignments were created for the group"
  }

  assert {
    condition     = alltrue([for k, v in var.groups.with_directory_role_assignments.directory_role_assignments : module.ad_groups.with_directory_role_assignments.directory_role_assignments[k].principal_object_id == module.ad_groups.with_directory_role_assignments.group.object_id])
    error_message = "The group was not assigned all Directory Role Assignments from var.groups.with_directory_role_assignments.directory_role_assignments"
  }

  # Ensure the group object_id matches expected value
  assert {
    condition     = module.ad_groups.with_directory_role_assignments.group.object_id != null && module.ad_groups.with_directory_role_assignments.group.object_id != ""
    error_message = "The group object_id is not set correctly"
  }
}

run "groups-directory_role_assignments_with_role_id" {
  variables {
    // Override project ID from `bootstrap_create_tfc_test_project`
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    // Override `owners` and `members` in `groups.static` and add group with role_id for directory role test
    groups = merge(var.groups, {
      static = merge(var.groups.static, {
        owners  = toset([run.bootstrap_groups.current.object_id]),
        members = toset([run.bootstrap_groups.current.object_id, run.bootstrap_groups.test_user_object_id])
      }),
      with_directory_role_id = {
        display_name       = "Station test: groups with directory role ID"
        security_enabled   = true
        assignable_to_role = true

        directory_role_assignments = {
          directory_reader_by_id = {
            role_id = run.setup.azuread_directory_role.directory_readers.template_id
          }
        }
      }
    })
  }

  module {
    source = "./"
  }

  # Ensure directory role assignment was created using role_id
  assert {
    condition     = length(module.ad_groups.with_directory_role_id.directory_role_assignments) > 0
    error_message = "No directory role assignments were created for the group using role_id"
  }

  assert {
    condition     = alltrue([for k, v in module.ad_groups.with_directory_role_id.directory_role_assignments : v.principal_object_id == module.ad_groups.with_directory_role_id.group.object_id])
    error_message = "The group was not assigned directory role using role_id"
  }

  assert {
    condition     = alltrue([for k, v in module.ad_groups.with_directory_role_id.directory_role_assignments : v.role_id == run.setup.azuread_directory_role.directory_readers.template_id])
    error_message = "The directory role assignment does not have the expected role_id"
  }
}

run "groups-validation_assignable_to_role_required" {
  command = plan

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    groups = {
      invalid_group = {
        display_name       = "Invalid group without assignable_to_role"
        security_enabled   = true
        assignable_to_role = false

        directory_role_assignments = {
          directory_reader = {
            role_name = "Directory Readers"
          }
        }
      }
    }
  }

  expect_failures = [
    var.groups
  ]
}

run "groups-validation_role_name_and_role_id_mutually_exclusive" {
  command = plan

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    groups = {
      invalid_group = {
        display_name       = "Invalid group with both role_name and role_id"
        security_enabled   = true
        assignable_to_role = true

        directory_role_assignments = {
          directory_reader = {
            role_name = "Directory Readers"
            role_id   = run.setup.azuread_directory_role.directory_readers.template_id
          }
        }
      }
    }
  }

  expect_failures = [
    var.groups
  ]
}

run "groups-validation_role_name_or_role_id_required" {
  command = plan

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    groups = {
      invalid_group = {
        display_name       = "Invalid group without role_name or role_id"
        security_enabled   = true
        assignable_to_role = true

        directory_role_assignments = {
          directory_reader = {
            # Neither role_name nor role_id provided
          }
        }
      }
    }
  }

  expect_failures = [
    var.groups
  ]
}

run "groups-validation_pim_member_type" {
  command = plan

  variables {
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    groups = {
      invalid_group = {
        display_name     = "Invalid group with unsupported PIM member type"
        security_enabled = true

        role_assignments = {
          invalid = {
            scope                = "/subscriptions/${var.subscription_id}"
            role_definition_name = "Reader"
            pim = {
              member_type = "Temporary"
            }
          }
        }
      }
    }
  }

  expect_failures = [
    var.groups
  ]
}
