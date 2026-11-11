# LIVE integration test. Run only in approved, non-production Azure/TFC test accounts.
# Uses fixture-owned zones/records, never a central production DNS zone.
provider "tfe" {}
provider "azuread" {}
provider "azurerm" {
  features {}
}
provider "azurerm" {
  alias           = "connectivity"
  subscription_id = run.overrides.connectivity_subscription_id
  features {}
}

test {
  parallel = false
}

run "overrides" {
  module {
    source = "./tests/overrides"
  }
}

run "setup_dns" {
  providers = {
    azurerm = azurerm.connectivity
  }
  module {
    source = "./tests/setup-private-dns"
  }
  assert {
    condition     = lower(run.overrides.connectivity_subscription_id) != lower(var.subscription_id)
    error_message = "This test requires separate workload and connectivity subscriptions in the same tenant. Use non-production test subscriptions."
  }
  assert {
    condition     = lower(output.tenant_id) == lower(var.tenant_id)
    error_message = "The connectivity provider must authenticate to the workload tenant for this cross-subscription test."
  }
}

run "setup_tfc_project" {
  variables {
    tfc_project_name = "tests_dns_${run.setup_dns.suffix}"
  }
  module {
    source = "./tests/setup-tfe-project"
  }
}

variables {
  tfe = {
    organization_name     = "blinq-west-lab"
    project               = { id = "# Overridden", name = "# Overridden" }
    workspace_name        = "# Overridden"
    workspace_description = "Station DNS link integration test"
  }
  connectivity = {
    first = {
      virtual_network_name = "vnet-stationtest-dns-first"
      address_space        = ["10.91.0.0/24"]
      subnets              = {}
    }
    second = {
      virtual_network_name   = "vnet-stationtest-dns-second"
      address_space          = ["10.92.0.0/24"]
      subnets                = {}
      private_dns_zone_links = {}
    }
  }
}

run "minimum" {
  variables {
    resource_group_name = "stationtest-dns-${run.setup_dns.suffix}"
    tfe = merge(var.tfe, {
      project        = { id = run.setup_tfc_project.id, name = "tests_dns_${run.setup_dns.suffix}" }
      workspace_name = "stationtest-dns-${run.setup_dns.suffix}"
    })
  }
  module {
    source = "./"
  }
  assert {
    condition     = length(output.private_dns_zone_links) == 0
    error_message = "Omitted and empty DNS link maps must create no links."
  }
}

run "maximum" {
  variables {
    resource_group_name = "stationtest-dns-${run.setup_dns.suffix}"
    tfe = merge(var.tfe, {
      project        = { id = run.setup_tfc_project.id, name = "tests_dns_${run.setup_dns.suffix}" }
      workspace_name = "stationtest-dns-${run.setup_dns.suffix}"
    })
    connectivity = {
      for network_key, network in var.connectivity : network_key => merge(network, {
        private_dns_zone_links = {
          for zone_key, zone in run.setup_dns.zones : zone_key => {
            name                = "${network_key}-${zone_key}"
            private_dns_zone_id = zone.id
          } if network_key == "first" || zone_key == "shared"
        }
      })
    }
  }
  module {
    source = "./"
  }
  assert {
    condition = toset(keys(output.private_dns_zone_links)) == toset([
      jsonencode(["first", "shared"]), jsonencode(["first", "other"]), jsonencode(["second", "shared"])
    ])
    error_message = "Multiple zones, shared zones and repeated map keys must produce three distinct links."
  }
  assert {
    condition = alltrue(flatten([
      for network_key, network in var.connectivity : [
        for link_key, link in network.private_dns_zone_links :
        lower(output.private_dns_zone_links[jsonencode([network_key, link_key])].id) == lower("${link.private_dns_zone_id}/virtualNetworkLinks/${link.name}") &&
        output.private_dns_zone_links[jsonencode([network_key, link_key])].name == link.name &&
        output.private_dns_zone_links[jsonencode([network_key, link_key])].virtual_network_id == output.virtual_networks[network_key].id &&
        output.private_dns_zone_links[jsonencode([network_key, link_key])].registration_enabled == false
      ]
    ]))
    error_message = "Each link must belong to the fixture zone in the connectivity subscription and target its enclosing workload VNet without registration."
  }
  assert {
    condition     = alltrue([for network in values(output.virtual_networks) : startswith(lower(network.id), "/subscriptions/${lower(var.subscription_id)}/")])
    error_message = "The linked VNets must remain in the separate workload subscription."
  }
}

