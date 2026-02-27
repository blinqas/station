moved {
  from = azurerm_role_assignment.roles
  to   = azurerm_role_assignment.this
}

resource "azurerm_role_assignment" "this" {
  for_each                               = local.role_assignments_standard
  name                                   = each.value.name
  scope                                  = each.value.scope
  role_definition_id                     = each.value.role_definition_id
  role_definition_name                   = each.value.role_definition_name
  principal_id                           = azurerm_user_assigned_identity.identity.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  description                            = each.value.description
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check == null ? false : each.value.skip_service_principal_aad_check
  principal_type                         = "ServicePrincipal"
}

# Resolves Azure role definitions by name for PIM assignments that do not already provide a role_definition_id.
# This data source iterates over a merged map of:
# - eligible PIM role assignments, and
# - active PIM role assignments
# filtering to entries where role_definition_id is null and role_definition_name is set.
# Each matching assignment is looked up by role name at its specified scope so downstream resources
# can reference the resolved role definition metadata/ID consistently.
data "azurerm_role_definition" "pim_by_name" {
  for_each = merge(
    { for k, v in local.role_assignments_pim_eligible : k => v if v.role_definition_id == null && v.role_definition_name != null },
    { for k, v in local.role_assignments_pim_active : k => v if v.role_definition_id == null && v.role_definition_name != null }
  )
  name  = each.value.role_definition_name
  scope = each.value.scope
}

resource "azurerm_pim_eligible_role_assignment" "this" {
  for_each = local.role_assignments_pim_eligible

  scope              = each.value.scope
  role_definition_id = coalesce(each.value.role_definition_id, try(data.azurerm_role_definition.pim_by_name[each.key].id, null))
  principal_id       = azurerm_user_assigned_identity.identity.principal_id
  justification      = try(each.value.pim.justification, null)
  condition          = each.value.condition
  condition_version  = each.value.condition_version

  dynamic "ticket" {
    for_each = try(each.value.pim.ticket, null) == null ? [] : [each.value.pim.ticket]
    content {
      number = try(ticket.value.number, null)
      system = try(ticket.value.system, null)
    }
  }

  dynamic "schedule" {
    for_each = try(each.value.pim.schedule, null) == null ? [] : [each.value.pim.schedule]
    content {
      start_date_time = try(schedule.value.start_date_time, null)

      dynamic "expiration" {
        for_each = try(schedule.value.expiration, null) == null ? [] : [schedule.value.expiration]
        content {
          duration_days  = try(expiration.value.duration_days, null)
          duration_hours = try(expiration.value.duration_hours, null)
          end_date_time  = try(expiration.value.end_date_time, null)
        }
      }
    }
  }
}

resource "azurerm_pim_active_role_assignment" "this" {
  for_each = local.role_assignments_pim_active

  scope              = each.value.scope
  role_definition_id = coalesce(each.value.role_definition_id, try(data.azurerm_role_definition.pim_by_name[each.key].id, null))
  principal_id       = azurerm_user_assigned_identity.identity.principal_id
  justification      = try(each.value.pim.justification, null)

  dynamic "ticket" {
    for_each = try(each.value.pim.ticket, null) == null ? [] : [each.value.pim.ticket]
    content {
      number = try(ticket.value.number, null)
      system = try(ticket.value.system, null)
    }
  }

  dynamic "schedule" {
    for_each = try(each.value.pim.schedule, null) == null ? [] : [each.value.pim.schedule]
    content {
      start_date_time = try(schedule.value.start_date_time, null)

      dynamic "expiration" {
        for_each = try(schedule.value.expiration, null) == null ? [] : [schedule.value.expiration]
        content {
          duration_days  = try(expiration.value.duration_days, null)
          duration_hours = try(expiration.value.duration_hours, null)
          end_date_time  = try(expiration.value.end_date_time, null)
        }
      }
    }
  }
}

locals {
  role_assignments_standard = {
    for k, v in var.role_assignments : k => v if try(v.pim, null) == null
  }

  role_assignments_pim_eligible = {
    for k, v in var.role_assignments : k => v if try(v.pim, null) != null && try(v.pim.member_type, "Eligible") == "Eligible"
  }

  role_assignments_pim_active = {
    for k, v in var.role_assignments : k => v if try(v.pim, null) != null && try(v.pim.member_type, "Eligible") == "Active"
  }
}

