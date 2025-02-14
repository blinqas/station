output "id" {
  value = azurerm_user_assigned_identity.identity.id
}

output "client_id" {
  value = azurerm_user_assigned_identity.identity.client_id
}

output "principal_id" {
  value = azurerm_user_assigned_identity.identity.principal_id
}

output "tenant_id" {
  value = azurerm_user_assigned_identity.identity.tenant_id
}

output "identity" {
  value = merge(
    azurerm_user_assigned_identity.identity, # Flatten identity properties to the root
    {
      role_assignments = azurerm_role_assignment.roles
      app_role_assignments = {
        for k, v in azuread_app_role_assignment.app_workload_roles : k => {
          app_role_id         = v.app_role_id
          principal_object_id = v.principal_object_id
          resource_object_id  = v.resource_object_id
        }
      }
      group_memberships = {
        for k, v in azuread_group_member.uai : k => v.group_object_id
      }
    }
  )
  description = "Outputs the full identity object including role assignments, app role assignments, and group memberships"
}

