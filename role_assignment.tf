# Assign the Landing Zone identity Owner on this Landing Zone's resource groups
moved {
  from = azurerm_role_assignment.rg_workload_owner
  to   = azurerm_role_assignment.lz_owner["default"]
}

moved {
  from = azurerm_role_assignment.rg_user_specified
  to   = azurerm_role_assignment.lz_owner
}

resource "azurerm_role_assignment" "lz_owner" {
  for_each             = merge({ default = azurerm_resource_group.workload }, azurerm_resource_group.user_specified)
  scope                = each.value.id
  principal_id         = module.user_assigned_identity.principal_id
  role_definition_name = "Owner"
  principal_type       = "ServicePrincipal"
}

moved {
  from = azurerm_role_assignment.user_input
  to   = azurerm_role_assignment.lz_identity
}

// Role Assignments for the Landing Zone identity (via var.identity.role_assignments)
resource "azurerm_role_assignment" "lz_identity" {
  for_each                               = local.role_assignments_merged_non_pim
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
  principal_type                         = "ServicePrincipal"
}

// PIM Eligible Role Assignments for the Landing Zone identity
resource "azurerm_pim_eligible_role_assignment" "lz_identity" {
  for_each           = local.role_assignments_merged_pim_eligible
  scope              = each.value.scope
  role_definition_id = each.value.role_definition_id != null ? each.value.role_definition_id : "/providers/Microsoft.Authorization/roleDefinitions/${data.azurerm_role_definition.pim_eligible[each.key].id}"
  principal_id       = module.user_assigned_identity.principal_id

  dynamic "schedule" {
    for_each = each.value.pim.start_date_time != null || each.value.pim.expiration != null ? [1] : []
    content {
      start_date_time = each.value.pim.start_date_time

      dynamic "expiration" {
        for_each = each.value.pim.expiration != null ? [each.value.pim.expiration] : []
        content {
          duration_days  = expiration.value.duration_days
          duration_hours = expiration.value.duration_hours
          end_date_time  = expiration.value.end_date_time
        }
      }
    }
  }

  justification = each.value.pim.justification

  dynamic "ticket" {
    for_each = each.value.pim.ticket_number != null && each.value.pim.ticket_system != null ? [1] : []
    content {
      number = each.value.pim.ticket_number
      system = each.value.pim.ticket_system
    }
  }
}

// PIM Active Role Assignments for the Landing Zone identity
resource "azurerm_pim_active_role_assignment" "lz_identity" {
  for_each           = local.role_assignments_merged_pim_active
  scope              = each.value.scope
  role_definition_id = each.value.role_definition_id != null ? each.value.role_definition_id : "/providers/Microsoft.Authorization/roleDefinitions/${data.azurerm_role_definition.pim_active[each.key].id}"
  principal_id       = module.user_assigned_identity.principal_id

  dynamic "schedule" {
    for_each = each.value.pim.start_date_time != null || each.value.pim.expiration != null ? [1] : []
    content {
      start_date_time = each.value.pim.start_date_time

      dynamic "expiration" {
        for_each = each.value.pim.expiration != null ? [each.value.pim.expiration] : []
        content {
          duration_days  = expiration.value.duration_days
          duration_hours = expiration.value.duration_hours
          end_date_time  = expiration.value.end_date_time
        }
      }
    }
  }

  justification = each.value.pim.justification

  dynamic "ticket" {
    for_each = each.value.pim.ticket_number != null && each.value.pim.ticket_system != null ? [1] : []
    content {
      number = each.value.pim.ticket_number
      system = each.value.pim.ticket_system
    }
  }
}

// Role Assignments for user specified principal IDs (not the Landing Zone identity (var.identity) OR the var.user_assigned_identities)
resource "azurerm_role_assignment" "others" {
  for_each                               = local.role_assignments_others_non_pim
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
  principal_type                         = "ServicePrincipal"
}

