# All providers are mocked: these tests never authenticate or create Azure/TFC resources.
mock_provider "azurerm" {
  mock_resource "azurerm_private_dns_zone_virtual_network_link" {
    defaults = {
      id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-wrong/providers/Microsoft.Network/privateDnsZones/wrong.example/virtualNetworkLinks/wrong-provider"
    }
  }
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-workload"
    }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-workload/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mock"
      principal_id = "33333333-3333-3333-3333-333333333333"
      client_id    = "44444444-4444-4444-4444-444444444444"
    }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-workload/providers/Microsoft.Network/virtualNetworks/mock"
    }
  }
}

mock_provider "azurerm" {
  alias = "connectivity"
  mock_resource "azurerm_private_dns_zone_virtual_network_link" {
    defaults = {
      id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/shared.example/virtualNetworkLinks/mock"
    }
  }
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
      tenant_id       = "22222222-2222-2222-2222-222222222222"
    }
  }
}

mock_provider "azuread" {
  mock_data "azuread_application_published_app_ids" {
    defaults = {
      result = { MicrosoftGraph = "00000003-0000-0000-c000-000000000000" }
    }
  }
}

mock_provider "tfe" {}
mock_provider "random" {}
mock_provider "time" {}

override_module {
  target = module.station-tfe
  outputs = {
    workspace           = {}
    workspace_variables = {}
    workspace_settings  = {}
  }
}

override_resource {
  target = azurerm_virtual_network.this["first"]
  values = {
    id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-workload/providers/Microsoft.Network/virtualNetworks/first"
  }
}

override_resource {
  target = azurerm_virtual_network.this["second"]
  values = {
    id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-workload/providers/Microsoft.Network/virtualNetworks/second"
  }
}

variables {
  tenant_id       = "22222222-2222-2222-2222-222222222222"
  subscription_id = "11111111-1111-1111-1111-111111111111"
  tfe = {
    organization_name     = "mock-only"
    project               = { id = "prj-mock", name = "mock" }
    workspace_name        = "dns-mock"
    workspace_description = "Mocked DNS link tests"
  }
  connectivity = {
    omitted = {
      virtual_network_name = "vnet-omitted"
      address_space        = ["10.1.0.0/24"]
      subnets              = {}
    }
    empty = {
      virtual_network_name   = "vnet-empty"
      address_space          = ["10.2.0.0/24"]
      subnets                = {}
      private_dns_zone_links = {}
    }
  }
}

run "no_connectivity" {
  command = plan
  variables {
    connectivity = {}
  }
  assert {
    condition     = length(output.private_dns_zone_links) == 0 && length(output.virtual_networks) == 0 && length(data.azurerm_client_config.connectivity) == 0
    error_message = "An empty connectivity input must preserve the no-network default without new provider reads."
  }
}

run "minimum" {
  command = plan

  assert {
    condition     = length(output.private_dns_zone_links) == 0 && length(data.azurerm_client_config.connectivity) == 0
    error_message = "Omitted and empty DNS link maps must create no links and require no new connectivity-provider reads."
  }
  assert {
    condition     = length(output.virtual_networks) == 2 && length(output.subnets) == 0
    error_message = "Existing VNet and subnet configuration must remain unchanged."
  }
}

