provider "tfe" {}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias = "connectivity"
  features {}
}

provider "azuread" {}

test {
  parallel = true
}

run "setup_create_hub_vnet" {
  variables {
    remote_vnet_name          = "remote_hub_network" # Update the remote_virtual_network_id if this is changed
    remote_vnet_address_space = "10.0.58.0/23"
    resource_group_name       = "rg-stationtest-peering-hub" # Update the remote_virtual_network_id if this is changed
  }

  module {
    source = "./tests/setup-peering-networks"
  }
}

run "setup_create_tfc_test_project" {
  variables {
    tfc_project_name = "tests_connectivity"
  }
  module {
    source = "./tests/setup-tfe-project"
  }
}


variables {
  tfe = {
    project = {
      id   = "# Overridden"
      name = "test_peering"
    }
    organization_name     = "blinq-west-lab"
    workspace_name        = "connectivity-test"
    workspace_description = "Workspace description"
    workspace_settings = {
      execution_mode = "remote"
    }
  }

  resource_group_name = "stationtest-peering-01"

  connectivity = {
    min = {
      virtual_network_name = "vnet-my-lz-min"
      address_space        = ["10.0.54.0/23"]
      subnets = {
        main = {
          name             = "snet-main-min"
          address_prefixes = ["10.0.54.0/24"]
        }
      }

      peerings = {
        min_hub = {
          name                      = "peer-lz-min"
          remote_virtual_network_id = "This has to be overrided by the output from the setup_create_hub_vnet module"
        }
      }
    }

    max = {
      virtual_network_name = "vnet-my-lz2-max"
      resource_group_name  = "rg-stationtest-peering-hub"
      address_space        = ["10.0.56.0/23"]
      security_group_name  = "nsg-max-test"
      subnets = {
        main = {
          name             = "snet-app"
          address_prefixes = ["10.0.56.0/24"]
        }
        other = {
          name             = "snet-app2"
          address_prefixes = ["10.0.57.0/25"]
        }
        service_delegation_subnet = {
          name             = "snet-delegated"
          address_prefixes = ["10.0.57.128/25"]
          delegation = {
            service_delegation_1 = {
              name = "myservicedelegation"
              service_delegation = {
                name = "Microsoft.Databricks/workspaces"
                actions = [
                  "Microsoft.Network/virtualNetworks/subnets/join/action",
                  "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
                  "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
                ]
              }
            }
          }
        }
      }
      peerings = {
        max_hub = {
          name                         = "peer-lz-max"
          resource_group_name          = "rg-stationtest-peering-hub"
          remote_virtual_network_id    = "This has to be overrided by the output from the setup_create_hub_vnet module"
          allow_forwarded_traffic      = true
          allow_virtual_network_access = true
          allow_gateway_transit        = true
        }
      }
    }
  }

}

