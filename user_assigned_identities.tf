locals {
  /* Ensure Managed Identity has required permissions to read basic user information
     when the caller wants to create Entra ID Groups. Having only "Owner" on the group
    is not sufficient (even though the Terraform Provider docs says so).

    "Group.Read.All" is required to list groups members as beein the owner of a group is not sufficient.
  */
  required_app_roles = merge(
    // Ensure Managed Identity has required permissions to read basic user information when the caller wants to create Entra ID Groups. Having only "Owner" on the group is not sufficient (even though the Terraform Provider docs says so).
    length(var.groups) == 0 ? {} : {
      "User.ReadBasic.All" = {
        app_role_id        = data.azuread_service_principal.msgraph.app_role_ids["User.ReadBasic.All"]
        resource_object_id = data.azuread_service_principal.msgraph.object_id
      }
      "Group.Read.All" = {
        app_role_id        = data.azuread_service_principal.msgraph.app_role_ids["Group.Read.All"]
        resource_object_id = data.azuread_service_principal.msgraph.object_id
      }
    },

    # When `var.applications` is specified, ensure the Landing Zone Identity have the correct permissions so it can manage it in their landing zone configuration.
    length(var.applications) == 0 ? {} : {
      "Application.ReadWrite.OwnedBy" = {
        app_role_id        = data.azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.OwnedBy"]
        resource_object_id = data.azuread_service_principal.msgraph.object_id
      }
    }
  )
}

moved {
  from = azuread_app_role_assignment.app_workload_roles
  to   = module.user_assigned_identity.azuread_app_role_assignment.this["Application.ReadWrite.OwnedBy"]
}

module "user_assigned_identity" {
  name                       = var.identity.name == null ? "mi-${var.tfe.workspace_name}" : var.identity.name
  source                     = "./user_assigned_identity"
  resource_group_name        = azurerm_resource_group.workload.name
  location                   = azurerm_resource_group.workload.location
  app_role_assignments       = merge(var.identity.app_role_assignments, local.required_app_roles)
  directory_role_assignments = var.identity.directory_role_assignments
  group_memberships          = var.identity.group_memberships
  tags                       = local.tags
}

#moved {
#  from = azuread_app_role_assignment.app_workload_roles
#  to   = azuread_app_role_assignment.this
#}

#resource "azuread_app_role_assignment" "this" {
#  for_each            = local.required_app_roles
#  app_role_id         = each.value.app_role_id
#  principal_object_id = module.user_assigned_identity.principal_id
#  resource_object_id  = data.azuread_service_principal.msgraph.object_id
#}

module "user_assigned_identities" {
  for_each                   = var.user_assigned_identities
  source                     = "./user_assigned_identity"
  name                       = each.value.name
  resource_group_name        = each.value.resource_group_name == null ? azurerm_resource_group.workload.name : each.value.resource_group_name
  location                   = each.value.location == null ? azurerm_resource_group.workload.location : each.value.location
  role_assignments           = each.value.role_assignments
  app_role_assignments       = each.value.app_role_assignments
  directory_role_assignments = each.value.directory_role_assignments
  group_memberships          = each.value.group_memberships
  tags                       = local.tags
}

