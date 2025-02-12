data "azuread_client_config" "current" {}

output "current" {
  value = data.azuread_client_config.current
}

resource "random_uuid" "min" {
}

output "uuid_min" {
  value = random_uuid.min
}

resource "random_uuid" "max" {
}


output "uuid_max" {
  value = random_uuid.max
}