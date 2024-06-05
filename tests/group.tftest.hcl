provider "tfe" {}
provider "azurerm" {
  features {}
}
provider "azuread" {

}

variables {
  tfe = {
    project_name                         = "tests_group"
    organization_name                    = "blinq-west-lab"
    workspace_name                       = "tests_group"
    workspace_description                = "This is a test for the group module."
    create_federated_identity_credential = true # Configures Federated Credentials on the workload identity for plan and apply phases.
  }

  groups = {
    minimal = {
      display_name     = "Station test: groups minimal"
      security_enabled = true
    },
    
    minimal_with_role_assignments = {
      display_name     = "Station test: groups minimal roles"
      security_enabled = true

      role_assignments = {
        subscription_reader = {
          scope                = null #Will default to subscription
          role_definition_name = "Reader"
          description          = "Reader on the subscription"
        },
        backup_sa_contributor = {
          scope                = null #Will default to subscription
          role_definition_name = "Storage Blob Data Contributor"
          description          = "Storage Blob Data Contributor on the storage account"
        }
      }
    }
  }
}

run "setup_create_tfc_test_project" {
  variables {
    tfc_project_name = "tests_group"
  }
  module {
    source = "./tests/setup-tfe-project"
  }
}


run "groups" {

  module {
    source = "./"
  }

  assert {
    condition     = module.ad_groups.minimal_with_role_assignments.display_name == "Station test: groups minimal roles"
    error_message = "The display name for the minimal group with role assignments is incorrect"
  }

  assert {
    condition = contains([for role_assignment in values(module.ad_groups.minimal_with_role_assignments.group_with_roles.role_assignments) : role_assignment.role_name], "Reader")
    error_message = "No 'Reader' role assignments found for the minimal group with role assignments"
  }

  assert {
    condition = contains([for role_assignment in values(module.ad_groups.minimal_with_role_assignments.group_with_roles.role_assignments) : role_assignment.role_name], "Storage Blob Data Contributor")
    error_message = "No 'Storage Blob Data Contributor' role assignments found for the minimal group with role assignments"
  }

  assert {
    condition = !contains([for role_assignment in values(module.ad_groups.minimal_with_role_assignments.group_with_roles.role_assignments) : role_assignment.role_name], "Owner")
    error_message = "Unassigned role found for the minimal group with role assignments"
  }
}