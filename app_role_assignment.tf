data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "msgraph" {
  client_id    = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing = true
}

/*  
  Assign the workload identity the `Application.ReadWrite.OwnedBy` role, 
  so it can interact with the applications they own however they desire
*/
resource "azuread_app_role_assignment" "app_workload_roles" {
  count               = length(var.applications) > 0 ? 1 : 0
  app_role_id         = azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.OwnedBy"]
  principal_object_id = module.user_assigned_identity.principal_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}

/* 
  As of now, when a service principal is an owner of a group, certain functionality using the MS Graph works with no addtional grants, 
  such as add/remove member and get a group's specific detail. 
  However it is not possible to list members of the group that they own or get a list of groups that they own, 
  without granting permissions such as 
  Group.Read.All/GroupMember.Read.All/Group.ReadWrite.All/GroupMember.ReadWrite.All.

  See https://techcommunity.microsoft.com/t5/microsoft-365-developer-platform/provided-quot-ownedby-quot-permissions-for-groups-and/idi-p/3846345 for more details
*/
resource "azuread_app_role_assignment" "group_read_all_workload_roles" {
  count               = length(var.groups) > 0 ? 1 : 0
  app_role_id         = azuread_service_principal.msgraph.app_role_ids["Group.Read.All"]
  principal_object_id = module.user_assigned_identity.principal_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}