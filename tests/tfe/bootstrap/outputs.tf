output "client_id" {
  value = azuread_service_principal.workload.application_id
}

output "tenant_id" {
  value = data.azuread_client_config.current.tenant_id
}

output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "state_resource_group_name" {
  value = var.state_resource_group_name
}

output "state_storage_account_name" {
  value = azurerm_storage_account.state.name
}

output "state_storage_container_name" {
  value = azurerm_storage_container.state.name
}