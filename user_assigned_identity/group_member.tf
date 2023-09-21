# Add the User Assigned Identity to each group
resource "azuread_group_member" "uai" {
  for_each         = var.group_membership
  group_object_id  = each.key
  member_object_id = azurerm_user_assigned_identity.identity.principal_id
}