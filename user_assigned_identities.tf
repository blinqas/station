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
        app_role_id        = "97235f07-e226-4f63-ace3-39588e11d3a1"
        resource_object_id = var.management.msgraph_azuread_service_principal_object_id
      }
      "Group.Read.All" = {
        app_role_id        = "5b567255-7703-4780-807c-7be8301ae99b"
        resource_object_id = var.management.msgraph_azuread_service_principal_object_id
      }
    },

    # When `var.applications` is specified, ensure the Landing Zone Identity have the correct permissions so it can manage it in their landing zone configuration.
    length(var.applications) == 0 ? {} : {
      "Application.ReadWrite.OwnedBy" = {
        app_role_id = "18a4783c-866b-4cc7-a460-3d5e5662c884" # Application.ReadWrite.OwnedBy
      }
    }
  )
}

module "user_assigned_identity" {
  name                       = var.identity.name == null ? "mi-${var.tfe.workspace_name}-${var.environment_name}" : var.identity.name
  source                     = "./user_assigned_identity"
  resource_group_name        = azurerm_resource_group.workload.name
  location                   = azurerm_resource_group.workload.location
  tags                       = local.tags
  app_role_assignments       = var.identity.app_role_assignments
  group_memberships          = var.identity.group_memberships
  directory_role_assignments = var.identity.directory_role_assignments
}

moved {
  from = azuread_app_role_assignment.app_workload_roles
  to   = azuread_app_role_assignment.this
}

resource "azuread_app_role_assignment" "this" {
  for_each            = local.required_app_roles
  app_role_id         = each.value.app_role_id
  principal_object_id = module.user_assigned_identity.principal_id
  resource_object_id  = var.management.msgraph_azuread_service_principal_object_id
}

module "user_assigned_identities" {
  for_each                   = var.user_assigned_identities
  source                     = "./user_assigned_identity/"
  name                       = each.value.name
  resource_group_name        = each.value.resource_group_name == null ? azurerm_resource_group.workload.name : each.value.resource_group_name
  location                   = each.value.location == null ? azurerm_resource_group.workload.location : each.value.location
  tags                       = local.tags
  role_assignments           = each.value.role_assignments
  app_role_assignments       = each.value.app_role_assignments
  group_memberships          = each.value.group_memberships
  directory_role_assignments = each.value.directory_role_assignments
}

