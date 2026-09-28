variable "vcs_repo_oauth_token_id" {
  description = "HCP Terraform OAuth token ID for the GitLab VCS connection."
  type        = string
}

variable "gitlab_group" {
  description = "Full path of the GitLab group for landing zones."
  type        = string
}