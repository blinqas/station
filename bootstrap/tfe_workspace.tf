resource "tfe_workspace" "bootstrap" {
  name           = var.bootstrap_tfc_workspace_name
  organization   = data.tfe_organization.this.name
  project_id     = tfe_project.station.id
  description    = "This workspace contains state for the bootstrap procedure for Station. Repo URL: ${var.bootstrap_repo_url}"
  execution_mode = "local"
  force_delete   = true
}

resource "tfe_workspace" "deployments" {
  name         = var.deployments_tfc_workspace_name
  organization = data.tfe_organization.this.name
  project_id   = tfe_project.station.id
  description  = "This workspace contains Station Deployments. This workspace was bootstrapped from ${var.bootstrap_repo_url}"

  vcs_repo {
    identifier                 = github_repository.deployments.name
    branch                     = github_branch_default.deployments.branch
    oauth_token_id             = var.vcs_repo_oauth_token_id
    github_app_installation_id = var.vcs_repo_github_app_installation_id
    tags_regex                 = var.vcs_repo_tags_regex
  }
}

