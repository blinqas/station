resource "tfe_workspace" "workload" {
  name        = var.workspace_name
  description = var.workspace_description
  project_id  = data.tfe_project.workload.id
  dynamic "vcs_repo" {
    for_each = try(var.vcs_repo, null) != null ? [1] : [0]

    content {
      identifier                 = var.vcs_repo.identifier
      branch                     = try(var.vcs_repo.branch, null)
      ingress_submodules         = try(var.ingress_submodules.branch, false)
      oauth_token_id             = try(var.oauth_token_id.branch, null)
      github_app_installation_id = try(var.github_app_installation_id.branch, null)
      tags_regex                 = try(var.tags_regex, null)
    }
  }
}

