output "client_id" {
  value = azuread_service_principal.workload.application_id
}

output "workload_service_principal_object_id" {
  value = azuread_service_principal.workload.object_id
}

output "tenant_id" {
  value = data.azuread_client_config.current.tenant_id
}

output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "workload_resource_group_name" {
  value = azurerm_resource_group.workload.name
}

output "applications" {
  value = module.applications
}

output "groups" {
  value = module.ad_groups
}

output "user_assigned_identities" {
  value = module.user_assigned_identities
}

output "tfe" {
  value = module.station-tfe
}

output "tfe_projects" {
  value = module.tfe-projects.tfe_projects
}
