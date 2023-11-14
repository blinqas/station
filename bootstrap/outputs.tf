output "client_id" {
  value = azuread_service_principal.workload.client_id
}

output "tenant_id" {
  value = data.azuread_client_config.current.tenant_id
}

output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "tfc_organization_name" {
  value = data.tfe_organization.this.name
}

output "tfc_project_name" {
  value = tfe_project.station.name
}

output "tfc_deployments_workspace_name" {
  value = tfe_workspace.deployments.name
}

output "tfc_bootstrap_workspace_name" {
  value = tfe_workspace.bootstrap.name
}

