resource "azuread_service_principal" "workload" {
  application_id = azuread_application.workload.application_id
}

