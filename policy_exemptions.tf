locals {
  # For policy exemptions without a specified resource_group_name, use the default workload resource group
  policy_exemptions_default_rg = {
    for k, v in var.policy_exemptions : k => merge(v, {
      resource_group_id = azurerm_resource_group.workload.id
    }) if v.resource_group_name == null
  }

  # For policy exemptions with a specified resource_group_name, use the specified resource group
  policy_exemptions_specified_rg = {
    for k, v in var.policy_exemptions : k => merge(v, {
      resource_group_id = azurerm_resource_group.user_specified[v.resource_group_name].id
    }) if v.resource_group_name != null
  }

  # Merge all policy exemptions
  policy_exemptions_merged = merge(
    local.policy_exemptions_default_rg,
    local.policy_exemptions_specified_rg
  )
}

resource "azurerm_resource_group_policy_exemption" "this" {
  for_each                        = local.policy_exemptions_merged
  name                            = each.value.name
  resource_group_id               = each.value.resource_group_id
  policy_assignment_id            = each.value.policy_assignment_id
  exemption_category              = each.value.exemption_category
  display_name                    = each.value.display_name
  description                     = each.value.description
  expires_on                      = each.value.expires_on
  policy_definition_reference_ids = each.value.policy_definition_reference_ids
  metadata                        = each.value.metadata
}
