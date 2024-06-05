variable "tfc_organization_name" {
  type        = string
  description = "(Required) The name of the Terraform Cloud organization to use"
}

variable "tfc_project_name" {
  type        = string
  description = "(Required) The name of the Terraform Cloud project to create"
}

variable "tenant_id" {
  type        = string
  description = "(Required) The Entra ID tenant ID used by the caller."
}

variable "subscription_id" {
  type        = string
  description = "(Required) The Azure subscription ID used by the caller."
}

