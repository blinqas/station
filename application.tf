resource "azuread_application" "workload" {
  display_name = "app-${random_id.workload.hex}-${var.environment_name}"
}