run "maximum" {
  variables {
    connectivity = {
      first = {
        virtual_network_name = "vnet-first"
        address_space        = ["10.1.0.0/24"]
        subnets              = {}
        private_dns_zone_links = {
          shared = {
            name                = "first-shared"
            private_dns_zone_id = "/SUBSCRIPTIONS/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/RESOURCEGROUPS/rg-dns/PROVIDERS/microsoft.network/PRIVATEDNSZONES/shared.example"
          }
          other = {
            name                = "first-other"
            private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-other/providers/Microsoft.Network/privateDnsZones/other.example"
          }
        }
      }
      second = {
        virtual_network_name = "vnet-second"
        address_space        = ["10.2.0.0/24"]
        subnets              = {}
        private_dns_zone_links = {
          shared = {
            name                = "second-shared"
            private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/shared.example"
          }
        }
      }
    }
  }

  assert {
    condition = toset(keys(output.private_dns_zone_links)) == toset([
      jsonencode(["first", "shared"]), jsonencode(["first", "other"]), jsonencode(["second", "shared"])
    ])
    error_message = "Different VNets may reuse a link key and share a zone, while one VNet may link multiple zones."
  }
  assert {
    condition = alltrue(flatten([
      for network_key, network in var.connectivity : [
        for link_key, link in network.private_dns_zone_links :
        output.private_dns_zone_links[jsonencode([network_key, link_key])].name == link.name &&
        output.private_dns_zone_links[jsonencode([network_key, link_key])].virtual_network_id == output.virtual_networks[network_key].id &&
        output.private_dns_zone_links[jsonencode([network_key, link_key])].registration_enabled == false &&
        length(output.private_dns_zone_links[jsonencode([network_key, link_key])].id) > 0
      ]
    ]))
    error_message = "Links must expose IDs, preserve explicit names, reference their enclosing VNet and disable registration."
  }
  assert {
    condition = (
      output.private_dns_zone_links[jsonencode(["first", "shared"])].private_dns_zone_name == "shared.example" &&
      output.private_dns_zone_links[jsonencode(["first", "shared"])].resource_group_name == "rg-dns" &&
      output.private_dns_zone_links[jsonencode(["first", "other"])].private_dns_zone_name == "other.example" &&
      output.private_dns_zone_links[jsonencode(["first", "other"])].resource_group_name == "rg-other"
    )
    error_message = "Zone names and resource groups must come from the supplied zone IDs, including mixed-case resource paths."
  }
  assert {
    condition     = length(output.role_assignments.lz_identity) == 0 && length(output.role_assignments.others) == 0 && length(output.landing_zone_identity.app_role_assignments) == 0
    error_message = "DNS consumption must not grant identity permissions."
  }
  assert {
    condition     = alltrue([for link in values(output.private_dns_zone_links) : startswith(link.id, "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/")])
    error_message = "DNS link resources must use the connectivity provider, not the workload provider."
  }
}

run "unchanged_plan" {
  command = plan
  variables {
    connectivity = {
      for key, network in run.maximum.virtual_networks : key => {
        virtual_network_name = network.name
        address_space        = network.address_space
        subnets              = {}
        private_dns_zone_links = {
          for link_key in(key == "first" ? ["shared", "other"] : ["shared"]) : link_key => {
            name = run.maximum.private_dns_zone_links[jsonencode([key, link_key])].name
            private_dns_zone_id = format("/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/%s/providers/Microsoft.Network/privateDnsZones/%s",
              run.maximum.private_dns_zone_links[jsonencode([key, link_key])].resource_group_name,
            run.maximum.private_dns_zone_links[jsonencode([key, link_key])].private_dns_zone_name)
          }
        }
      }
    }
  }
  assert {
    condition     = output.private_dns_zone_links == run.maximum.private_dns_zone_links
    error_message = "An unchanged plan must retain all link attributes and IDs without replacements or duplicate instances."
  }
}

run "unchanged_reapply" {
  variables {
    connectivity = {
      for key, network in run.maximum.virtual_networks : key => {
        virtual_network_name = network.name
        address_space        = network.address_space
        subnets              = {}
        private_dns_zone_links = {
          for link_key in(key == "first" ? ["shared", "other"] : ["shared"]) : link_key => {
            name = run.maximum.private_dns_zone_links[jsonencode([key, link_key])].name
            private_dns_zone_id = format("/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/%s/providers/Microsoft.Network/privateDnsZones/%s",
              run.maximum.private_dns_zone_links[jsonencode([key, link_key])].resource_group_name,
            run.maximum.private_dns_zone_links[jsonencode([key, link_key])].private_dns_zone_name)
          }
        }
      }
    }
  }
  assert {
    condition     = output.private_dns_zone_links == run.maximum.private_dns_zone_links && output.virtual_networks == run.maximum.virtual_networks
    error_message = "An unchanged mocked reapply must retain all links and VNets. Live service idempotency requires the integration test."
  }
}

run "remove_links" {
  variables {
    connectivity = {
      for key, network in run.maximum.virtual_networks : key => {
        virtual_network_name = network.name
        address_space        = network.address_space
        subnets              = {}
      }
    }
  }
  assert {
    condition     = length(output.private_dns_zone_links) == 0 && output.virtual_networks == run.maximum.virtual_networks
    error_message = "Removing all links must preserve the managed VNets. External zone/record preservation is verified by the live fixture test, not mocks."
  }
}

run "malformed_id" {
  command = plan
  variables {
    connectivity = {
      invalid = {
        virtual_network_name = "vnet-invalid"
        address_space        = ["10.3.0.0/24"]
        subnets              = {}
        private_dns_zone_links = {
          invalid = { name = "invalid", private_dns_zone_id = "not-an-azure-id" }
        }
      }
    }
  }
  expect_failures = [var.connectivity]
}

