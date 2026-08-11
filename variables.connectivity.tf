variable "connectivity" {
  description = <<EOF
    Use this block to configure connectivity of this Landing Zone. Connectivity can be virtual networks, subnets, peerings to other virtual networks and VWAN hub connections.

    Limitations:
    - Connecting Virtual Networks in different resource groups managed by this landing zone is currently unavailable. Configure this manually in the landing zone configuration.
    - The key used for a peering object must be unique across all connectivity objects.
    - The VWAN Virtual Hub peering option can only peer to VWAN Hubs that are in the configured `azurerm.connectivity` subscription.
  EOF
  default     = {}
  type = map(object({
    virtual_network_name = string
    tags                 = optional(map(string), {})
    address_space        = set(string)
    resource_group_name  = optional(string)
    location             = optional(string)
    bgp_community        = optional(string)
    security_group_name  = optional(string)
    ddos_protection_plan = optional(object({
      id     = string
      enable = string
    }))
    encryption = optional(object({
      enforcement = string
    }))
    dns_servers                    = optional(set(string))
    edge_zone                      = optional(string)
    flow_timeout_in_minutes        = optional(string)
    private_endpoint_vnet_policies = optional(string, "Disabled")
    subnets = map(object({
      name             = string
      address_prefixes = list(string)
      delegation = optional(map(object({
        name = string
        service_delegation = object({
          name    = string
          actions = optional(set(string))
        })
      })))
      default_outbound_access_enabled               = optional(bool, true)
      private_endpoint_network_policies             = optional(string, "Disabled")
      private_link_service_network_policies_enabled = optional(bool, true)
      service_endpoint = optional(list(object({
        service            = string
        network_identifier = optional(string)
      })), [])
      service_endpoint_policy_ids = optional(set(string))
      route_table_id              = optional(string)
    }))
    peerings = optional(map(object({
      name                                   = string
      remote_virtual_network_id              = string
      use_connectivity_subscription          = optional(bool, true)
      allow_virtual_network_access           = optional(bool, true)
      allow_forwarded_traffic                = optional(bool, false)
      allow_gateway_transit                  = optional(bool, false)
      local_subnet_names                     = optional(list(string), [])
      only_ipv6_peering_enabled              = optional(bool)
      peer_complete_virtual_networks_enabled = optional(bool, true)
      remote_subnet_names                    = optional(list(string), [])
      use_remote_gateways                    = optional(bool, false)
      triggers = optional(object({
        remote_address_space = string
      }))
    })), {})
    virtual_hub_connection = optional(object({
      name                      = string
      id                        = string
      internet_security_enabled = optional(bool, false)
      routing = optional(object({
        associated_route_table_id = optional(string)
        inbound_route_map_id      = optional(string)
        outbound_route_map_id     = optional(string)
        propagated_route_table = optional(object({
          labels          = optional(list(string))
          route_table_ids = optional(list(string))
        }))
        static_vnet_local_route_override_criteria   = optional(string, "Contains")
        static_vnet_propagate_static_routes_enabled = optional(bool, true)
        static_vnet_route = optional(object({
          name                = optional(string)
          address_prefixes    = optional(list(string))
          next_hop_ip_address = optional(string)
        }))
      }))
    }))
    })
  )

  validation {
    condition = length(
      distinct(
        flatten([
          for vnet_key, vnet in var.connectivity : [
            for peering_key, peering in lookup(vnet, "peerings", {}) :
            "${vnet_key}:${peering_key}"
          ]
        ])
      )
      ) == length(
      flatten([
        for vnet_key, vnet in var.connectivity : [
          for peering_key, peering in lookup(vnet, "peerings", {}) :
          "${vnet_key}:${peering_key}"
        ]
      ])
    )
    error_message = "The key used for a peering object must be unique across all connectivity objects."
  }
}
