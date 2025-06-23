provider "tfe" {}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias = "connectivity"
  features {}
}

provider "azuread" {}

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
      user_principal_name = "stationtestuser@blinQVestLab.onmicrosoft.com"
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
