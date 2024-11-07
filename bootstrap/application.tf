resource "azuread_application" "workload" {
  display_name = var.station_entraID_application_name
  notes        = "This application is used to create new workloads using the station module"
}