run "wrong_resource_id" {
  command = plan
  variables {
    connectivity = {
      invalid = {
        virtual_network_name = "vnet-invalid"
        address_space        = ["10.3.0.0/24"]
        subnets              = {}
        private_dns_zone_links = {
          invalid = { name = "invalid", private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-dns/providers/Microsoft.Network/dnsZones/public.example" }
        }
      }
    }
  }
  expect_failures = [var.connectivity]
}

run "child_resource_id" {
  command = plan
  variables {
    connectivity = {
      invalid = {
        virtual_network_name = "vnet-invalid"
        address_space        = ["10.3.0.0/24"]
        subnets              = {}
        private_dns_zone_links = {
          invalid = { name = "invalid", private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/shared.example/virtualNetworkLinks/existing" }
        }
      }
    }
  }
  expect_failures = [var.connectivity]
}

run "duplicate_zone_case_insensitive" {
  command = plan
  variables {
    connectivity = {
      invalid = {
        virtual_network_name = "vnet-invalid"
        address_space        = ["10.3.0.0/24"]
        subnets              = {}
        private_dns_zone_links = {
          first  = { name = "first", private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/shared.example" }
          second = { name = "second", private_dns_zone_id = "/SUBSCRIPTIONS/AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA/RESOURCEGROUPS/RG-DNS/PROVIDERS/MICROSOFT.NETWORK/PRIVATEDNSZONES/SHARED.EXAMPLE" }
        }
      }
    }
  }
  expect_failures = [var.connectivity]
}

run "wrong_subscription" {
  command = plan
  variables {
    connectivity = {
      invalid = {
        virtual_network_name = "vnet-invalid"
        address_space        = ["10.3.0.0/24"]
        subnets              = {}
        private_dns_zone_links = {
          invalid = { name = "invalid", private_dns_zone_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/shared.example" }
        }
      }
    }
  }
  expect_failures = [azurerm_private_dns_zone_virtual_network_link.this]
}

run "separator_keys" {
  command = plan
  variables {
    connectivity = {
      "a.b" = {
        virtual_network_name = "vnet-ab"
        address_space        = ["10.4.0.0/24"]
        subnets              = {}
        private_dns_zone_links = {
          c = { name = "ab-c", private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/shared.example" }
        }
      }
      a = {
        virtual_network_name = "vnet-a"
        address_space        = ["10.5.0.0/24"]
        subnets              = {}
        private_dns_zone_links = {
          "b.c" = { name = "a-bc", private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/shared.example" }
        }
      }
    }
  }
  assert {
    condition     = toset(keys(output.private_dns_zone_links)) == toset([jsonencode(["a.b", "c"]), jsonencode(["a", "b.c"])])
    error_message = "Composite identities must not collide when VNet or link keys contain separators."
  }
}

run "null_zone_id" {
  command = plan
  variables {
    connectivity = {
      invalid = {
        virtual_network_name = "vnet-invalid"
        address_space        = ["10.3.0.0/24"]
        subnets              = {}
        private_dns_zone_links = {
          invalid = { name = "invalid", private_dns_zone_id = null }
        }
      }
    }
  }
  expect_failures = [var.connectivity]
}

run "blank_link_name" {
  command = plan
  variables {
    connectivity = {
      invalid = {
        virtual_network_name = "vnet-invalid"
        address_space        = ["10.3.0.0/24"]
        subnets              = {}
        private_dns_zone_links = {
          invalid = { name = "  ", private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/shared.example" }
        }
      }
    }
  }
  expect_failures = [var.connectivity]
}

run "duplicate_zone" {
  command = plan
  variables {
    connectivity = {
      invalid = {
        virtual_network_name = "vnet-invalid"
        address_space        = ["10.3.0.0/24"]
        subnets              = {}
        private_dns_zone_links = {
          first  = { name = "first", private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/shared.example" }
          second = { name = "second", private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/shared.example" }
        }
      }
    }
  }
  expect_failures = [var.connectivity]
}

# Validate live-fixture schemas/wiring without claiming live preservation proof.
run "setup_fixture_contract" {
  command = plan
  providers = {
    azurerm = azurerm.connectivity
  }
  module {
    source = "./tests/setup-private-dns"
  }
  assert {
    condition     = length(output.zones) == 2 && length(output.records) == 2
    error_message = "The integration fixture must own two zones and two sentinel records independently of Station."
  }
}

run "preservation_read_contract" {
  command = plan
  providers = {
    azurerm = azurerm.connectivity
  }
  variables {
    zones = {
      shared = { name = "shared.station.test", resource_group_name = "rg-fixture" }
      other  = { name = "other.station.test", resource_group_name = "rg-fixture" }
    }
  }
  module {
    source = "./tests/check-private-dns"
  }
  assert {
    condition     = length(output.zones) == 2 && length(output.records) == 2
    error_message = "The preservation helper must read every supplied zone and sentinel record through the selected provider."
  }
}
