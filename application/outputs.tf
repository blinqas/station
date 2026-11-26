output "application" {
  value = merge(azuread_application.this, {
    identifier_uris = msgraph_update_resource.this.body.identifierUris
  })
}

output "service_principal" {
  value = azuread_service_principal.this
}
output "app_role_assignments" {
  value = azuread_app_role_assignment.this
}

output "preauthorized_clients" {
  description = "Client preauthorizations keyed by their input map keys."
  value       = azuread_application_pre_authorized.this
}

output "group_assignments" {
  description = "Group app role assignments keyed by their input map keys."
  value       = azuread_app_role_assignment.groups
}
