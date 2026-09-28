variable "config" {
  type        = any
  description = "Bootstrap configuration with exactly one of github or gitlab selected."

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
    (Optional) Whether to grant the Station identity the "Privileged Role Administrator" directory role.
    
    Default: false
    
    When DISABLED (default):
      • Station uses only Microsoft Graph API permissions (least-privilege)
      • Landing zones CANNOT be assigned Entra ID directory roles
      • Landing zones CAN still receive Graph API permissions (e.g., User.Read.All)
      • This is the recommended setting for most deployments
    
    When ENABLED:
      • Station can assign ANY directory role to landing zone identities
      • Including Global Administrator (privilege escalation risk)
      • Only enable if landing zones genuinely require directory roles
      • Ensure strict repository access controls are in place
    
    See PERMISSIONS.md for detailed security implications.
    Reference: https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference#privileged-role-administrator
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
