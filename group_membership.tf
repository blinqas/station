resource "azuread_group_member" "workload" {
  for_each         = toset(var.group_membership)
  group_object_id  = each.key
  member_object_id = azuread_service_principal.workload.object_id
}

