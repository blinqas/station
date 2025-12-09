variable "identity" {
  description = <<EOF
  Configuration for the workload identity. This is the identity that is used to perform the Terraform plan and apply operations.

  Example:
  identity = {
    name = "workload-prod" #Name will be prefixed with `mi-`

    role_assignments = {
      key_vault_admin = {
        scope = null # Defaults to the resource groups created by the workload
        role_definition_name = "Key Vault Administrator"
        description = "Needed to manage key vaults"
      }
    }

    app_role_assignments = {
      "User.ReadBasic.All" = {
        app_role_id        = data.azuread_service_principals.well_known["MicrosoftGraph"].app_role_ids["User.ReadBasic.All"]
        resource_object_id = data.azuread_service_principals.well_known["MicrosoftGraph"].object_id
      }
    }

    group_memberships    = {
      "A group" = "ad-group-object-id"
    }

    directory_role_assignments = {
      Reader = {
        role_name = "Directory Readers"
      }
    }
  }
  EOF
  default     = {}
  type = object({
    name = optional(string)
    role_assignments = optional(map(object({
      name                                   = optional(string)
      scope                                  = optional(string)
      role_definition_id                     = optional(string)
      role_definition_name                   = optional(string)
      condition                              = optional(string)
      condition_version                      = optional(string)
      delegated_managed_identity_resource_id = optional(string)
      description                            = optional(string)
      skip_service_principal_aad_check       = optional(bool)

      pim = optional(object({
        member_type     = optional(string, "Eligible")
        start_date_time = optional(string)
        expiration = optional(object({
          duration_days  = optional(number)
          duration_hours = optional(number)
          end_date_time  = optional(string)
        }))
        justification = optional(string)
        ticket_number = optional(string)
        ticket_system = optional(string)
      }))
    })), {})
    group_memberships = optional(map(string), {})
    app_role_assignments = optional(map(object({
      app_role_id        = string
      resource_object_id = string
    })), {})
    directory_role_assignments = optional(map(object({
      role_name          = optional(string)
      role_id            = optional(string)
      app_scope_id       = optional(string)
      directory_scope_id = optional(string)
    })), {})
  })

  validation {
    condition     = alltrue([for k, v in var.identity.directory_role_assignments : !(v.app_scope_id != null && v.directory_scope_id != null)])
    error_message = "directory_role_assignments: `app_scope_id` cannot be used with `directory_scope_id`."
  }

  validation {
    condition     = alltrue([for k, v in var.identity.directory_role_assignments : !(v.role_name != null && v.role_id != null)])
    error_message = "directory_role_assignments: `role_name` cannot be used with `role_id`."
  }
}

