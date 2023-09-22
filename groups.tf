module "ad_groups" {
  for_each = var.groups

  source             = "./group"
  display_name       = each.value.display_name
  owners             = try(each.value.owners, toset([]))
  members            = try(each.value.members, toset([]))
  security_enabled   = each.value.security_enabled != null ? each.value.security_enabled : true
  types              = each.value.types
  dynamic_membership = try(each.value.dynamic_membership, [])
}