run "station-connectivity" {
  variables {
    // Overide the min network to use the outputed vnet ID from the setup_create_hub_vnet module
    connectivity = merge(var.connectivity, {
      min = merge(var.connectivity.min, {
        peerings = merge(var.connectivity.min.peerings, {
          min_hub = merge(var.connectivity.min.peerings.min_hub, {
            remote_virtual_network_id = run.setup_create_hub_vnet.virtual_network_id
          })
        })
      }),
      // Overide the max network to use the outputed vnet ID from the setup_create_hub_vnet module
      max = merge(var.connectivity.max, {
        peerings = merge(var.connectivity.max.peerings, {
          max_hub = merge(var.connectivity.max.peerings.max_hub, {
            remote_virtual_network_id = run.setup_create_hub_vnet.virtual_network_id
          })
        })
      })
    })
    // Override project ID from `setup_create_tfc_test_project`
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.setup_create_tfc_test_project.id
      })
    })
  }


  module {
    source = "./"
  }

  # Verify that VNets have the correct names
  assert {
    condition = alltrue([
      for key, vnet in azurerm_virtual_network.this :
      vnet.name == var.connectivity[key].virtual_network_name
    ])
    error_message = join("\n", [
      "Virtual network name mismatch. Details:",
      jsonencode({
        for key, vnet in azurerm_virtual_network.this : key => {
          actual_name   = vnet.name,
          expected_name = var.connectivity[key].virtual_network_name,
          matches       = vnet.name == var.connectivity[key].virtual_network_name
        }
      })
    ])
  }

  # Verify that VNets are in the correct resource groups
  assert {
    condition = alltrue([
      azurerm_virtual_network.this["min"].resource_group_name == "rg-${var.resource_group_name}",
      azurerm_virtual_network.this["max"].resource_group_name == var.connectivity["max"].resource_group_name
    ])
    error_message = join("\n", [
      "Resource group mismatch. Details:",
      jsonencode({
        min = {
          actual_rg   = azurerm_virtual_network.this["min"].resource_group_name,
          expected_rg = "rg-${var.resource_group_name}",
          matches     = azurerm_virtual_network.this["min"].resource_group_name == "rg-${var.resource_group_name}"
        },
        max = {
          actual_rg   = azurerm_virtual_network.this["max"].resource_group_name,
          expected_rg = var.connectivity["max"].resource_group_name,
          matches     = azurerm_virtual_network.this["max"].resource_group_name == var.connectivity["max"].resource_group_name
        }
      })
    ])
  }

  # Validate Address Prefixes for VNets
  assert {
    condition = alltrue([
      for key, vnet in azurerm_virtual_network.this :
      vnet.address_space == var.connectivity[key].address_space
    ])
    error_message = join("\n", [
      "Address space mismatch. Details:",
      jsonencode({
        for key, vnet in azurerm_virtual_network.this : key => {
          actual_address_space   = vnet.address_space,
          expected_address_space = var.connectivity[key].address_space,
          matches                = vnet.address_space == var.connectivity[key].address_space
        }
      })
    ])
  }

  # Validate Peering Configurations
  assert {
    condition = alltrue([
      // Validate allow_forwarded_traffic
      azurerm_virtual_network_peering.to["min_hub"].allow_forwarded_traffic == var.connectivity["min"].peerings["min_hub"].allow_forwarded_traffic,
      azurerm_virtual_network_peering.to["max_hub"].allow_forwarded_traffic == var.connectivity["max"].peerings["max_hub"].allow_forwarded_traffic,

      // Validate allow_virtual_network_access
      azurerm_virtual_network_peering.to["min_hub"].allow_virtual_network_access == try(var.connectivity["min"].peerings["min_hub"].allow_virtual_network_access, true),
      azurerm_virtual_network_peering.to["max_hub"].allow_virtual_network_access == var.connectivity["max"].peerings["max_hub"].allow_virtual_network_access,

      // Validate allow_gateway_transit
      azurerm_virtual_network_peering.to["min_hub"].allow_gateway_transit == try(var.connectivity["min"].peerings["min_hub"].allow_gateway_transit, false),
      azurerm_virtual_network_peering.to["max_hub"].allow_gateway_transit == var.connectivity["max"].peerings["max_hub"].allow_gateway_transit,
    ])
    error_message = join("\n", [
      "Peering configuration mismatch. Details:",
      jsonencode({
        min_hub = {
          forwarded_traffic = {
            actual   = azurerm_virtual_network_peering.to["min_hub"].allow_forwarded_traffic,
            expected = var.connectivity["min"].peerings["min_hub"].allow_forwarded_traffic,
            matches  = azurerm_virtual_network_peering.to["min_hub"].allow_forwarded_traffic == var.connectivity["min"].peerings["min_hub"].allow_forwarded_traffic
          },
          virtual_network_access = {
            actual   = azurerm_virtual_network_peering.to["min_hub"].allow_virtual_network_access,
            expected = try(var.connectivity["min"].peerings["min_hub"].allow_virtual_network_access, true),
            matches  = azurerm_virtual_network_peering.to["min_hub"].allow_virtual_network_access == try(var.connectivity["min"].peerings["min_hub"].allow_virtual_network_access, true)
          },
          gateway_transit = {
            actual   = azurerm_virtual_network_peering.to["min_hub"].allow_gateway_transit,
            expected = try(var.connectivity["min"].peerings["min_hub"].allow_gateway_transit, false),
            matches  = azurerm_virtual_network_peering.to["min_hub"].allow_gateway_transit == try(var.connectivity["min"].peerings["min_hub"].allow_gateway_transit, false)
          }
        },
        max_hub = {
          forwarded_traffic = {
            actual   = azurerm_virtual_network_peering.to["max_hub"].allow_forwarded_traffic,
            expected = var.connectivity["max"].peerings["max_hub"].allow_forwarded_traffic,
            matches  = azurerm_virtual_network_peering.to["max_hub"].allow_forwarded_traffic == var.connectivity["max"].peerings["max_hub"].allow_forwarded_traffic
          },
          virtual_network_access = {
            actual   = azurerm_virtual_network_peering.to["max_hub"].allow_virtual_network_access,
            expected = var.connectivity["max"].peerings["max_hub"].allow_virtual_network_access,
            matches  = azurerm_virtual_network_peering.to["max_hub"].allow_virtual_network_access == var.connectivity["max"].peerings["max_hub"].allow_virtual_network_access
          },
          gateway_transit = {
            actual   = azurerm_virtual_network_peering.to["max_hub"].allow_gateway_transit,
            expected = var.connectivity["max"].peerings["max_hub"].allow_gateway_transit,
            matches  = azurerm_virtual_network_peering.to["max_hub"].allow_gateway_transit == var.connectivity["max"].peerings["max_hub"].allow_gateway_transit
          }
        }
      })
    ])
  }

  # Validate Subnet Names and Address Prefixes
  assert {
    condition = alltrue([
      for subnet_key, subnet in local.subnets :
      azurerm_subnet.this[subnet_key].name == subnet.name && azurerm_subnet.this[subnet_key].address_prefixes == subnet.address_prefixes
    ])
    error_message = join("\n", [
      "Subnet configuration mismatch. Details:",
      jsonencode({
        for subnet_key, subnet in local.subnets : subnet_key => {
          name = {
            actual   = azurerm_subnet.this[subnet_key].name,
            expected = subnet.name,
            matches  = azurerm_subnet.this[subnet_key].name == subnet.name
          },
          address_prefixes = {
            actual   = azurerm_subnet.this[subnet_key].address_prefixes,
            expected = subnet.address_prefixes,
            matches  = azurerm_subnet.this[subnet_key].address_prefixes == subnet.address_prefixes
          }
        }
      })
    ])
  }

  # Ensure the correct number of VNets was created
  assert {
    condition = length(azurerm_virtual_network.this) == length(var.connectivity)
    error_message = join("\n", [
      "Virtual network count mismatch. Details:",
      jsonencode({
        actual_count   = length(azurerm_virtual_network.this),
        expected_count = length(var.connectivity),
        actual_vnets   = keys(azurerm_virtual_network.this),
        expected_vnets = keys(var.connectivity)
      })
    ])
  }

  # Ensure the correct number of subnets per VNet
  assert {
    condition = alltrue([
      for key, vnet in azurerm_virtual_network.this :
      length([for subnet_key, _ in azurerm_subnet.this : subnet_key if startswith(subnet_key, "${key}.")]) == length(var.connectivity[key].subnets)
    ])
    error_message = join("\n", [
      "VNet subnet count mismatch. Details:",
      jsonencode({
        for key, vnet in azurerm_virtual_network.this : key => {
          vnet_name        = vnet.name,
          found_subnets    = [for subnet_key, _ in azurerm_subnet.this : subnet_key if startswith(subnet_key, "${key}.")],
          expected_subnets = keys(var.connectivity[key].subnets)
        }
      })
    ])
  }

  # Check if all expected subnet delegations exist
  assert {
    condition = alltrue([
      for subnet_key, subnet in local.subnets :
      subnet.delegation == null || (
        length(azurerm_subnet.this[subnet_key].delegation) > 0 &&
        azurerm_subnet.this[subnet_key].delegation[0].name == values(subnet.delegation)[0].name &&
        azurerm_subnet.this[subnet_key].delegation[0].service_delegation[0].name == values(subnet.delegation)[0].service_delegation.name &&
        azurerm_subnet.this[subnet_key].delegation[0].service_delegation[0].actions == values(subnet.delegation)[0].service_delegation.actions
      )
    ])
    error_message = join("\n", [
      "Subnet delegation mismatch. Details:",
      jsonencode({
        for subnet_key, subnet in local.subnets : subnet_key => {
          actual = subnet.delegation == null ? null : {
            name = azurerm_subnet.this[subnet_key].delegation[0].name,
            service_delegation = {
              name    = azurerm_subnet.this[subnet_key].delegation[0].service_delegation[0].name,
              actions = azurerm_subnet.this[subnet_key].delegation[0].service_delegation[0].actions
            }
          },
          expected = subnet.delegation == null ? null : {
            name               = values(subnet.delegation)[0].name,
            service_delegation = values(subnet.delegation)[0].service_delegation
          }
        }
      })
    ])
  }

  # Check if NSG is created and named correctly
  assert {
    condition = alltrue([
      for key, vnet in var.connectivity :
      vnet.security_group_name == null || azurerm_network_security_group.this[key].name == vnet.security_group_name
    ])
    error_message = join("\n", [
      "NSG name mismatch. Details:",
      jsonencode({
        for key, vnet in var.connectivity : key => {
          expected_name = vnet.security_group_name,
          actual_name   = try(azurerm_network_security_group.this[key].name, null),
          matches       = vnet.security_group_name == null || azurerm_network_security_group.this[key].name == vnet.security_group_name
        } if vnet.security_group_name != null
      })
    ])
  }

  # Verify NSG associations with subnets
  assert {
    condition = alltrue([
      for subnet_key, subnet in local.subnets :
      var.connectivity[subnet.network_key].security_group_name == null ||
      contains(keys(azurerm_subnet_network_security_group_association.this), subnet_key)
    ])
    error_message = join("\n", [
      "NSG association mismatch. Details:",
      jsonencode({
        for subnet_key, subnet in local.subnets : subnet_key => {
          vnet_name       = var.connectivity[subnet.network_key].virtual_network_name,
          expected_nsg    = var.connectivity[subnet.network_key].security_group_name,
          has_association = contains(keys(azurerm_subnet_network_security_group_association.this), subnet_key)
        } if var.connectivity[subnet.network_key].security_group_name != null
      })
    ])
  }
}

