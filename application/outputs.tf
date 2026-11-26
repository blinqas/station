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
