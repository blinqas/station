# Add the User Assigned Identity to each group
resource "azuread_group_member" "uai" {
  for_each         = var.group_memberships
  group_object_id  = each.value
  member_object_id = azurerm_user_assigned_identity.identity.principal_id
}

