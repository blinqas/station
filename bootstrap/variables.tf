variable "config" {
  description = "Bootstrap configuration with exactly one of github or gitlab selected, including optional Station capabilities."
  type = object({
    tenant_id           = string
    subscription_id     = string
    resource_group_name = string
    identity_name       = string
    tags                = map(string)
    terraform_cloud     = any
    github              = optional(any)
    gitlab              = optional(any)
    station_capabilities = optional(object({
      manage_applications           = optional(bool, false)
      manage_groups                 = optional(bool, false)
      manage_group_membership       = optional(bool, false)
      grant_application_permissions = optional(bool, false)
      assign_directory_roles        = optional(bool, false)
    }), {})
  })

  validation {
    condition     = (try(var.config.github, null) != null) != (try(var.config.gitlab, null) != null)
    error_message = "Set exactly one of config.github or config.gitlab."
  }

  validation {
    condition     = try(var.config.github, null) == null || try(length(trimspace(var.config.terraform_cloud.vcs_repo_github_app_installation_id)) > 0, false)
    error_message = "Set terraform_cloud.vcs_repo_github_app_installation_id for GitHub bootstrap."
  }

  validation {
    condition     = try(var.config.gitlab, null) == null || try(length(trimspace(var.config.terraform_cloud.vcs_repo_oauth_token_id)) > 0, false)
    error_message = "Set terraform_cloud.vcs_repo_oauth_token_id for GitLab bootstrap."
  }
}

variable "tfe_token" {
  description = "(Required) HCP Terraform User API token for \"Service Account\" user. Must be member of the `owners` team."
  sensitive   = true
  type        = string
}

variable "enable_privileged_role_administrator" {
  description = <<-EOT
    Whether to grant the Station identity the Privileged Role Administrator Entra directory role.
    Defaults to false. This is independent of config.station_capabilities.assign_directory_roles,
    which grants the RoleManagement.ReadWrite.Directory Microsoft Graph application permission.
    Neither setting automatically enables the other. See PERMISSIONS.md before enabling.
  EOT
  type        = bool
  default     = false
}

variable "github_app_pem_file" {
  description = "Base64 encoded private key for the Station Landing Zones GitHub app (required for GitHub bootstrap)."
  sensitive   = true
  type        = string
  default     = null

  validation {
    condition     = try(var.config.github, null) == null || try(length(var.github_app_pem_file) > 0, false)
    error_message = "github_app_pem_file is required for GitHub bootstrap."
  }
}

variable "gitlab_token" {
  description = "GitLab API token for bootstrap and the landing-zone workspace. Set TF_VAR_gitlab_token for GitLab bootstrap."
  sensitive   = true
  type        = string
  default     = null

  validation {
    condition     = try(var.config.gitlab, null) == null || try(length(trimspace(var.gitlab_token)) > 0, false)
    error_message = "Set TF_VAR_gitlab_token for GitLab bootstrap and landing-zone management."
  }
}
