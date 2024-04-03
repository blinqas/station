module "station-groups" {
  depends_on = [tfe_project.test]
  source     = "./.."
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
    }
  }
}

