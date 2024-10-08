resource "tfe_workspace" "workload" {
  name                  = var.workspace_name
  description           = var.workspace_description
  project_id            = data.tfe_project.workload.id
  file_triggers_enabled = var.file_triggers_enabled

  dynamic "vcs_repo" {
    for_each = var.vcs_repo == null ? [] : [var.vcs_repo]

    content {
      identifier                 = var.vcs_repo.identifier
      branch                     = try(var.vcs_repo.branch, null)
      ingress_submodules         = try(var.vcs_repo.ingress_submodules, false)
      oauth_token_id             = try(var.vcs_repo.oauth_token_id, null)
      github_app_installation_id = try(var.vcs_repo.github_app_installation_id, null)
      tags_regex                 = try(var.vcs_repo.tags_regex, null)
    }
  }
}

resource "tfe_workspace_settings" "workload" {
  count          = var.workspace_settings == null ? 0 : 1
  workspace_id   = tfe_workspace.workload.id
  agent_pool_id  = var.workspace_settings.agent_pool_id
  execution_mode = var.workspace_settings.execution_mode
}
