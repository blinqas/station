variable "groups" {
  description = <<-EOT
    A map of groups to create. The key is a custom identifier for the group.

    - `display_name` - (Required) The display name of the group.
    - `description` - (Optional) The description of the group.
    - `mail_enabled` - (Optional) Whether the group is mail-enabled. Defaults to `false`. At least one of `mail_enabled` or `security_enabled` must be specified. A group can be mail enabled and security enabled.
    - `mail_nickname` - (Optional) The mail alias for the group, unique in the organisation. Required for mail-enabled groups. Changing this forces a new resource to be created.
    - `security_enabled` - (Optional) Whether the group is a security group for controlling access to in-app resources. Defaults to `true`. At least one of `mail_enabled` or `security_enabled` must be specified. A group can be mail enabled and security enabled.
    - `types` - (Optional) A set of group types to configure for the group. Supported values are `DynamicMembership` and `Unified`. If `Unified` is included, the group will be a Microsoft 365 group. Changing this forces a new resource to be created.
    - `assignable_to_role` - (Optional) Indicates whether this group can be assigned to an Azure Active Directory role. Defaults to `false`. Changing this forces a new resource to be created.
    - `behaviors` - (Optional) A set of behaviors for a Microsoft 365 group. Possible values are `AllowOnlyMembersToPost`, `HideGroupInOutlook`, `SkipExchangeInstallCheck`, `SubscribeMembersToCalendarEventsDisabled`, `SubscribeNewGroupMembers` and `WelcomeEmailDisabled`. See [official documentation](https://learn.microsoft.com/en-us/graph/group-set-options) for more details. Changing this forces a new resource to be created.
    - `external_senders_allowed` - (Optional) Indicates whether people external to the organization can send messages to the group. Defaults to `false`. Only valid for Unified groups (Microsoft 365 groups).
    - `hide_from_address_lists` - (Optional) Indicates whether the group is displayed in certain parts of the Outlook user interface: in the Address Book, in address lists for selecting message recipients, and in the Browse Groups dialog for searching groups. Defaults to `true`. Only valid for Unified groups (Microsoft 365 groups).
    - `hide_from_outlook_clients` - (Optional) Indicates whether the group is displayed in Outlook clients, such as Outlook for Windows and Outlook on the web. Defaults to `true`. Only valid for Unified groups (Microsoft 365 groups).
    - `owners` - (Optional) A set of object IDs of principals that will be granted ownership of the group.
    - `members` - (Optional) A set of object IDs of principals that will be granted membership of the group.
    - `dynamic_membership` - (Optional) An optional block to configure dynamic membership for the group. Cannot be used with `members`. For additional information on `dynamic_membership`, see [dynamic_membership block](#dynamic_membership-block).
    - `role_assignments` - (Optional) A map of role assignments to create for the group. For additional information on `role_assignments`, see [role_assignments block](#role_assignments-block).
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
