variable "tenant_id" {
  type        = string
  description = "(Required) The Entra ID tenant ID used by the caller."
}

variable "subscription_id" {
  type        = string
  description = "(Required) The Azure subscription ID used by the caller."
}

variable "default_location" {
  description = "The name of the default location to deploy workload resources to."
  default     = "norwayeast"
  type        = string
}

variable "resource_group_name" {
  description = <<EOF
    The name of the workload resource group. The final name is prefixed with `rg-`.

    If a value is not provided, Station will set the name to `rg-var.tfe.workspace_name`
  EOF
  default     = null
  type        = string
}

variable "resource_groups" {
  description = "Map of resource groups to create"
  default     = {}
  type = map(object({
    name     = string
    location = optional(string)
    tags     = optional(map(string))
  }))
}

variable "tags" {
  description = <<EOF
    Tags to merge with the default tags configured by Station.

    Station configures the following map in tags.tf:
    {
      "station-id"  = random_id.workload.hex
    }
  EOF
  default     = {}
  type        = map(string)
}

variable "groups" {
  description = <<-EOF
    (Optional) Map of Entra ID (Azure AD) groups to create
    Note: The workload identity is automatically assigned the App Role "User.ReadBasic.All" and "Group.Read.All"
          because being "Owner" of the group is not sufficient to add principals and then list them after an add or delete operation.
  EOF
  default     = {}
  type = map(object({
    display_name     = string
    description      = optional(string)
    owners           = optional(list(string))
    members          = optional(set(string))
    security_enabled = optional(bool, true)
    mail_enabled     = optional(bool)
    types            = optional(set(string))
    dynamic_membership = optional(object({
      enabled = bool
      rule    = string
    }))
    role_assignments = optional(map(object({
      name                             = optional(string)
      scope                            = optional(string)
      role_definition_id               = optional(string)
      role_definition_name             = optional(string)
      condition                        = optional(string)
      condition_version                = optional(string)
      description                      = optional(string)
      skip_service_principal_aad_check = optional(bool)

      pim = optional(object({
        member_type     = optional(string, "Eligible")
        start_date_time = optional(string)
        expiration = optional(object({
          duration_days  = optional(number)
          duration_hours = optional(number)
          end_date_time  = optional(string)
        }))
        justification = optional(string)
        ticket_number = optional(string)
        ticket_system = optional(string)
      }))
    })))
  }))
}

variable "user_assigned_identities" {
  description = <<EOF
  User Assigned Identities to create.

  Example:

  user_assigned_identities = {
    my_app = {
      name                = "uai-my-identity"
      resource_group_name = "rg-name"
      location            = "norwayeast"
      app_role_assignments = {
        Application.ReadWrite.OwnedBy = {
          app_role_id        = "18a4783c-866b-4cc7-a460-3d5e5662c884"
          resource_object_id = "microsoft-graph-enterprise-app-object-id"
        }
      }
      group_memberships = {
        "Kubernetes Administrators" = azuread_group.k8s_admins.object_id
      }
      directory_role_assignments = {
        role_name                      = "Application Administrator"
      }
    }
  }
  EOF
  default     = {}
  type = map(object({
    name                = string
    resource_group_name = optional(string)
    location            = optional(string)
    app_role_assignments = optional(map(object({
      app_role_id        = string
      resource_object_id = string
    })), {})
    role_assignments = optional(map(object({
      name                                   = optional(string)
      scope                                  = string
      role_definition_id                     = optional(string)
      role_definition_name                   = optional(string)
      principal_id                           = optional(string)
      assign_to_workload_principal           = optional(bool)
      condition                              = optional(string)
      condition_version                      = optional(string)
      delegated_managed_identity_resource_id = optional(string)
      description                            = optional(string)
      skip_service_principal_aad_check       = optional(bool)

      pim = optional(object({
        member_type     = optional(string, "Eligible")
        start_date_time = optional(string)
        expiration = optional(object({
          duration_days  = optional(number)
          duration_hours = optional(number)
          end_date_time  = optional(string)
        }))
        justification = optional(string)
        ticket_number = optional(string)
        ticket_system = optional(string)
      }))
    })), {})
    group_memberships = optional(map(string), {})
    directory_role_assignments = optional(map(object({
      role_name          = optional(string)
      app_scope_id       = optional(string)
      directory_scope_id = optional(string)
    })), {})
  }))
}

