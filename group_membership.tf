resource "azuread_group_member" "workload" {
  for_each         = var.group_membership
  group_object_id  = each.value
  member_object_id = module.user_assigned_identity.principal_id
}

