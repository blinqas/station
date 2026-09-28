locals {
  # Keep Graph permission names as keys to preserve existing assignment addresses.
  # The root Station module always looks up the Microsoft Graph service principal.
  station_graph_role_names = toset(concat(
    ["Application.Read.All"],
    var.config.station_capabilities.manage_applications ? ["Application.ReadWrite.All"] : [],
    var.config.station_capabilities.manage_groups || var.config.station_capabilities.manage_group_membership ? ["Group.ReadWrite.All"] : [],
    var.config.station_capabilities.manage_group_membership ? ["User.Read.All"] : [],
    var.config.station_capabilities.grant_application_permissions ? ["AppRoleAssignment.ReadWrite.All"] : [],
    var.config.station_capabilities.assign_directory_roles ? ["RoleManagement.ReadWrite.Directory"] : []
  ))
  station_graph_role_assignments = {
    for name in local.station_graph_role_names : name => {
      app_role_id        = data.azuread_service_principal.msgraph.app_role_ids[name]
      resource_object_id = data.azuread_service_principal.msgraph.object_id
    }
  }

  use_github            = try(var.config.github, null) != null
  repository_identifier = local.use_github ? github_repository.this[0].full_name : gitlab_project.this[0].path_with_namespace
  bootstrap_files = toset([
    "main.tf",
    "providers.tf",
    "variables.tf",
    "github.tf",
    "gitlab.tf",
    "locals.tf",
    "providers/providers.cloud.tf",
    "providers/providers.local.tf",
    "files/providers.github.tf",
    "files/providers.gitlab.tf",
    "files/variables.tf",
    "files/variables.github.tf",
    "files/variables.gitlab.tf",
    "files/variables.bootstrap.tf",
    "lz.auto.tfvars",
    "README.md",
    "PERMISSIONS.md"
  ])
  github_vcs_repo = {
    identifier                 = local.repository_identifier
    branch                     = try(var.config.github.branch, null)
    github_app_installation_id = try(var.config.terraform_cloud.vcs_repo_github_app_installation_id, null)
  }
  gitlab_vcs_repo = {
    identifier     = local.repository_identifier
    branch         = try(var.config.gitlab.branch, null)
    oauth_token_id = try(var.config.terraform_cloud.vcs_repo_oauth_token_id, null)
  }
  vcs_repo = local.use_github ? local.github_vcs_repo : local.gitlab_vcs_repo

  common_workspace_vars = {
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
    }
  }
  github_workspace_vars = {
    // The reason all github provider configuration values are of type `terraform`
    // as opposed to setting them as `env` is because HCP Terraform does not
    // support multi-line env vars. This means the PEM file can not be
    // set without base64 encoding it first, and decode it on provider.
    github_owner = {
      value       = try(var.config.github.owner, null)
      description = "GitHub Account name."
      sensitive   = false
      category    = "terraform"
    },
    github_app_id = {
      value       = try(var.config.github.provider.id, null)
      description = "Station Application Landing Zones application id."
      sensitive   = false
      category    = "terraform"
    },
    github_app_installation_id = {
      value       = try(var.config.github.provider.installation_id, null)
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
    vcs_repo_github_app_installation_id = {
      value       = try(var.config.terraform_cloud.vcs_repo_github_app_installation_id, null)
      description = "The installation id of the Github app used for the VCS connection between HCP Terraform and Github.",
      sensitive   = false,
      category    = "terraform"
    }
  }
  gitlab_workspace_vars = {
    GITLAB_TOKEN = {
      value       = var.gitlab_token
      description = "GitLab API token for managing GitLab from the landing-zone workspace."
      sensitive   = true
      category    = "env"
    }
    vcs_repo_oauth_token_id = {
      value       = try(var.config.terraform_cloud.vcs_repo_oauth_token_id, null)
      description = "HCP Terraform OAuth token ID for the GitLab VCS connection."
      sensitive   = false
      category    = "terraform"
    }
    tfe_organization_name = {
      value       = var.config.terraform_cloud.organization_name
      description = "HCP Terraform organization name."
      sensitive   = false
      category    = "terraform"
    }
    tenant_id = {
      value       = var.config.tenant_id
      description = "Azure tenant ID."
      sensitive   = false
      category    = "terraform"
    }
    gitlab_group = {
      value       = try(var.config.gitlab.group, null)
      description = "Full path of the GitLab group for landing zones."
      sensitive   = false
      category    = "terraform"
    }
    subscription_id = {
      value       = var.config.subscription_id
      description = "Azure subscription ID."
      sensitive   = false
      category    = "terraform"
    }
  }
  workspace_env_vars = merge(
    local.common_workspace_vars,
    local.use_github ? local.github_workspace_vars : local.gitlab_workspace_vars
  )
}
