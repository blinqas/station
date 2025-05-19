locals {
  vcs_repo = {
    identifier                 = github_repository.this.full_name
    branch                     = var.config.github.branch
    github_app_installation_id = var.config.terraform_cloud.vcs_repo_github_app_installation_id
  }
  workspace_env_vars = {
    // The reason all github provider configuration values are of type `terraform`
    // as opposed to setting them as `env` is because HCP Terraform does not
    // support multi-line env vars. This means the PEM file can not be 
    // set without base64 encoding it first, and decode it on provider.
    github_owner = {
      value       = var.config.github.owner
      description = "GitHub Account name."
      sensitive   = false
      category    = "terraform"
    },
    github_app_id = {
      value       = var.config.github.provider.id
      description = "Station Application Landing Zones application id."
      sensitive   = false
      category    = "terraform"
    },
    github_app_installation_id = {
      value       = var.config.github.provider.installation_id
      description = "Station Application Landing Zones application's installation id."
      sensitive   = false
      category    = "terraform"
    },
    github_app_pem_file = {
      value       = var.github_app_pem_file
      description = "Base64 encoded private key for the Station Landing Zones Github app."
      sensitive   = true
      category    = "terraform"
    },
    TFE_ORGANIZATION = {
      value       = var.config.terraform_cloud.organization_name
      description = "The name of the Terraform Cloud organization."
      sensitive   = false
      category    = "env"
    },
    TFE_TOKEN = {
      value       = var.tfe_token
      description = "HCP Terraform User API token for \"Service Account\" user. Must be member of the `owners` team."
      sensitive   = true
      category    = "env"
    },
    vcs_repo_github_app_installation_id = {
      value       = var.config.terraform_cloud.vcs_repo_github_app_installation_id
      description = "The installation id of the Github app used for the VCS connection between HCP Terraform and Github.",
      sensitive   = false,
      category    = "terraform"
    }
  }
}
