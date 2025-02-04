module "station-groups" {
  depends_on      = [tfe_project.test]
  source          = "./.."
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  tfe = {
    project_name          = tfe_project.test.name
    organization_name     = data.tfe_organization.test.name
    workspace_description = "This workspace contains groups_tests from https://github.com/blinqas/station.git"
    workspace_name        = "station-tests-group_tests"
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
      owners           = [data.azuread_client_config.current.object_id]
      members          = [data.azuread_client_config.current.object_id]
    },

    dynamic = {
      display_name     = "Station test: groups dynamic"
      security_enabled = true
      description      = "This group is dynamic"
      types            = ["DynamicMembership"]
      owners           = [data.azuread_client_config.current.object_id]
      dynamic_membership = {
        enabled = true
        rule    = "user.jobTitle -eq \"DevOps Engineer\""
      }
    },
    minimal_with_role_assignments = {
      display_name     = "Station test: groups minimal with role assignments"
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

