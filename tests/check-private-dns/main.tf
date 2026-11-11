terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.65"
    }
  }
}

variable "zones" {
  description = "Fixture-owned zones to read again after Station removes its links."
  nullable    = false
  type = map(object({
    name                = string
    resource_group_name = string
  }))
}

data "azurerm_private_dns_zone" "this" {
  for_each            = var.zones
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
}

data "azurerm_private_dns_a_record" "this" {
  for_each            = var.zones
  name                = "sentinel"
  zone_name           = each.value.name
  resource_group_name = each.value.resource_group_name
}

output "zones" {
  value = data.azurerm_private_dns_zone.this
}

output "records" {
  value = data.azurerm_private_dns_a_record.this
}
