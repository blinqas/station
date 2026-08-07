output "client_id" {
  value = module.user_assigned_identity.client_id
}

output "workload_service_principal_object_id" {
  value = module.user_assigned_identity.principal_id
}

output "tenant_id" {
  value = var.tenant_id
}

output "subscription_id" {
  value = var.subscription_id
}

output "workload_resource_group_name" {
  value = azurerm_resource_group.workload.name
}

output "resource_group" {
  value = azurerm_resource_group.workload
}

output "resource_groups_user_specified" {
  value = azurerm_resource_group.user_specified
}

output "policy_exemptions" {
  value = azurerm_resource_group_policy_exemption.this
}

output "applications" {
  value = module.applications
}

output "groups" {
  value = module.ad_groups
}

output "landing_zone_identity" {
  value = module.user_assigned_identity
}

output "user_assigned_identities" {
  value = module.user_assigned_identities
}

output "tfe" {
  value = module.station-tfe
}

output "virtual_networks" {
  value = azurerm_virtual_network.this
}

output "subnets" {
  value = local.subnets_output
}

output "network_security_groups" {
  value = azurerm_network_security_group.this
}

output "peerings" {
  value = {
    to   = azurerm_virtual_network_peering.to
    from = azurerm_virtual_network_peering.from
  }
}

output "role_assignments" {
  value = {
    lz_owner    = azurerm_role_assignment.lz_owner
    lz_identity = azurerm_role_assignment.lz_identity
    others      = azurerm_role_assignment.others
  }

  description = <<EOT
    Map of role assignments.

    - lz_owner: Owner role assignment on the default landing zone resource group
    - lz_identity: Role assignments created through `var.identity.role_assignment`
    - others: Role assignments created through `var.role_assignments`
  EOT
}
