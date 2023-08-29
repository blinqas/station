variable "default_location" {
  type        = string
  description = "The name of the default location to deploy workload resources to."
  default     = "norwayeast"
}

variable "environment_name" {
  type        = string
  description = "The name of the current environment. Ex: dev/staging/production"
  default     = "dev"
}

variable "role_definition_name_on_workload_rg" {
  type        = string
  description = "Which role to assign the workload Service Principal on the workload Resource Group"
  default     = "Owner"
}

variable "resource_groups" {
  description = "Resource Groups to create."
  default     = {}
}

variable "federated_identity_credential_config" {
  description = "The Application Federated Identity Credential configuration. Configure this for secret-less automation by setting create to `true` and filling in the object values."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to append to the default tags."
  default     = {}
}

variable "applications" {
  description = "Applications to create. See https://registry.terraform.io/modules/aztfmod/caf/azurerm/5.7.0-preview0/submodules/applications?tab=inputs for documentation."
  default     = {}
}

variable "groups" {
  description = "List of Azure AD groups to create"
  default     = {}
}

variable "user_assigned_identities" {
  description = "User Assigned Identities to create."
  default     = {}
}

variable "tfe" {
  description = "Terraform Cloud configuration. See submodule ./hashicorp/tfe/variables.tf for settings"
  type = object({
    project_name          = string
    create_project        = optional(bool)
    workspace_name        = string
    workspace_description = string
    env_vars = map(object({
      value       = string
      category    = string
      description = string
    }))
  })
  default = {}
}

