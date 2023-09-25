resource "azurerm_resource_group" "workload" {
  name     = "rg-${random_id.workload.hex}-${var.environment_name}"
  location = var.default_location
  tags     = local.tags
}

resource "azurerm_resource_group" "user_specified" {
  for_each = var.resource_groups
  name     = "rg-${random_id.workload.hex}-${each.key}-${var.environment_name}"
  location = each.value.location == null ? var.default_location : each.value.location
  tags = merge(
    each.value.tags == null ? {} : each.value.tags,
    local.tags
  )
}