run "virtual_hub_connection" {
  command = plan

  variables {
    // Override the project ID from bootstrap_create_tfc_test_project
    tfe = merge(var.tfe, {
      project = merge(var.tfe.project, {
        id = run.bootstrap_create_tfc_test_project.id
      })
    })

    // Override the virtual networks and add hub connection configuration
    connectivity = merge(var.connectivity, {
      min = merge(var.connectivity.min, {
        peerings = merge(var.connectivity.min.peerings, {
          min_hub = merge(var.connectivity.min.peerings.min_hub, {
            remote_virtual_network_id = run.setup_create_hub_vnet.virtual_network_id
          })
        })
      }),
      max = merge(var.connectivity.max, {
        peerings = merge(var.connectivity.max.peerings, {
          max_hub = merge(var.connectivity.max.peerings.max_hub, {
            remote_virtual_network_id = run.setup_create_hub_vnet.virtual_network_id
          })
        }),
        virtual_hub_connection = {
          name = "hub-connection-test"
          id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualHubs/test-hub"
        }
      })
    })
  }

  module {
    source = "./"
  }

  # Verify virtual hub connection name and ID
  assert {
    condition = alltrue([
      try(azurerm_virtual_hub_connection.this["max"].name, null) == try(var.connectivity["max"].virtual_hub_connection.name, null),
      try(azurerm_virtual_hub_connection.this["max"].virtual_hub_id, null) == try(var.connectivity["max"].virtual_hub_connection.id, null)
    ])
    error_message = join("\n", [
      "Virtual hub connection configuration mismatch. Details:",
      jsonencode({
        name = {
          actual   = try(azurerm_virtual_hub_connection.this["max"].name, null),
          expected = try(var.connectivity["max"].virtual_hub_connection.name, null),
          matches  = try(azurerm_virtual_hub_connection.this["max"].name, null) == try(var.connectivity["max"].virtual_hub_connection.name, null)
        },
        hub_id = {
          actual   = try(azurerm_virtual_hub_connection.this["max"].virtual_hub_id, null),
          expected = try(var.connectivity["max"].virtual_hub_connection.id, null),
          matches  = try(azurerm_virtual_hub_connection.this["max"].virtual_hub_id, null) == try(var.connectivity["max"].virtual_hub_connection.id, null)
        }
      })
    ])
  }
}
