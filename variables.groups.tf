variable "groups" {
  description = <<-EOT
    (Optional) Map of Entra ID (Azure AD) groups to create.

    Note: The workload identity is automatically assigned the App Role "User.ReadBasic.All" and "Group.Read.All"
          because being "Owner" of the group is not sufficient to add principals and then list them after an add or delete operation.

    Example:
    groups = {
      developers = {
        display_name     = "Application Developers"
        description      = "Group for application developers"
        security_enabled = true
        owners           = [data.azuread_client_config.current.object_id]
        members          = [azuread_user.dev1.object_id]
        role_assignments = {
          contributor = {
            scope                = azurerm_resource_group.example.id
            role_definition_name = "Contributor"
          }
        }
      }
      admins = {
        display_name       = "Kubernetes Administrators"
        description        = "Group for cluster administrators"
        security_enabled   = true
        assignable_to_role = true
        dynamic_membership = {
          enabled = true
          rule    = "user.department -eq \"IT\""
        }
      }
    }
  EOT
  type = map(object({
    display_name               = string
    description                = optional(string)
    mail_enabled               = optional(bool, false)
    mail_nickname              = optional(string)
    security_enabled           = optional(bool, true)
    types                      = optional(set(string))
    assignable_to_role         = optional(bool, false)
    behaviors                  = optional(set(string))
    external_senders_allowed   = optional(bool, false)
    hide_from_address_lists    = optional(bool, true)
    hide_from_outlook_clients  = optional(bool, true)
    owners                     = optional(set(string))
    members                    = optional(set(string))
    prevent_duplicate_names    = optional(bool, false)
    auto_subscribe_new_members = optional(bool, false)
    theme                      = optional(string)
    visibility                 = optional(string)
    writeback_enabled          = optional(bool, false)
    onpremises_group_type      = optional(string)
    dynamic_membership = optional(object({
      enabled = bool
      rule    = string
    }))
    role_assignments = optional(map(object({
      scope                = string
      role_definition_id   = optional(string)
      role_definition_name = optional(string)
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.groups : (v.mail_enabled || v.security_enabled)
    ])
    error_message = "At least one of 'mail_enabled' or 'security_enabled' must be true for each group."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.groups : [
        for rk, rv in v.role_assignments : (
          (rv.role_definition_id != null && rv.role_definition_name == null) ||
          (rv.role_definition_id == null && rv.role_definition_name != null)
        )
      ]
    ]))
    error_message = "Each role assignment must specify exactly one of 'role_definition_id' or 'role_definition_name', not both."
  }
}
