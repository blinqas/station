config = {
  # az account show --query tenantId -o tsv
  tenant_id = ""
  # az account show --query id -o tsv
  subscription_id = ""
  # The name of the resource group to install Station. Station prefixes this with `rg-`
  resource_group_name = "alz"
  # The name of the Managed Identity which will deploy further Landing Zones
  identity_name = "id-alz"

  terraform_cloud = { # Terraform Cloud Configuration
    organization_name                   = ""
    workspace_name                      = "alz"
    workspace_description               = "Landing Zone definitions"
    bootstrap_workspace_name            = "alz-bootstrap"
    bootstrap_workspace_description     = "Bootstrap for Landing Zones"
    #vcs_repo_github_app_installation_id = ""
    # GitLab: comment out the GitHub App ID above and uncomment this OAuth token ID.
    vcs_repo_oauth_token_id = "" # HCP Terraform GitLab VCS connection token ID
    project = {
      name        = "Azure Landing Zones"
      description = "Azure Landing Zones"
    }
  }

  # github = {
  #   owner       = "" # Organization
  #   repository  = "alz"
  #   description = "Terraform Configuration for Landing Zones"
  #   branch      = "main"

  #   # Bootstrap
  #   bootstrap_repository  = "alz-bootstrap"
  #   bootstrap_description = "Terraform Configuration for Bootstrap of Azure Landing Zones"
  #   bootstrap_branch      = "main"

  #   provider = { # Station Landing Zones GitHub App
  #     id              = ""
  #     installation_id = ""
  #   }
  # }

  # GitLab: comment out the entire github block above, then uncomment and fill in this block.
  gitlab = {
    group                 = "" # Full GitLab group/subgroup path, e.g. "platform/landing-zones"
    repository            = "alz"
    description           = "Terraform Configuration for Landing Zones"
    branch                = "main"
    bootstrap_repository  = "alz-bootstrap"
    bootstrap_description = "Terraform Configuration for Bootstrap of Azure Landing Zones"
    bootstrap_branch      = "main"
  }

  tags = {
    owner      = "Platform Engineering"
    deployedBy = "terraform"
  }
}

# GitLab API authentication is a separate, required sensitive input:
# export TF_VAR_gitlab_token="your-gitlab-api-token"
# This token is also installed as GITLAB_TOKEN in the landing-zone workspace.
# Do not store tokens in this file.
