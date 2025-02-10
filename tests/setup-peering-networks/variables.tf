variable "remote_vnet_name" {
  type        = string
  description = "(Required) The name of the remote virtual network."
}
variable "remote_vnet_address_space" {
  type        = string
  description = "(Required) The address space for the Vnet."
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which the remote virtual network is located."
}

variable "location" {
  type        = string
  default     = "norwayeast"
  description = "(Required) The location/region where the remote virtual network should be located."

}
variable "tenant_id" {
  type        = string
  description = "(Required) The Entra ID tenant ID used by the caller."
}

variable "subscription_id" {
  type        = string
  description = "(Required) The Azure subscription ID used by the caller."
}


