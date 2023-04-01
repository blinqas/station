output "client_id" {
  value = azuread_service_principal.workload.application_id
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
  value = module.caf_applications
}

output "groups" {
  value = module.ad_groups
}
