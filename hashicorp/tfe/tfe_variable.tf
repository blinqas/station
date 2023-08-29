resource "tfe_variable" "workload" {
  for_each    = var.env_vars
  key         = each.key
  value       = each.value.value
  description = each.value.description
  category    = each.value.category
}