variable "tfe" {
  description = <<EOF
  Terraform Cloud configuration for the workload environment

  - Either of tfe.vcs_repo.(oauth_token_id|github_app_installation_id) must be provided, both can not be used at the same time.
  - tfe.workspace_env_vars lets you configure Environment Variables for the Terraform Cloud runtime environment
  - tfe.workspace_vars lets you configure Terraform variables
    resource into respective Terraform variables on the Terraform Cloud workspace. Useful when you need group object ids
    for the groups Station Deployments provisioned in your workload environment.
  - tfe.workspace_settings lets you configure the workspace settings like agent_pool_id and execution_mode. If agent_pool_id is provided, execution_mode must be set to "agent".
  EOF
  default     = null
  type = object({
    organization_name = string
    project = object({
      id   = string
      name = string
    })
    workspace_name        = string
    workspace_description = string
    workspace_settings = optional(object({
      agent_pool_id  = optional(string)
      execution_mode = optional(string)
    }))
    file_triggers_enabled = optional(bool)
    vcs_repo = optional(object({
      identifier                 = string
      branch                     = optional(string)
      ingress_submodules         = optional(string)
      oauth_token_id             = optional(string)
      github_app_installation_id = optional(string)
      tags_regex                 = optional(string)
    }))
    workspace_env_vars = optional(map(object({
      value       = string
      category    = string
      description = string
      sensitive   = optional(bool, false)
    })))
    workspace_vars = optional(map(object({
      value       = any
      category    = string
      description = string
      hcl         = optional(bool, false)
      sensitive   = optional(bool, false)
    })))
  })
}

variable "role_assignments" {
  description = <<EOF
    Map of role_assignments to create. Be careful of who is allowed to provision role_assignments, you might want to 
    consider Sentinel policies in TFC.

    PIM Support (optional 'pim' block):
    - member_type: "Eligible" or "Active" (default: "Eligible" if pim block is provided).
    - start_date_time: Optional start date/time in RFC3339 format (e.g., "2024-01-15T00:00:00Z").
    - expiration:
        - duration_days: Number of days until expiration (e.g., 90).
        - duration_hours: Number of hours until expiration (alternative to duration_days).
        - end_date_time: Specific end date/time in RFC3339 format (alternative to duration_days/duration_hours).
    - justification: Optional justification text for the assignment.
    - ticket_number: Optional ticket number for the assignment.
    - ticket_system: Optional ticket system identifier.

    Note: When 'pim' block is specified, a PIM role assignment will be created instead of a regular role assignment.
  EOF
  default     = {}
  type = map(object({
    name                                   = optional(string)
    scope                                  = string
    role_definition_id                     = optional(string)
    role_definition_name                   = optional(string)
    principal_id                           = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    delegated_managed_identity_resource_id = optional(string)
    description                            = optional(string)
    skip_service_principal_aad_check       = optional(bool, false)

    pim = optional(object({
      member_type     = optional(string, "Eligible") # Valid values: "Eligible", "Active"
      start_date_time = optional(string)
      expiration = optional(object({
        duration_days  = optional(number)
        duration_hours = optional(number)
        end_date_time  = optional(string)
      }))
      justification = optional(string)
      ticket_number = optional(string)
      ticket_system = optional(string)
    }))
  }))
}

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
      service_endpoints                             = optional(set(string))
      service_endpoint_policy_ids                   = optional(set(string))
      route_table_id                                = optional(string)
    }))
    peerings = optional(map(object({
      name                                   = string
      remote_virtual_network_id              = string
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

