locals {
  // https://developer.hashicorp.com/terraform/language/functions/flatten#flattening-nested-structures-for-for_each
  subnets_with_nsg_raw = flatten([
    for connKey, conn in var.connectivity : [
      for subnetKey, subnet in conn.subnets : merge(subnet, {
        "compositeKey" = format("%s_%s", connKey, subnetKey)
      }) if subnet.security_group_name != null
    ]
  ])

  subnets_with_nsg = tomap({
    for subnet in local.subnets_with_nsg_raw : subnet.compositeKey => subnet
  })
}

resource "azurerm_network_security_group" "this" {
  for_each            = local.subnets_with_nsg
  name                = each.value.security_group_name
  location            = azurerm_resource_group.workload.location
  resource_group_name = azurerm_resource_group.workload.name
  tags                = local.tags
}

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

  dynamic "subnet" {
    for_each = each.value.subnets

    content {
      name             = subnet.value.name
      address_prefixes = subnet.value.address_prefixes
      // Use value from `var.connectivity.subnets.this.security_group_id
      // fallback to resolved id of `var.connectivity.subnets.this.security_group_name`
      // fallback to null.
      // In essence 
      // security_group_id > security_group_name > null
      security_group = try(coalesce(
        subnet.value.security_group_id,
        azurerm_network_security_group.this["${each.key}_${subnet.key}"].id
      ), null)
      default_outbound_access_enabled = subnet.value.default_outbound_access_enabled

      dynamic "delegation" {
        for_each = subnet.value.delegation == null ? {} : subnet.value.delegation

        content {
          name = delegation.value.name

          dynamic "service_delegation" {
            for_each = delegation.value.service_delegation == null ? [] : [1]

            content {
              name    = delegation.value.service_delegation.name
              actions = delegation.value.service_delegation.actions
            }
          }
        }
      }
      private_endpoint_network_policies             = subnet.value.private_endpoint_network_policies
      private_link_service_network_policies_enabled = subnet.value.private_link_service_network_policies_enabled
      route_table_id                                = subnet.value.route_table_id
      service_endpoints                             = subnet.value.service_endpoints
      service_endpoint_policy_ids                   = subnet.value.service_endpoint_policy_ids
    }
  }
}

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
  for_each                               = local.peerings
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
        for_each = routing.value[0].propogated_route_table == null ? [] : [routing.value[0].propogated_route_table]

        content {
          labels          = propogated_route_table.value[0].labels
          route_table_ids = propogated_route_table.value[0].route_table_ids
        }
      }

      dynamic "static_vnet_route" {
        for_each = routing.value[0].static_vnet_route == null ? [] : [routing.value[0].static_vnet_route]
        content {
          name                = static_vnet.value[0].name
          address_prefixes    = static_vnet.value[0].address_prefixes
          next_hop_ip_address = static_vnet.value[0].next_hop_ip_address
        }
      }
    }
  }
}

