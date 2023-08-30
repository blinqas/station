resource "tfe_workspace" "workload" {
  name        = var.workspace_name
  description = var.workspace_description
  project_id  = data.tfe_project.workload.id

  dynamic "vcs_repo" {
    for_each = var.vcs_repo == null ? [] : [var.vcs_repo]

    content {
      identifier                 = vcs_repo.value["identifier"]
      branch                     = try(vcs_repo.value["branch"], null)
      ingress_submodules         = try(vcs_repo.value["ingress_submodules"], false)
      oauth_token_id             = try(vcs_repo.value["oauth_token_id"], null)
      github_app_installation_id = try(vcs_repo.value["github_app_installation_id"], null)
      tags_regex                 = try(vcs_repo.value["tags_regex"], null)
    }
  }
}

