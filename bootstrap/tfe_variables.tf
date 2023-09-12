resource "tfe_variable" "deployments" {
  for_each     = local.env_vars
  key          = each.key
  value        = each.value.value
  category     = "env"
  workspace_id = tfe_workspace.deployments.id
  description  = each.value.description
}

# These are set to enable authentication between Terraform Cloud and Azure with OIDC.
locals {
  env_vars = {
    TFC_AZURE_PROVIDER_AUTH = {
      value       = true
      description = "Is true when using dynamic credentials to authenticate to Azure. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-terraform-cloud"
    },
    TFC_AZURE_RUN_CLIENT_ID = {
      value       = azuread_service_principal.workload.application_id
      description = "The client ID for the Service Principal / Application used when authenticating to Azure. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-terraform-cloud"
    },
    ARM_SUBSCRIPTION_ID = {
      value       = data.azurerm_client_config.current.subscription_id
      description = "The Subscription ID to connect to. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-the-azurerm-or-azuread-provider"
    },
    ARM_TENANT_ID = {
      value       = data.azurerm_client_config.current.tenant_id
      description = "The Azure Tenant ID to connect to. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-the-azurerm-or-azuread-provider"
    },
  }
}
