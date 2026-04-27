variable "subscription_id" {
  type    = string
  default = null
}

variable "connectivity_subscription_id" {
  type    = string
  default = null
}

output "subscription_id" {
  value = var.subscription_id
}

output "connectivity_subscription_id" {
  value = var.connectivity_subscription_id
}

