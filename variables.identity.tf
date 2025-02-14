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
    app_role_assignments = ["User.Read.All"]
    group_memberships    = {
      "A group" = "ad-group-object-id"
    }
    directory_role_assignment = {
      Reader = {
        role_name = "Directory Readers"
      }
    }
  }
  EOF
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
    })), {})
    group_memberships    = optional(map(string), {})
    app_role_assignments = optional(set(string), [])
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

