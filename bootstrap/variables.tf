variable "tfc_organization_name" {
  type        = string
  description = "The name of the organization containing the workspace(s) the current configuration should use."
}

variable "tfc_project_name" {
  type        = string
  description = "The name of a Terraform Cloud project. Provisioned on initial bootstrap run."
}

variable "tfc_token" {
  type        = string
  description = "Access token for TFC. This can be either a team or organziation token. https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens"
}

variable "bootstrap_tfc_workspace_name" {
  type        = string
  description = "The name of a single Terraform Cloud workspace. Provisioned on initial bootstrap run."
}

variable "deployments_tfc_workspace_name" {
  type        = string
  description = "The name of a single Terraform Cloud workspace for Station Deployments."
}

variable "tfc_hostname" {
  description = "The hostname of a Terraform Enterprise installation, if using Terraform Enterprise. Defaults to Terraform Cloud (app.terraform.io)."
  default     = "app.terraform.io"
  type        = string
}

variable "bootstrap_repo_url" {
  type        = string
  description = "The url of the git repository where the bootstrap code is stored. Providing this makes it easy to find back to the source repo where Station was bootstrapped from."
  default     = "Not provided. Set `var.bootstrap_repo_url`."
}

variable "vcs_repo_name" {
  type        = string
  description = "The name you want to give the repository that should hold you Station deployments"
}

variable "vcs_repo_branch" {
  type        = string
  description = "(Optional) The repository branch that Terraform will execute from. This defaults to the repository's default branch (e.g. main)."
  default     = null
}

variable "vcs_repo_oauth_token_id" {
  type        = string
  description = "(Optional) The VCS Connection (OAuth Connection + Token) to use. This ID can be obtained from a tfe_oauth_client resource. This conflicts with github_app_installation_id and can only be used if github_app_installation_id is not used."
  default     = null
}

variable "vcs_repo_github_app_installation_id" {
  type        = string
  description = "(Optional) The installation id of the Github App. This conflicts with oauth_token_id and can only be used if oauth_token_id is not used. Go to https://app.terraform.io/api/v2/github-app/installations to find installations. See https://developer.hashicorp.com/terraform/cloud-docs/api-docs/github-app-installations for more information."
  default     = null
}

variable "vcs_repo_tags_regex" {
  type        = string
  description = "Optional) A regular expression used to trigger a Workspace run for matching Git tags. This option conflicts with trigger_patterns and trigger_prefixes. Should only set this value if the former is not being used."
  default     = null
}

variable "vcs_repo_owner" {
  type        = string
  description = "Name of the GitHub Organization to manage"
  default     = null
}

variable "vcs_repo_PAT" {
  type        = string
  description = "Personal Access Token (PAT) for TFC to create repositories. Documentation: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens"
  default     = null
  sensitive   = true
}

variable "subscription_ids" {
  type        = set(string)
  description = "Set of Subscription ID's the Station identity can manage."
  default     = []
}