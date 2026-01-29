resource "azurerm_virtual_network" "this" {
  for_each                       = var.connectivity
  name                           = each.value.virtual_network_name
  address_space                  = each.value.address_space
  location                       = each.value.location == null ? var.default_location : each.value.location
  resource_group_name            = each.value.resource_group_name == null ? azurerm_resource_group.workload.name : each.value.resource_group_name
  bgp_community                  = each.value.bgp_community
  dns_servers                    = each.value.dns_servers
  edge_zone                      = each.value.edge_zone
  flow_timeout_in_minutes        = each.value.flow_timeout_in_minutes
  private_endpoint_vnet_policies = each.value.private_endpoint_vnet_policies
  tags                           = merge(local.tags, each.value.tags)

  dynamic "encryption" {
    for_each = each.value.encryption == null ? [] : [each.value.encryption]

    content {
      enforcement = encryption.value[0].enforcement
    }
  }
}

# Network Security Group(s)
// Create NSG only if var.connectivity[subnet].security_group_name is supplied.
resource "azurerm_network_security_group" "this" {
  for_each            = { for k, v in var.connectivity : k => v if v.security_group_name != null }
  name                = each.value.security_group_name
  resource_group_name = azurerm_resource_group.workload.name
  location            = azurerm_resource_group.workload.location
  tags                = local.tags
}

// Associate NSG with Subnets only if var.connectivity[subnet].security_group_name is supplied.
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = { for k, v in local.subnets : k => v if var.connectivity[v.network_key].security_group_name != null }
  network_security_group_id = azurerm_network_security_group.this[each.value.network_key].id
  subnet_id                 = azurerm_subnet.this[each.key].id
}

# Subnet(s)
locals {
  subnets_flatten = flatten([
    for network_key, network in var.connectivity : [
      for subnet_key, subnet in network.subnets : merge(subnet, {
        network_key = network_key
        network_id  = azurerm_virtual_network.this[network_key].id
        subnet_key  = subnet_key
      })
    ]
  ])
  subnets = tomap({
    for subnet in local.subnets_flatten : "${subnet.network_key}.${subnet.subnet_key}" => subnet
  })
}

