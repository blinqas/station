variable "connectivity" {
  description = <<-EOT
    Configuration for connectivity resources (virtual networks, subnets, peerings, etc.).

    - `virtual_networks` - (Optional) A map of virtual networks to create. For additional information on `virtual_networks`, see [virtual_networks block](#virtual_networks-block).
    - `subnets` - (Optional) A map of subnets to create. For additional information on `subnets`, see [subnets block](#subnets-block).
    - `peerings` - (Optional) A map of virtual network peerings to create. For additional information on `peerings`, see [peerings block](#peerings-block).
    - `virtual_hub_connection` - (Optional) Configuration for connecting to a virtual hub. For additional information on `virtual_hub_connection`, see [virtual_hub_connection block](#virtual_hub_connection-block).
  EOT
  type = object({
    virtual_networks = optional(map(object({
      name                = string
      location            = optional(string)
      resource_group_name = optional(string)
      address_space       = list(string)
      dns_servers         = optional(list(string))
      tags                = optional(map(string))
    })), {})
    subnets = optional(map(object({
      name                = string
      virtual_network_key = string
      address_prefixes    = list(string)
      service_endpoints   = optional(list(string))
      delegation = optional(object({
        name = string
        service_delegation = object({
          name    = string
          actions = optional(list(string))
        })
      }))
    })), {})
    peerings = optional(map(object({
      name                         = string
      virtual_network_key          = string
      remote_virtual_network_id    = string
      allow_virtual_network_access = optional(bool, true)
      allow_forwarded_traffic      = optional(bool, false)
      allow_gateway_transit        = optional(bool, false)
      use_remote_gateways          = optional(bool, false)
    })), {})
    virtual_hub_connection = optional(object({
      virtual_hub_id            = string
      internet_security_enabled = optional(bool)
      routing = optional(object({
        associated_route_table_id = optional(string)
        propagated_route_table = optional(object({
          labels          = optional(list(string))
          route_table_ids = optional(list(string))
        }))
      }))
    }))
  })
  default = null

  validation {
    condition = var.connectivity == null ? true : alltrue([
      for peering_key, peering in var.connectivity.peerings : length([
        for other_key, other_peering in var.connectivity.peerings :
        other_key if peering_key != other_key &&
        peering.virtual_network_key == other_peering.virtual_network_key &&
        peering.remote_virtual_network_id == other_peering.remote_virtual_network_id
      ]) == 0
    ])
    error_message = "Each combination of 'virtual_network_key' and 'remote_virtual_network_id' must be unique across all peerings."
  }
}
