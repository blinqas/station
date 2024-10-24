resource "tfe_variable" "workload" {
  for_each     = var.workspace_vars
  key          = each.key
  value        = each.value.value
  description  = each.value.description
  category     = each.value.category
  workspace_id = tfe_workspace.workload.id
  hcl          = try(each.value.hcl, false)
  sensitive    = each.value.sensitive
}

data "tfe_variables" "workload" {
  workspace_id = tfe_workspace.workload.id
  depends_on   = [tfe_variable.workload]
}


locals {
  #Restructure the output so it's possible to create terraform tests
  tfc_variables = { for v in data.tfe_variables.workload.variables : v.name => {
    category  = v.category
    hcl       = v.hcl
    id        = v.id
    sensitive = v.sensitive
    value     = v.value
  } }
}