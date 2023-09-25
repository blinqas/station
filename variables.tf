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
  type = map(object({
    name     = string
    location = optional(string)
    tags     = optional(map(string))
  }))
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
  type = map(object({
    display_name                   = string
    owners                         = optional(list(string))
    sign_in_audience               = optional(string)
    group_membership_claims        = optional(list(string))
    identifier_uris                = optional(list(string))
    prevent_duplicate_names        = optional(bool)
    fallback_public_client_enabled = optional(bool)

    single_page_application = optional(object({
      redirect_uris = optional(list(string))
    }))

    api = optional(object({
      known_client_applications      = optional(list(string))
      mapped_claims_enabled          = optional(bool)
      requested_access_token_version = optional(number)

      oauth2_permission_scope = optional(list(object({
        admin_consent_description  = string
        admin_consent_display_name = string
        id                         = string
        enabled                    = optional(bool)
        type                       = optional(string)
        user_consent_description   = optional(string)
        user_consent_display_name  = optional(string)
        value                      = string
      })))
    }))

    required_resource_access = optional(set(object({
      resource_app_id = string
      resource_access = map(object({
        id   = string
        type = string
      }))
    })))

    optional_claims = optional(object({
      access_token = optional(set(object({
        name                  = string
        source                = optional(string)
        essential             = optional(bool)
        additional_properties = optional(list(string))
      })))
      id_token = optional(set(object({
        name                  = string
        source                = optional(string)
        essential             = optional(bool)
        additional_properties = optional(list(string))
      })))
      saml2_token = optional(set(object({
        name                  = string
        source                = optional(string)
        essential             = optional(bool)
        additional_properties = optional(list(string))
      })))
    }))

    web = optional(object({
      homepage_url  = optional(string)
      logout_url    = optional(string)
      redirect_uris = optional(set(string))
      implicit_grant = optional(object({
        access_token_issuance_enabled = optional(bool)
        id_token_issuance_enabled     = optional(bool)
      }))
    }))
  }))
}

variable "groups" {
  description = "Map of Azure AD groups to create"
  default     = {}
  type = map(object({
    display_name     = string
    owners           = optional(list(string))
    members          = optional(set(string))
    security_enabled = optional(bool)
    mail_enabled     = optional(bool)
    types            = optional(set(string))
    dynamic_membership = optional(object({
      enabled = bool
      rule    = string
    }))
  }))
}



variable "user_assigned_identities" {
  description = "User Assigned Identities to create."
  default     = {}
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
