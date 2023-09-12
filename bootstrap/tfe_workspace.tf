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
    identifier                 = var.vcs_repo_identifier
    branch                     = try(var.vcs_repo_branch, null)
    oauth_token_id             = try(var.vcs_repo_oauth_token_id, null)
    github_app_installation_id = try(var.vcs_repo_github_app_installation_id, null)
    tags_regex                 = try(var.vcs_repo_tags_regex, null)
  }
}

