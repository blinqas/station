resource "azurerm_resource_group" "workload" {
  name     = "rg-${random_id.workload.hex}-${var.environment_name}"
  location = "norwayeast"
}

