variable "vcs_repo_oauth_token_id" {
  description = "HCP Terraform OAuth token ID for the GitLab VCS connection."
  type        = string
}

variable "tfe_organization_name" {
  description = "HCP Terraform organization name."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID."
  type        = string
}

variable "gitlab_group" {
  description = "Full path of the GitLab group for landing zones."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}