resource "azurerm_subnet" "this" {
  for_each                                      = local.subnets
  name                                          = each.value.name
  resource_group_name                           = azurerm_virtual_network.this[each.value.network_key].resource_group_name
  virtual_network_name                          = azurerm_virtual_network.this[each.value.network_key].name
  address_prefixes                              = each.value.address_prefixes
  default_outbound_access_enabled               = each.value.default_outbound_access_enabled
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  service_endpoints                             = each.value.service_endpoints
  service_endpoint_policy_ids                   = each.value.service_endpoint_policy_ids

  dynamic "delegation" {
    for_each = each.value.delegation == null ? {} : each.value.delegation
    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

// Virtual Network Peering(s)
locals {
  // Collect all peerings objects from all var.connectivity entries into one map
  // See https://developer.hashicorp.com/terraform/language/functions/flatten#flattening-nested-structures-for-for_each
  peerings_collected = flatten([
    for connKey, conn in var.connectivity : [
      for peeringKey, peering in conn.peerings : merge(peering, {
        connKey       = connKey
        composite_key = peeringKey
      })
    ]
  ])
  peerings = tomap({
    for peering in local.peerings_collected : peering.composite_key => peering
  })
}

resource "azurerm_virtual_network_peering" "to" {
  for_each                               = local.peerings
  name                                   = each.value.name
  resource_group_name                    = azurerm_virtual_network.this[each.value.connKey].resource_group_name
  allow_forwarded_traffic                = each.value.allow_forwarded_traffic
  allow_gateway_transit                  = each.value.allow_gateway_transit
  allow_virtual_network_access           = each.value.allow_virtual_network_access
  local_subnet_names                     = each.value.local_subnet_names
  only_ipv6_peering_enabled              = each.value.only_ipv6_peering_enabled
  peer_complete_virtual_networks_enabled = each.value.peer_complete_virtual_networks_enabled
  remote_subnet_names                    = each.value.remote_subnet_names
  remote_virtual_network_id              = each.value.remote_virtual_network_id
  triggers                               = each.value.triggers
  use_remote_gateways                    = each.value.use_remote_gateways
  virtual_network_name                   = azurerm_virtual_network.this[each.value.connKey].name
}

resource "azurerm_virtual_network_peering" "from" {
  for_each                               = { for k, v in local.peerings : k => v if !v.use_connectivity_subscription }
  name                                   = each.value.name
  resource_group_name                    = regex("resourceGroups/(.*?)/", each.value.remote_virtual_network_id)[0] // Extract Resource Group name from Resource ID
  allow_forwarded_traffic                = each.value.allow_forwarded_traffic
  allow_gateway_transit                  = each.value.allow_gateway_transit
  allow_virtual_network_access           = each.value.allow_virtual_network_access
  local_subnet_names                     = each.value.remote_subnet_names
  only_ipv6_peering_enabled              = each.value.only_ipv6_peering_enabled
  peer_complete_virtual_networks_enabled = each.value.peer_complete_virtual_networks_enabled
  remote_subnet_names                    = each.value.local_subnet_names
  remote_virtual_network_id              = azurerm_virtual_network.this[each.value.connKey].id
  triggers                               = each.value.triggers
  use_remote_gateways                    = each.value.use_remote_gateways
  virtual_network_name                   = regex("([^//]+)$", each.value.remote_virtual_network_id)[0] // Extract Virtual Network name from Resource ID
}

resource "azurerm_virtual_network_peering" "from.connectivity" {
  provider                               = azurerm.connectivity
  for_each                               = { for k, v in local.peerings : k => v if v.use_connectivity_subscription }
  name                                   = each.value.name
  resource_group_name                    = regex("resourceGroups/(.*?)/", each.value.remote_virtual_network_id)[0] // Extract Resource Group name from Resource ID
  allow_forwarded_traffic                = each.value.allow_forwarded_traffic
  allow_gateway_transit                  = each.value.allow_gateway_transit
  allow_virtual_network_access           = each.value.allow_virtual_network_access
  local_subnet_names                     = each.value.remote_subnet_names
  only_ipv6_peering_enabled              = each.value.only_ipv6_peering_enabled
  peer_complete_virtual_networks_enabled = each.value.peer_complete_virtual_networks_enabled
  remote_subnet_names                    = each.value.local_subnet_names
  remote_virtual_network_id              = azurerm_virtual_network.this[each.value.connKey].id
  triggers                               = each.value.triggers
  use_remote_gateways                    = each.value.use_remote_gateways
  virtual_network_name                   = regex("([^//]+)$", each.value.remote_virtual_network_id)[0] // Extract Virtual Network name from Resource ID
}


locals {
  # Generates a map of VWAN Hub Connections from `var.connectivity` where a Hub Connection is
  # configured. This is required as virtual_hub_connections is an optional object in `var.connectivity`.
  virtual_hub_connections = { for k, v in var.connectivity : k => merge(v.virtual_hub_connection, {
    remote_virtual_network_id = azurerm_virtual_network.this[k].id
  }) if !(v.virtual_hub_connection == null) }
}

resource "azurerm_virtual_hub_connection" "this" {
  provider                  = azurerm.connectivity
  for_each                  = local.virtual_hub_connections
  name                      = each.value.name
  virtual_hub_id            = each.value.id
  remote_virtual_network_id = each.value.remote_virtual_network_id
  internet_security_enabled = each.value.internet_security_enabled

  dynamic "routing" {
    for_each = each.value.routing == null ? [] : [each.value.routing]

    content {
      associated_route_table_id                   = routing.value[0].associated_route_table_id
      inbound_route_map_id                        = routing.value[0].inbound_route_map_id
      outbound_route_map_id                       = routing.value[0].outbound_route_map_id
      static_vnet_local_route_override_criteria   = routing.value[0].static_vnet_local_route_override_criteria
      static_vnet_propagate_static_routes_enabled = routing.value[0].static_vnet_propagate_static_routes_enabled

      dynamic "propagated_route_table" {
        for_each = routing.value[0].propagated_route_table == null ? [] : [routing.value[0].propagated_route_table]

        content {
          labels          = propagated_route_table.value[0].labels
          route_table_ids = propagated_route_table.value[0].route_table_ids
        }
      }

      dynamic "static_vnet_route" {
        for_each = routing.value[0].static_vnet_route == null ? [] : [routing.value[0].static_vnet_route]
        content {
          name                = static_vnet_route.value[0].name
          address_prefixes    = static_vnet_route.value[0].address_prefixes
          next_hop_ip_address = static_vnet_route.value[0].next_hop_ip_address
        }
      }
    }
  }
}

