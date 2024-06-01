#module "station-uai" {
#  depends_on = [tfe_project.test]
#  source     = "./.."
#  tfe = {
#    project_name          = tfe_project.test.name
#    organization_name     = data.tfe_organization.test.name
#    workspace_description = "This workspace contains groups_tests from https://github.com/blinqas/station.git"
#    workspace_name        = "station-tests-uai_tests"
#  }
#  managed_identity_name = "testName"
#  user_assigned_identities = {
#    minimum = {
#      name = "uai-01"
#    }
#
#    maximum = {
#      name                 = "uai-02"
#      location             = "norwayeast"
#      app_role_assignments = ["User.Read.All"]
#      group_memberships = {
#        static = module.station-groups.groups.static.object_id
#      }
#      role_assignments = {
#        subscription_reader = {
#          role_definition_name = "Reader"
#          scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
#        }
#      }
#    }
#  }
#}
#
