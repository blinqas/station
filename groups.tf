module "ad_groups" {
  for_each = var.groups
  source   = "./group"
  settings = each.value.settings
}

