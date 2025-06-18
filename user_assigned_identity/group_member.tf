# Add the User Assigned Identity to each group
resource "azuread_group_member" "uai" {
  for_each         = var.group_memberships
  group_object_id  = each.value
  member_object_id = azurerm_user_assigned_identity.identity.principal_id
  depends_on       = [time_sleep.this]
}

resource "terraform_data" "this" {
  input = azurerm_user_assigned_identity.identity.id
}

resource "time_sleep" "this" {
  create_duration = "30s"
  depends_on      = [terraform_data.this]
}

