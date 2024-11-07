resource "azuread_application" "workload" {
  display_name = "station-deployments"
  notes        = "This application is used to create new workloads using the station module"
}


