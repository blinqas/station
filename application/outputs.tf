output "application" {
  value = azuread_application.app
}

output "service_principal" {
  value = azuread_service_principal.sp
}