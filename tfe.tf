module "station-tfe" {
  source = "./hashicorp/tfe/"

  project_name          = var.tfe.project_name
  workspace_name        = var.tfe.workspace_name
  workspace_description = var.tfe.workspace_description
  vcs_repo              = try(var.tfe.vcs_repo, null)
  env_vars = merge(try(var.tfe.env_vars, {}), {
    # Terraform variables are prefixed with TF_VAR_ to suppress TFC Runner warning of unused variables.
    TF_VAR_station_id = {
      value       = random_id.workload.hex
      category    = "env"
      description = "Station ID"
    },
    TF_VAR_workload_resource_group_name = {
      value       = azurerm_resource_group.workload.name
      category    = "env"
      description = "Name of the resource group created by Station"
    },
    TF_VAR_environment_name = {
      value       = var.environment_name
      category    = "env"
      description = "Name of the current deployment environment. Often dev/test/stage/prod."
    },
    # DOCS: https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-terraform-cloud
    TFC_AZURE_PROVIDER_AUTH = {
      value       = true
      category    = "env"
      description = "Is true when using dynamic credentials to authenticate to Azure. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-terraform-cloud"
    },
    TFC_AZURE_RUN_CLIENT_ID = {
      value       = azuread_service_principal.workload.application_id
      category    = "env"
      description = "The client ID for the Service Principal / Application used when authenticating to Azure. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-terraform-cloud"
    },
    ARM_SUBSCRIPTION_ID = {
      value       = data.azurerm_client_config.current.subscription_id
      category    = "env"
      description = "The Subscription ID to connect to. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-the-azurerm-or-azuread-provider"
    },
    ARM_TENANT_ID = {
      value       = data.azurerm_client_config.current.tenant_id
      category    = "env"
      description = "The Azure Tenant ID to connect to. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-the-azurerm-or-azuread-provider"
    },
    },

    # Optionals
    try(var.tfe.env_vars.groups.pass_to_workspace, false) ? {
      TF_VAR_groups = {
        value = { for k, v in module.ad_groups : k => {
          display_name = v[k].display_name
          object_id    = v[k].object_id
        } }
        category    = "env"
        description = "Groups provisioned by Station"
      }
    } : null
  )
}

