# Assign the Landing Zone identity Owner on this Landing Zone's resource groups
moved {
  from = azurerm_role_assignment.rg_workload_owner
  to   = azurerm_role_assignment.lz_owner
}

resource "azurerm_role_assignment" "lz_owner" {
  for_each             = merge({ default = azurerm_resource_group.workload }, azurerm_resource_group.user_specified)
  scope                = each.value.id
  principal_id         = module.user_assigned_identity.principal_id
  role_definition_name = "Owner"
}

// Role Assignments for the Landing Zone identity (via var.identity.role_assignments)
resource "azurerm_role_assignment" "lz_identity" {
  for_each                               = local.role_assignments_merged
  name                                   = each.value.name
  scope                                  = each.value.scope
  role_definition_id                     = each.value.role_definition_id
  role_definition_name                   = each.value.role_definition_name
  principal_id                           = module.user_assigned_identity.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  description                            = each.value.description
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

// Role Assignments for user specified principal IDs (not the Landing Zone identity (var.identity) OR the var.user_assigned_identities)
resource "azurerm_role_assignment" "others" {
  for_each                               = var.role_assignments
  name                                   = each.value.name
  scope                                  = each.value.scope
  role_definition_id                     = each.value.role_definition_id
  role_definition_name                   = each.value.role_definition_name
  principal_id                           = each.value.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  description                            = each.value.description
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

locals {
  // Collect all role_assignments without a defined scope, and set a default scope
  // to the resource group of the Landing Zone
  role_assignments = {
    for k, v in var.identity.role_assignments : k => merge(v, {
      // Inject default value for scope
      scope = azurerm_resource_group.workload.id
    }) if v.scope == null
  }

  ra = {
    // Create new role assignments for the additional resource groups and set the scope to the resource created by Azure
    for k, v in azurerm_resource_group.user_specified : k => {
      for kk, vv in local.role_assignments : "${kk}-${v.name}" => merge(vv, {
        // This is a new role assignment, so set the scope to the resource group we are creating for
        scope = v.id
      })
    }
  }

  // Samle alle role_assignments som har spesifisert et scope
  // Collect all role_assignments _with_ a scope
  role_assignments_with_defined_scope = { for k, v in var.identity.role_assignments : k => v if v.scope != null }

  // Collect all created role_assignments created for the Landing Zone identity
  role_assignments_merged = merge(local.role_assignments, local.role_assignments_with_defined_scope, tomap({
    for ra in flatten([
      for rgKey, rg in local.ra : [
        for raKey, ra in rg : merge(ra, { composite_key = raKey })
      ]
  ]) : ra.composite_key => ra }))
}

