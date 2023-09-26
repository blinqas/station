resource "azuread_group_member" "workload" {
  for_each         = toset(var.group_membership)
  group_object_id  = each.key
  member_object_id = module.user_assigned_identity.principal_id
}

