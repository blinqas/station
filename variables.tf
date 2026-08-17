variable "tenant_id" {
  type        = string
  description = "(Required) The Entra ID tenant ID used by the caller."
}

variable "subscription_id" {
  type        = string
  description = "(Required) The Azure subscription ID used by the caller."
}

variable "default_location" {
  description = "The name of the default location to deploy workload resources to."
  default     = "norwayeast"
  type        = string
}

variable "resource_group_name" {
  description = <<EOF
    The name of the workload resource group. The final name is prefixed with `rg-`.

    If a value is not provided, Station will set the name to `rg-var.tfe.workspace_name`
  EOF
  default     = null
  type        = string
}

variable "resource_groups" {
  description = "Map of resource groups to create"
  default     = {}
  type = map(object({
    name     = string
    location = optional(string)
    tags     = optional(map(string))
  }))
}

variable "tags" {
  description = <<EOF
    Tags to merge with the default tags configured by Station.

    Station configures the following map in tags.tf:
    {
      "station-id"  = random_id.workload.hex
    }
  EOF
  default     = {}
  type        = map(string)
}

variable "role_assignments" {
  description = <<EOF
    Map of role_assignments to create. Be careful of who is allowed to provision role_assignments, you might want to 
    consider Sentinel policies in TFC.
  EOF
  default     = {}
  type = map(object({
    name                                   = optional(string)
    scope                                  = string
    role_definition_id                     = optional(string)
    role_definition_name                   = optional(string)
    principal_id                           = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    delegated_managed_identity_resource_id = optional(string)
    description                            = optional(string)
    skip_service_principal_aad_check       = optional(bool, false)
  }))
}

