module "station-workload-identity" {
  depends_on      = [tfe_project.test]
  source          = "./.."
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  tfe = {
    project_name          = tfe_project.test.name
    organization_name     = data.tfe_organization.test.name
    workspace_description = "This workspace contains test_workload_identity from https://github.com/blinqas/station.git"
    workspace_name        = "station-tests-workload-identity"
  }

  managed_identity_name = "workload-identity"
  app_role_assignments  = ["User.ReadBasic.All"]
}

