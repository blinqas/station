provider "tfe" {}

provider "azurerm" {
  features {}
}

provider "azuread" {}


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


variables {
  tfe = {
    project_name          = "test_peering"
    organization_name     = "blinq-west-lab"
    workspace_name        = "peering_test"
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
      subnets = {
        main = {
          name             = "snet-app"
          address_prefixes = ["10.0.56.0/24"]
        }
        other = {
          name             = "snet-app2"
          address_prefixes = ["10.0.57.0/24"]
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

run "setup_create_tfc_test_project" {
  variables {
    tfc_project_name = "test_peering"
  }
  module {
    source = "./tests/setup-tfe-project"
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
    error_message = "The virtual network names do not match the expected names from input variables."
  }

  # Verify that VNets are in the correct resource groups
  assert {
    condition = alltrue([
      azurerm_virtual_network.this["min"].resource_group_name == "rg-${var.resource_group_name}",
      azurerm_virtual_network.this["max"].resource_group_name == var.connectivity["max"].resource_group_name
    ])
    error_message = "The virtual networks are not deployed in the expected resource groups."
  }

  # Validate Address Prefixes for VNets
  assert {
    condition = alltrue([
      for key, vnet in azurerm_virtual_network.this :
      vnet.address_space == var.connectivity[key].address_space
    ])
    error_message = "The address space for one or more virtual networks does not match the expected value."
  }

  # Validate Peering Configurations
  assert {
    condition = alltrue([
      // Validate allow_forwarded_traffic
      azurerm_virtual_network_peering.to["min_hub"].allow_forwarded_traffic == var.connectivity["min"].peerings["min_hub"].allow_forwarded_traffic,
      azurerm_virtual_network_peering.to["max_hub"].allow_forwarded_traffic == var.connectivity["max"].peerings["max_hub"].allow_forwarded_traffic,

      // Validate allow_virtual_network_access
      azurerm_virtual_network_peering.to["min_hub"].allow_virtual_network_access == try(var.connectivity["min"].peerings["min_hub"].allow_virtual_network_access, true), //Should default to true when not provided
      azurerm_virtual_network_peering.to["max_hub"].allow_virtual_network_access == var.connectivity["max"].peerings["max_hub"].allow_virtual_network_access,

      // Validate allow_gateway_transit
      azurerm_virtual_network_peering.to["min_hub"].allow_gateway_transit == try(var.connectivity["min"].peerings["min_hub"].allow_gateway_transit, false), //Should default to false when not provided
      azurerm_virtual_network_peering.to["max_hub"].allow_gateway_transit == var.connectivity["max"].peerings["max_hub"].allow_gateway_transit,

    ])
    error_message = "The peering settings are not as expected."
  }

  # Validate Subnet Names and Address Prefixes
  assert {
    condition = alltrue(flatten([
      for key, vnet in azurerm_virtual_network.this : [
        for subnet_key, subnet in var.connectivity[key].subnets :
        anytrue([
          for created_subnet in vnet.subnet :
          created_subnet.name == subnet.name && created_subnet.address_prefixes == subnet.address_prefixes
        ])
      ]
    ]))
    error_message = "The virtual networks do not have the expected subnets with correct address prefixes."
  }

  # Ensure the correct number of VNets was created
  assert {
    condition     = length(azurerm_virtual_network.this) == length(var.connectivity)
    error_message = "The number of created VNets does not match the expected count."
  }

  # Ensure the correct number of subnets per VNet
  assert {
    condition = alltrue([
      for key, vnet in azurerm_virtual_network.this :
      length(vnet.subnet) == length(var.connectivity[key].subnets)
    ])
    error_message = "One or more virtual networks do not contain the expected number of subnets."
  }

  # Check if all expected subnet delegations exist
  assert {
    condition = alltrue(flatten([
      for key, vnet in azurerm_virtual_network.this : [
        for subnet_key, subnet in var.connectivity[key].subnets :
        subnet.delegation == null || anytrue([
          for created_subnet in vnet.subnet :
          created_subnet.name == subnet.name && created_subnet.delegation == subnet.delegation
        ])
      ]
    ]))
    error_message = "Subnet delegation settings do not match the expected values."
  }
}
