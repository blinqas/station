variable "tfe" {
  description = <<EOF
  Terraform Cloud configuration for the workload environment

  - Either of tfe.vcs_repo.(oauth_token_id|github_app_installation_id) must be provided, both can not be used at the same time.
  - tfe.workspace_env_vars lets you configure Environment Variables for the Terraform Cloud runtime environment
  - tfe.workspace_vars lets you configure Terraform variables
    resource into respective Terraform variables on the Terraform Cloud workspace. Useful when you need group object ids
    for the groups Station Deployments provisioned in your workload environment.
  - tfe.workspace_settings lets you configure the workspace settings like agent_pool_id and execution_mode. If agent_pool_id is provided, execution_mode must be set to "agent".
  - tfe.tags lets you configure tags for the workspace. Tags are key-value pairs that can be used to group and filter workspaces.
  EOF
  default     = null
  type = object({
    organization_name = string
    project = object({
      id   = string
      name = string
    })
    workspace_name        = string
    workspace_description = string
    workspace_settings = optional(object({
      agent_pool_id  = optional(string)
      execution_mode = optional(string)
    }))
    file_triggers_enabled = optional(bool)
    tags                  = optional(map(string))
    vcs_repo = optional(object({
      identifier                 = string
      branch                     = optional(string)
      ingress_submodules         = optional(string)
      oauth_token_id             = optional(string)
      github_app_installation_id = optional(string)
      tags_regex                 = optional(string)
    }))
    workspace_env_vars = optional(map(object({
      value       = string
      category    = string
      description = string
      sensitive   = optional(bool, false)
    })))
    workspace_vars = optional(map(object({
      value       = any
      category    = string
      description = string
      hcl         = optional(bool, false)
      sensitive   = optional(bool, false)
    })))
  })
}
