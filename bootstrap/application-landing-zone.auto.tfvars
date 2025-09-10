config = {
  # az account show --query tenantId -o tsv
  tenant_id = ""
  # az account show --query id -o tsv
  subscription_id = ""
  # The name of the resource group to install Station. Station prefixes this with `rg-`
  resource_group_name = "alz-applications"
  # The name of the Managed Identity which will deploy further Landing Zones
  identity_name = "mi-alz-applications"

  terraform_cloud = { # Terraform Cloud Configuration
    organization_name               = ""
    workspace_name                  = "alz-applications"
    workspace_description           = "Application Landing Zone definitions"
    bootstrap_workspace_name        = "alz-applications-bootstrap"
    bootstrap_workspace_description = "Bootstrap for Application Landing Zones"
    vcs_repo_github_oauth_token_id  = "" # OAuth App ID (https://github.com/organizations/<org_name>/settings/applications/<app_id_here>)
    project = {
      name        = "Azure Application Landing Zones"
      description = "Azure Application Landing Zones"
    }
  }

  github = {
    owner       = "" # Organization
    repository  = "alz-applications"
    description = "Terraform Configuration for Application Landing Zones"
    branch      = "main"

    # Bootstrap
    bootstrap_repository  = "alz-applications-bootstrap"
    bootstrap_description = "Terraform Configuration for Bootstrap of Azure Application Landing Zones"
    bootstrap_branch      = "main"

    provider = {           # Station Landing Zones GitHub App (Not VCS App)
      id              = "" #1234567
      installation_id = "" #12345678
    }
    pem_file_path = "./station-landing-zones.pem" # Path to private key used to create the 
  }

  tags = {
    owner      = "Platform Engineering"
    deployedBy = "terraform"
  }
}

