variable "github_owner" {
  description = "(Required) The name of the GitHub account to manage."
  type        = string
}

variable "github_app_id" {
  description = "(Required) Application ID of the Station Application Landing Zones Github app."
  type        = string
}

variable "github_app_installation_id" {
  description = "(Required) Application Installation ID of the Station Application Landing Zones Github app."
  type        = string
}

variable "github_app_pem_file" {
  description = "(Required) The private key for the Github app `Station Landing Zones (<org>`. Created at https://github.com/organizations/<org>/settings/apps/"
  sensitive   = true
  type        = string
  ephemeral   = true
}

variable "vcs_repo_github_app_installation_id" {
  description = "(Required) GitHub App Installation ID of the HCP Terraform VCS connection between HCP Terraform and GitHub."
  type        = string
}
