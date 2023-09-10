resource "tfe_variable" "workload" {
  for_each     = merge(var.workspace_env_vars, var.workspace_vars)
  key          = each.key
  value        = each.value.value
  description  = each.value.description
  category     = each.value.category
  workspace_id = tfe_workspace.workload.id
}
