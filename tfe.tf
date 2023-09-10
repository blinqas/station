module "station-tfe" {
  source = "./hashicorp/tfe/"

  project_name          = var.tfe.project_name
  workspace_name        = var.tfe.workspace_name
  workspace_description = var.tfe.workspace_description
  env_vars = merge(try(var.tfe.env_vars, {}), {
    station_id = {
      value       = random_id.workload.hex
      category    = "terraform"
      description = "Station ID"
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
  })
  vcs_repo = try(var.tfe.vcs_repo, null)
}
