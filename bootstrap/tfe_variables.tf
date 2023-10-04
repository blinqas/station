resource "tfe_variable" "deployments" {
  for_each     = local.env_vars
  key          = each.key
  value        = each.value.value
  category     = each.value.category
  sensitive    = each.value.sensitive
  workspace_id = tfe_workspace.deployments.id
  description  = each.value.description
}

# These are set to enable authentication between Terraform Cloud and Azure with OIDC.
locals {
  base_env_vars = {
    TFC_AZURE_PROVIDER_AUTH = {
      value       = true
      description = "Is true when using dynamic credentials to authenticate to Azure. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-terraform-cloud"
      sensitive   = false
      category    = "env"
    },
    TFC_AZURE_RUN_CLIENT_ID = {
      value       = azuread_service_principal.workload.application_id
      description = "The client ID for the Service Principal / Application used when authenticating to Azure. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-terraform-cloud"
      sensitive   = false
      category    = "env"
    },
    ARM_SUBSCRIPTION_ID = {
      value       = data.azurerm_client_config.current.subscription_id
      description = "The Subscription ID to connect to. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-the-azurerm-or-azuread-provider"
      sensitive   = false
      category    = "env"
    },
    ARM_TENANT_ID = {
      value       = data.azurerm_client_config.current.tenant_id
      description = "The Azure Tenant ID to connect to. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-the-azurerm-or-azuread-provider"
      sensitive   = false
      category    = "env"
    },
    GITHUB_OWNER = {
      value       = var.vcs_repo_owner
      description = "Name of the GitHub Organization to manage. https://registry.terraform.io/providers/integrations/github/latest/docs#owner"
      sensitive   = false
      category    = "env"
    },
    GITHUB_TOKEN = {
      value       = var.vcs_repo_PAT
      description = "Personal access token from Github"
      sensitive   = true
      category    = "env"
    },
    TFE_ORGANIZATION = {
      value       = var.tfc_organization_name
      description = "Name of the Terraform Cloud organization to manage"
      sensitive   = false
      category    = "env"
    },
    TFE_TOKEN = {
      value       = var.tfc_token
      description = "Terraform access token for the 'owners' team."
      sensitive   = true
      category    = "env"
    }
  }

  optional_env_vars = merge(
    var.vcs_repo_github_app_installation_id != null ? {
      vcs_repo_github_app_installation_id = {
        value       = var.vcs_repo_github_app_installation_id
        description = "The Github application ID used to authenticate with Github for org ${var.vcs_repo_owner}"
        sensitive   = false
        category    = "terraform"
      }
    } : {},

    var.vcs_repo_oauth_token_id != null ? {
      vcs_repo_oauth_token_id = {
        value       = var.vcs_repo_oauth_token_id
        description = "The oauth token ID used to authenticate with Github for org ${var.vcs_repo_owner}"
        sensitive   = false
        category    = "terraform"
      }
    } : {}
  )

  env_vars = merge(local.base_env_vars, local.optional_env_vars)
}
