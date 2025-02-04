output "client_id" {
  value = module.user_assigned_identity.client_id
}

output "workload_service_principal_object_id" {
  value = module.user_assigned_identity.principal_id
}

output "tenant_id" {
  value = var.tenant_id
}

output "subscription_id" {
  value = var.subscription_id
}

output "workload_resource_group_name" {
  value = azurerm_resource_group.workload.name
}

output "resource_group" {
  value = azurerm_resource_group.workload
}

output "resource_groups_user_specified" {
  value = azurerm_resource_group.user_specified
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

