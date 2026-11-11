terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.65"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "subscription_id" {
  description = "Workload test subscription; must differ from the fixture's connectivity provider."
  type        = string
  nullable    = false
}

variable "tenant_id" {
  description = "Workload tenant; the connectivity provider must use the same tenant."
  type        = string
  nullable    = false
}

resource "random_id" "this" {
  byte_length = 4
}

data "azurerm_client_config" "this" {}

resource "azurerm_resource_group" "this" {
  name     = "rg-stationtest-dns-${random_id.this.hex}"
  location = "norwayeast"

  lifecycle {
    precondition {
      condition     = lower(data.azurerm_client_config.this.subscription_id) != lower(var.subscription_id)
      error_message = "Use separate approved non-production workload and connectivity subscriptions for this integration test."
    }
    precondition {
      condition     = lower(data.azurerm_client_config.this.tenant_id) == lower(var.tenant_id)
      error_message = "The workload and connectivity test subscriptions must use the same tenant."
    }
  }
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = toset(["shared", "other"])
  name                = "${each.key}-${random_id.this.hex}.station.test"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_a_record" "this" {
  for_each            = azurerm_private_dns_zone.this
  name                = "sentinel"
  zone_name           = each.value.name
  resource_group_name = azurerm_resource_group.this.name
  ttl                 = 300
  records             = ["10.1.0.10"]
}

output "zones" {
  value = azurerm_private_dns_zone.this
}

output "records" {
  value = azurerm_private_dns_a_record.this
}

output "subscription_id" {
  value = data.azurerm_client_config.this.subscription_id
}

output "tenant_id" {
  value = data.azurerm_client_config.this.tenant_id
}

output "suffix" {
  value = random_id.this.hex
}
