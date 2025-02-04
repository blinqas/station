provider "tfe" {}
provider "azurerm" {
  features {}
}
provider "azuread" {

}


run "setup_create_hub_vnet" {
  variables {
    remote_vnet_name          = "remote_hub_network" # Update the remote_virtual_network_id if this is changed
    remote_vnet_address_space = "10.0.58.0/23"
    resource_group_name       = "rg-test-peering-hub" # Update the remote_virtual_network_id if this is changed
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
      agent_pool_id  = null # Not adding this as it will require us to setup a private runner
    }
  }

  resource_group_name = "test-peering-01"

  connectivity = {
    dev = {
      virtual_network_name = "vnet-my-lz-dev"
      address_space        = ["10.0.54.0/23"]
      subnets = {
        main = {
          name             = "snet-main-dev"
          address_prefixes = ["10.0.54.0/24"]
        }
      }

      peerings = {
        dev_hub = {
          name                      = "peer-lz-dev"
          remote_virtual_network_id = "This has to be overrided by the output from the setup_create_hub_vnet module"
          allow_forwarded_traffic   = false
        }
      }
    }
    prod = {
      virtual_network_name = "vnet-my-lz2-prod"
      resource_group_name  = "rg-test-peering-hub"
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
        prod_hub = {
          name                      = "peer-lz-prod"
          resource_group_name       = "rg-test-peering-hub"
          remote_virtual_network_id = "This has to be overrided by the output from the setup_create_hub_vnet module"
          allow_forwarded_traffic   = true
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
    //Overide the dev network to use the outputed vnet ID from the setup_create_hub_vnet module
    connectivity = merge(var.connectivity, {
      dev = merge(var.connectivity.dev, {
        peerings = merge(var.connectivity.dev.peerings, {
          dev_hub = merge(var.connectivity.dev.peerings.dev_hub, {
            remote_virtual_network_id = run.setup_create_hub_vnet.virtual_network_id
          })
        })
      }),
      //Overide the prod network to use the outputed vnet ID from the setup_create_hub_vnet module
      prod = merge(var.connectivity.prod, {
        peerings = merge(var.connectivity.prod.peerings, {
          prod_hub = merge(var.connectivity.prod.peerings.prod_hub, {
            remote_virtual_network_id = run.setup_create_hub_vnet.virtual_network_id
          })
        })
      })
    })
  }

  module {
    source = "./"
  }

  assert {
    condition = alltrue([
      for key, vnet in azurerm_virtual_network.this :
        vnet.name == var.connectivity[key].virtual_network_name
    ])
    error_message = "The virtual network names do not match the expected names from input variables."
  }

  assert {
    condition = alltrue([
      azurerm_virtual_network.this["dev"].resource_group_name == "rg-${var.resource_group_name}",
      azurerm_virtual_network.this["prod"].resource_group_name == var.connectivity["prod"].resource_group_name
    ])
    error_message = "The virtual networks are not deployed in the expected resource groups."
  }

  assert {
    condition = alltrue([
      azurerm_virtual_network_peering.to["dev_hub"].allow_forwarded_traffic == var.connectivity["dev"].peerings["dev_hub"].allow_forwarded_traffic,
      azurerm_virtual_network_peering.to["prod_hub"].allow_forwarded_traffic == var.connectivity["prod"].peerings["prod_hub"].allow_forwarded_traffic
    ])
    error_message = "The peering settings are not as expected."
  }



  assert {
    condition = alltrue(flatten([
      for key, vnet in azurerm_virtual_network.this : [
        for subnet_key, subnet in var.connectivity[key].subnets :
          contains([
            for created_subnet in vnet.subnet : created_subnet.name
          ], subnet.name)
      ]
    ]))
    error_message = "The virtual networks do not have the expected subnets."
  }
}
