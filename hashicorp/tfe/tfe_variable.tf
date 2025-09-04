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

resource "tfe_variable_set" "global" {
  name         = "Global Environment Variables"
  description  = "Common environment variables for all workspaces"
  organization = var.organization_name
  global       = true
}

resource "tfe_variable" "global" {
  for_each        = var.global_vars
  key             = each.key
  value           = each.value.value
  description     = each.value.description
  category        = each.value.category
  variable_set_id = tfe_variable_set.global.id
  hcl             = try(each.value.hcl, false)
  sensitive       = try(each.value.sensitive, false)
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