// PIM Eligible Role Assignments for user specified principals
resource "azurerm_pim_eligible_role_assignment" "others" {
  for_each           = local.role_assignments_others_pim_eligible
  scope              = each.value.scope
  role_definition_id = each.value.role_definition_id != null ? each.value.role_definition_id : "/providers/Microsoft.Authorization/roleDefinitions/${data.azurerm_role_definition.pim_others_eligible[each.key].id}"
  principal_id       = each.value.principal_id

  dynamic "schedule" {
    for_each = each.value.pim.start_date_time != null || each.value.pim.expiration != null ? [1] : []
    content {
      start_date_time = each.value.pim.start_date_time

      dynamic "expiration" {
        for_each = each.value.pim.expiration != null ? [each.value.pim.expiration] : []
        content {
          duration_days  = expiration.value.duration_days
          duration_hours = expiration.value.duration_hours
          end_date_time  = expiration.value.end_date_time
        }
      }
    }
  }

  justification = each.value.pim.justification

  dynamic "ticket" {
    for_each = each.value.pim.ticket_number != null && each.value.pim.ticket_system != null ? [1] : []
    content {
      number = each.value.pim.ticket_number
      system = each.value.pim.ticket_system
    }
  }
}

// PIM Active Role Assignments for user specified principals
resource "azurerm_pim_active_role_assignment" "others" {
  for_each           = local.role_assignments_others_pim_active
  scope              = each.value.scope
  role_definition_id = each.value.role_definition_id != null ? each.value.role_definition_id : "/providers/Microsoft.Authorization/roleDefinitions/${data.azurerm_role_definition.pim_others_active[each.key].id}"
  principal_id       = each.value.principal_id

  dynamic "schedule" {
    for_each = each.value.pim.start_date_time != null || each.value.pim.expiration != null ? [1] : []
    content {
      start_date_time = each.value.pim.start_date_time

      dynamic "expiration" {
        for_each = each.value.pim.expiration != null ? [each.value.pim.expiration] : []
        content {
          duration_days  = expiration.value.duration_days
          duration_hours = expiration.value.duration_hours
          end_date_time  = expiration.value.end_date_time
        }
      }
    }
  }

  justification = each.value.pim.justification

  dynamic "ticket" {
    for_each = each.value.pim.ticket_number != null && each.value.pim.ticket_system != null ? [1] : []
    content {
      number = each.value.pim.ticket_number
      system = each.value.pim.ticket_system
    }
  }
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

  // Separate PIM and non-PIM role assignments for Landing Zone identity
  role_assignments_merged_non_pim = {
    for k, v in local.role_assignments_merged : k => v
    if v.pim == null
  }

  role_assignments_merged_pim_eligible = {
    for k, v in local.role_assignments_merged : k => v
    if v.pim != null && lower(v.pim.member_type) == "eligible"
  }

  role_assignments_merged_pim_active = {
    for k, v in local.role_assignments_merged : k => v
    if v.pim != null && lower(v.pim.member_type) == "active"
  }

  // Separate PIM and non-PIM role assignments for user specified principals
  role_assignments_others_non_pim = {
    for k, v in var.role_assignments : k => v
    if v.pim == null
  }

  role_assignments_others_pim_eligible = {
    for k, v in var.role_assignments : k => v
    if v.pim != null && lower(v.pim.member_type) == "eligible"
  }

  role_assignments_others_pim_active = {
    for k, v in var.role_assignments : k => v
    if v.pim != null && lower(v.pim.member_type) == "active"
  }
}

// Data sources for role definitions when using role_definition_name with PIM
data "azurerm_role_definition" "pim_eligible" {
  for_each = {
    for k, v in local.role_assignments_merged_pim_eligible : k => v
    if v.role_definition_id == null && v.role_definition_name != null
  }
  name  = each.value.role_definition_name
  scope = each.value.scope
}

data "azurerm_role_definition" "pim_active" {
  for_each = {
    for k, v in local.role_assignments_merged_pim_active : k => v
    if v.role_definition_id == null && v.role_definition_name != null
  }
  name  = each.value.role_definition_name
  scope = each.value.scope
}

data "azurerm_role_definition" "pim_others_eligible" {
  for_each = {
    for k, v in local.role_assignments_others_pim_eligible : k => v
    if v.role_definition_id == null && v.role_definition_name != null
  }
  name  = each.value.role_definition_name
  scope = each.value.scope
}

data "azurerm_role_definition" "pim_others_active" {
  for_each = {
    for k, v in local.role_assignments_others_pim_active : k => v
    if v.role_definition_id == null && v.role_definition_name != null
  }
  name  = each.value.role_definition_name
  scope = each.value.scope
}