run "unchanged_plan" {
  command = plan
  variables {
    resource_group_name = "stationtest-dns-${run.setup_dns.suffix}"
    tfe = merge(var.tfe, {
      project        = { id = run.setup_tfc_project.id, name = "tests_dns_${run.setup_dns.suffix}" }
      workspace_name = "stationtest-dns-${run.setup_dns.suffix}"
    })
    connectivity = {
      for network_key, network in var.connectivity : network_key => merge(network, {
        private_dns_zone_links = {
          for zone_key, zone in run.setup_dns.zones : zone_key => {
            name                = "${network_key}-${zone_key}"
            private_dns_zone_id = zone.id
          } if network_key == "first" || zone_key == "shared"
        }
      })
    }
  }
  module {
    source = "./"
  }
  assert {
    condition     = output.private_dns_zone_links == run.maximum.private_dns_zone_links && output.virtual_networks == run.maximum.virtual_networks
    error_message = "An unchanged plan must preserve all link and VNet attributes and IDs without replacements."
  }
}

run "unchanged_reapply" {
  variables {
    resource_group_name = "stationtest-dns-${run.setup_dns.suffix}"
    tfe = merge(var.tfe, {
      project        = { id = run.setup_tfc_project.id, name = "tests_dns_${run.setup_dns.suffix}" }
      workspace_name = "stationtest-dns-${run.setup_dns.suffix}"
    })
    connectivity = {
      for network_key, network in var.connectivity : network_key => merge(network, {
        private_dns_zone_links = {
          for zone_key, zone in run.setup_dns.zones : zone_key => {
            name                = "${network_key}-${zone_key}"
            private_dns_zone_id = zone.id
          } if network_key == "first" || zone_key == "shared"
        }
      })
    }
  }
  module {
    source = "./"
  }
  assert {
    condition     = output.private_dns_zone_links == run.maximum.private_dns_zone_links && output.virtual_networks == run.maximum.virtual_networks
    error_message = "An unchanged reapply must retain all link and VNet attributes and IDs."
  }
}

run "remove_links" {
  variables {
    resource_group_name = "stationtest-dns-${run.setup_dns.suffix}"
    tfe = merge(var.tfe, {
      project        = { id = run.setup_tfc_project.id, name = "tests_dns_${run.setup_dns.suffix}" }
      workspace_name = "stationtest-dns-${run.setup_dns.suffix}"
    })
  }
  module {
    source = "./"
  }
  assert {
    condition     = length(output.private_dns_zone_links) == 0 && output.virtual_networks == run.maximum.virtual_networks
    error_message = "Link removal must preserve the VNets."
  }
}

# Fresh Azure reads, after link removal and BEFORE fixture teardown.
run "verify_external_dns_preserved" {
  command = plan
  providers = {
    azurerm = azurerm.connectivity
  }
  variables {
    zones = run.setup_dns.zones
  }
  module {
    source = "./tests/check-private-dns"
  }
  assert {
    condition = alltrue([
      for key, zone in run.setup_dns.zones :
      lower(output.zones[key].id) == lower(zone.id) &&
      lower(output.records[key].id) == lower(run.setup_dns.records[key].id) &&
      output.records[key].records == run.setup_dns.records[key].records &&
      output.records[key].ttl == run.setup_dns.records[key].ttl
    ])
    error_message = "Both external zones and their sentinel records must still exist unchanged after Station removes its links."
  }
}
