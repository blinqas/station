variable "tfe" {
  description = <<-EOT
    Configuration for Terraform Cloud/Enterprise workspace.

    - `workspace_id` - (Required) The ID of the workspace.
    - `workspace_settings` - (Optional) Settings for the workspace. For additional information on `workspace_settings`, see [workspace_settings block](#workspace_settings-block).
    - `vcs_repo` - (Optional) Settings for the workspace's VCS repository. For additional information on `vcs_repo`, see [vcs_repo block](#vcs_repo-block).
  EOT
  type = object({
    workspace_id = string
    workspace_settings = optional(object({
      agent_pool_id  = optional(string)
      execution_mode = optional(string)
    }))
    vcs_repo = optional(object({
      identifier                 = string
      branch                     = optional(string)
      ingress_submodules         = optional(bool)
      oauth_token_id             = optional(string)
      github_app_installation_id = optional(string)
      tags_regex                 = optional(string)
    }))
  })
  default = null

  validation {
    condition = (
      var.tfe == null ||
      var.tfe.workspace_settings == null ||
      !(
        var.tfe.workspace_settings.execution_mode == "agent" &&
        var.tfe.workspace_settings.agent_pool_id == null
      )
    )
    error_message = "tfe.workspace_settings: If 'execution_mode' is set to 'agent', 'agent_pool_id' is required."
  }

  validation {
    condition = (
      var.tfe == null ||
      var.tfe.workspace_settings == null ||
      !(
        var.tfe.workspace_settings.execution_mode != "agent" &&
        var.tfe.workspace_settings.execution_mode != null &&
        var.tfe.workspace_settings.agent_pool_id != null
      )
    )
    error_message = "tfe.workspace_settings: If 'execution_mode' is not 'agent', 'agent_pool_id' must not be set."
  }

  validation {
    condition = (
      var.tfe == null ||
      var.tfe.workspace_settings == null ||
      var.tfe.workspace_settings.execution_mode == null ||
      contains(["remote", "local", "agent"], var.tfe.workspace_settings.execution_mode)
    )
    error_message = "tfe.workspace_settings.execution_mode: Valid values are 'remote', 'local', or 'agent'."
  }

  validation {
    condition = (
      var.tfe == null ||
      var.tfe.vcs_repo == null ||
      !(
        var.tfe.vcs_repo.oauth_token_id != null &&
        var.tfe.vcs_repo.github_app_installation_id != null
      )
    )
    error_message = "tfe.vcs_repo: 'oauth_token_id' and 'github_app_installation_id' cannot both be set. Use one or the other."
  }
}
