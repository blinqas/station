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

  type = map(object({
    name                = string
    resource_group_name = optional(string)
    location            = optional(string)
    role_assignments    = optional(list(string))
    group_membership    = optional(set(string))
  }))

  default = {}
}


variable "tfe" {
  description = "Terraform Cloud configuration. See submodule ./hashicorp/tfe/variables.tf for settings"
  default     = null
  type = object({
    organization_name                    = string
    project_name                         = string
    workspace_name                       = string
    workspace_description                = string
    create_federated_identity_credential = optional(bool)
    vcs_repo = optional(object({
      identifier                 = string
      branch                     = optional(string)
      ingress_submodules         = optional(string)
      oauth_token_id             = optional(string)
      github_app_installation_id = optional(string)
      tags_regex                 = optional(string)
    }))
    workspace_env_vars = optional(map(object({
      value       = string
      category    = string
      description = string
    })))
    workspace_vars = optional(map(object({
      value       = any
      category    = string
      description = string
      hcl         = bool
      sensitive   = bool
    })))
    module_outputs_to_workspace_var = optional(object({
      groups                   = optional(bool)
      applications             = optional(bool)
      user_assigned_identities = optional(bool)
    }))
  })
}

variable "group_membership" {
  type        = list(string)
  description = "List of group object ids the workload identity should be member of"
  default     = []
}

variable "role_assignment" {
  type = map(object({
    name                                   = optional(string)
    scope                                  = string
    role_definition_id                     = optional(string)
    role_definition_name                   = optional(string)
    principal_id                           = optional(string) # If null, user must set assign_to_workload_principal
    assign_to_workload_principal           = optional(bool)
    condition                              = optional(string)
    condition_version                      = optional(string)
    delegated_managed_identity_resource_id = optional(string)
    description                            = optional(string)
    skip_service_principal_aad_check       = optional(bool)
  }))
  description = "Map of azurerm_role_assignments"
  default     = {}
}
