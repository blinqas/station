resource "azuread_application" "workload" {
  display_name = "app-station-tfe-tests"
  notes        = "This application tests Station TFE tests (github.com/kimfy/Station.git) from TFC to Azure"
}


