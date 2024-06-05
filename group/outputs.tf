output "group" {
  value = azuread_group.group
}

output "display_name" {
  value = azuread_group.group.display_name
}

output "group_with_roles" {
  value = {
    group_id           = azuread_group.group.object_id
    display_name       = azuread_group.group.display_name
    security_enabled   = azuread_group.group.security_enabled
    mail_enabled       = azuread_group.group.mail_enabled
    types              = azuread_group.group.types
    owners             = var.owners
    dynamic_membership = var.azuread_group.dynamic_membership
    members            = [for member in azuread_group_member.members : member.member_object_id]
    role_assignments = {
      for role, details in azurerm_role_assignment.roles : role => {
        role_name                              = details.role_definition_name
        scope                                  = details.scope
        role_id                                = details.role_definition_id
        description                            = details.description
        condition                              = details.condition
        condition_version                      = details.condition_version
        delegated_managed_identity_resource_id = details.delegated_managed_identity_resource_id
        skip_service_principal_aad_check       = details.skip_service_principal_aad_check
      }
    }
  }
  description = "Output the Azure AD group with its role assignments."
}



output "object_id" {
  value = azuread_group.group.object_id
}

