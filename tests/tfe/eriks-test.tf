module "eriks-station-test" {
  source           = "../../"
  environment_name = "prod"

  tfe = {
    organization_name     = "managed-devops"
    project_name          = local.tfe_projects.eriks_test.project_name
    workspace_name        = "tfe-${each.value.environment_name}"
    workspace_description = "Erik test"
    vcs_repo = {
      identifier                 = "kimfy/tfe-testing"
      github_app_installation_id = var.github_app_installation_id
    }
    module_outputs_to_workspace_var = {
      groups = true
    }
    create_federated_identity_credential = true
  }

  depends_on = [tfe_project.projects]
}

