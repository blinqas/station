resource "azuread_application" "workload" {
  display_name = "app-station-github-workflow-tests"
  notes        = "This application deploys the tests under tests/bootstrap in https://github.com/kimfy/station.git"
}


