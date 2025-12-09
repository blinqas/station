// Standard role assignments (non-PIM)
resource "azurerm_role_assignment" "roles" {
  for_each                         = local.non_pim_role_assignments
  name                             = each.value.name
  scope                            = each.value.scope == null ? "/subscriptions/${var.subscription_id}" : each.value.scope
  role_definition_id               = each.value.role_definition_id
  role_definition_name             = each.value.role_definition_name
  principal_id                     = azuread_group.group.object_id
  condition                        = each.value.condition
  condition_version                = each.value.condition_version
  description                      = each.value.description
  skip_service_principal_aad_check = each.value.skip_service_principal_aad_check == null ? false : each.value.skip_service_principal_aad_check
}

// PIM Eligible role assignments
resource "azurerm_pim_eligible_role_assignment" "roles" {
  for_each           = local.pim_eligible_role_assignments
  scope              = each.value.scope == null ? "/subscriptions/${var.subscription_id}" : each.value.scope
  role_definition_id = each.value.role_definition_id != null ? each.value.role_definition_id : data.azurerm_role_definition.pim_eligible[each.key].id
  principal_id       = azuread_group.group.object_id

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

// PIM Active role assignments
resource "azurerm_pim_active_role_assignment" "roles" {
  for_each           = local.pim_active_role_assignments
  scope              = each.value.scope == null ? "/subscriptions/${var.subscription_id}" : each.value.scope
  role_definition_id = each.value.role_definition_id != null ? each.value.role_definition_id : data.azurerm_role_definition.pim_active[each.key].id
  principal_id       = azuread_group.group.object_id

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
  role_assignments = var.role_assignments == null ? {} : var.role_assignments

  non_pim_role_assignments = {
    for k, v in local.role_assignments : k => v
    if v.pim == null
  }

  pim_eligible_role_assignments = {
    for k, v in local.role_assignments : k => v
    if v.pim != null && lower(v.pim.member_type) == "eligible"
  }

  pim_active_role_assignments = {
    for k, v in local.role_assignments : k => v
    if v.pim != null && lower(v.pim.member_type) == "active"
  }
}

// Data sources for role definitions when using role_definition_name with PIM
data "azurerm_role_definition" "pim_eligible" {
  for_each = {
    for k, v in local.pim_eligible_role_assignments : k => v
    if v.role_definition_id == null && v.role_definition_name != null
  }
  name  = each.value.role_definition_name
  scope = each.value.scope == null ? "/subscriptions/${var.subscription_id}" : each.value.scope
}

data "azurerm_role_definition" "pim_active" {
  for_each = {
    for k, v in local.pim_active_role_assignments : k => v
    if v.role_definition_id == null && v.role_definition_name != null
  }
  name  = each.value.role_definition_name
  scope = each.value.scope == null ? "/subscriptions/${var.subscription_id}" : each.value.scope
}