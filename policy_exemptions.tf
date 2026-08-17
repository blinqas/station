locals {
  policy_exemptions = {
    for key, value in var.policy_exemptions : key => merge(value, {
      resource_group_id = value.resource_group_key == null ? azurerm_resource_group.workload.id : azurerm_resource_group.user_specified[value.resource_group_key].id
    })
  }
}

resource "azurerm_resource_group_policy_exemption" "this" {
  for_each = local.policy_exemptions

  name                            = each.value.name
  resource_group_id               = each.value.resource_group_id
  policy_assignment_id            = each.value.policy_assignment_id
  exemption_category              = each.value.exemption_category
  description                     = each.value.description
  display_name                    = each.value.display_name
  expires_on                      = each.value.expires_on
  policy_definition_reference_ids = each.value.policy_definition_reference_ids
}
