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

output "name" {
  value = azurerm_user_assigned_identity.identity.name
}

output "location" {
  value = azurerm_user_assigned_identity.identity.location
}

output "role_assignments" { 
  value = azurerm_role_assignment.roles
}

output "app_role_assignments" { 
  value =  {
        for k, v in azuread_app_role_assignment.app_workload_roles : k => {
          app_role_id         = v.app_role_id
          principal_object_id = v.principal_object_id
          resource_object_id  = v.resource_object_id
        }
      }
}

output "group_memberships" {
  value = {
        for k, v in azuread_group_member.uai : k => v.group_object_id
      }
}