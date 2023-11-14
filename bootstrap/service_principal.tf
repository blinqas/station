resource "azuread_service_principal" "workload" {
  client_id = azuread_application.workload.client_id
}

