output "application" {
  value = azuread_application.this
}

output "service_principal" {
  value = azuread_service_principal.this
}
output "app_role_assignments" {
  value = azuread_app_role_assignment.this
}