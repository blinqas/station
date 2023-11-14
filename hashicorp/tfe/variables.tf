variable "organization_name" {
  description = "The name of the Terraform Cloud organization to work in"
  type        = string
}

variable "project_name" {
  description = "Name of the project to link `var.workspace_name` to. The project must exist already. Can not be set if `var.projects` is set."
  type        = string
}

variable "workspace_name" {
  description = "Name of the workspace to provision in Terraform Cloud"
  type        = string
}

variable "workspace_description" {
  description = "Description of the Terraform Cloud workspace"
  type        = string
}

variable "workspace_env_vars" {
  description = "Map of environment variables to provision on the workspace in Terraform Cloud"
  type = map(object({
    value       = string
    category    = string
    description = string
    sensitive   = optional(bool)
  }))
  default = null
}

variable "workspace_vars" {
  description = "Map of variables to provision on the workspace in Terraform Cloud"
  type = map(object({
    value       = any
    category    = string
    description = string
    hcl         = bool
    sensitive   = bool
  }))
  default = null
}

variable "vcs_repo" {
  description = "Settings for the workspace's VCS repository, enabling the UI/VCS-driven run workflow."
  type = object({
    identifier                 = string
    branch                     = optional(string)
    ingress_submodules         = optional(string)
    oauth_token_id             = optional(string)
    github_app_installation_id = optional(string)
    tags_regex                 = optional(string)
  })
  default = null
}
