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
    vcs_repo_github_app_installation_id = ""
    # For GitLab, remove the GitHub App ID above and set vcs_repo_oauth_token_id = "ot-...".
    project = {
      name        = "Azure Landing Zones"
      description = "Azure Landing Zones"
    }
  }

  github = {
    owner       = "" # Organization
    repository  = "alz"
    description = "Terraform Configuration for Landing Zones"
    branch      = "main"

    # Bootstrap
    bootstrap_repository  = "alz-bootstrap"
    bootstrap_description = "Terraform Configuration for Bootstrap of Azure Landing Zones"
    bootstrap_branch      = "main"

    provider = { # Station Landing Zones GitHub App
      id              = ""
      installation_id = ""
    }
  }

  # For GitLab, replace the entire github block above with a gitlab block.
  # See README.md for the required group, project names, and branch settings.

  tags = {
    owner      = "Platform Engineering"
    deployedBy = "terraform"
  }
}

