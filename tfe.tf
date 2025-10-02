module "station-tfe" {
  source = "./hashicorp/tfe/"

  organization_name     = var.tfe.organization_name
  project               = var.tfe.project
  workspace_name        = var.tfe.workspace_name
  workspace_description = var.tfe.workspace_description
  workspace_settings    = try(var.tfe.workspace_settings, null)
  vcs_repo              = try(var.tfe.vcs_repo, null)
  file_triggers_enabled = try(var.tfe.vcs_repo.tags_regex, null) == null ? true : false # if tags_regex is supplied, set to false, this removes an uneccessary step
  workspace_vars = merge(try(var.tfe.workspace_vars, {}), {
    # Terraform variables are prefixed with TF_VAR_ to suppress TFC Runner warning of unused variables.
    station_id = {
      value       = random_id.workload.hex
      category    = "terraform"
      description = "Station ID"
      hcl         = false
      sensitive   = false
    },
    workload_resource_group_name = {
      value       = azurerm_resource_group.workload.name
      category    = "terraform"
      description = "Name of the resource group created by Station"
      hcl         = false
      sensitive   = false
    },
    tags = {
      value       = replace(jsonencode(local.tags), "/(\".*?\"):/", "$1 = ")
      category    = "terraform"
      description = "Default tags from Station Deployment"
      hcl         = true
      sensitive   = false
      }, TFC_AZURE_PROVIDER_AUTH = {
      value       = true
      category    = "env"
      description = "Is true when using dynamic credentials to authenticate to Azure. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-terraform-cloud"
      sensitive   = false
    },
    TFC_AZURE_RUN_CLIENT_ID = {
      value       = module.user_assigned_identity.client_id
      category    = "env"
      description = "The client ID for the Service Principal / Application used when authenticating to Azure. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-terraform-cloud"
      sensitive   = false
    },
    ARM_SUBSCRIPTION_ID = {
      value       = var.subscription_id
      category    = "env"
      description = "The Subscription ID to connect to. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-the-azurerm-or-azuread-provider"
      sensitive   = false
    },
    ARM_TENANT_ID = {
      value       = var.tenant_id
      category    = "env"
      description = "The Azure Tenant ID to connect to. https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration#configure-the-azurerm-or-azuread-provider"
      sensitive   = false
    }
    },
    try(length(module.ad_groups) > 0) ? {
      groups = {
        value = replace(jsonencode({ for k, v in module.ad_groups : k => {
          display_name = v.group.display_name
          object_id    = v.group.object_id
        } }), "/(\".*?\"):/", "$1 = ") # Credit: https://brendanthompson.com/til/2021/03/hcl-enabled-tfe-variables
        category    = "terraform"
        description = "Groups provisioned by Station"
        hcl         = true
        sensitive   = false
      }
    } : {},
    try(length(module.applications) > 0) ? {
      applications = {
        value = replace(jsonencode({ for k, v in module.applications : k => {
          id           = v.application.id
          display_name = v.application.display_name
          client_id    = v.application.client_id
          application_id = "/applications/${v.application.client_id}"
          object_id    = v.application.object_id
        } }), "/(\".*?\"):/", "$1 = ") # Credit: https://brendanthompson.com/til/2021/03/hcl-enabled-tfe-variables
        category    = "terraform"
        description = "User Assigned Identities provisioned by Station"
        hcl         = true
        sensitive   = false
      }
    } : {},
    try(length(module.user_assigned_identities) > 0) ? {
      user_assigned_identities = {
        value = replace(jsonencode({ for k, v in module.user_assigned_identities : k => {
          id           = v.id
          client_id    = v.client_id
          principal_id = v.principal_id
        } }), "/(\".*?\"):/", "$1 = ") # Credit: https://brendanthompson.com/til/2021/03/hcl-enabled-tfe-variables
        category    = "terraform"
        description = "Applications provisioned by Station"
        hcl         = true
        sensitive   = false
      }
    } : {},
    try(length(azurerm_resource_group.user_specified) > 0) ? {
      resource_groups = {
        value = replace(jsonencode({ for key, v in azurerm_resource_group.user_specified : key => {
          name     = v.name
          location = v.location
        } }), "/(\".*?\"):/", "$1 = ") # Credit: https://brendanthompson.com/til/2021/03/hcl-enabled-tfe-variables
        category    = "terraform"
        description = "User specified resource groups provisioned by Station"
        hcl         = true
        sensitive   = false
      }
    } : {},
    try(length(azurerm_virtual_network.this) > 0) ? {
      virtual_networks = {
        value       = replace(jsonencode(azurerm_virtual_network.this), "/(\".*?\"):/", "$1 = ") # Credit: https://brendanthompson.com/til/2021/03/hcl-enabled-tfe-variables
        category    = "terraform"
        description = "Virtual Network(s) provisioned with Station"
        hcl         = true
        sensitive   = false
      }
    } : {},
    try(length(azurerm_subnet.this) > 0) ? {
      subnets = {
        value       = replace(jsonencode(azurerm_subnet.this), "/(\".*?\"):/", "$1 = ") # Credit: https://brendanthompson.com/til/2021/03/hcl-enabled-tfe-variables
        category    = "terraform"
        description = "Subnet(s) provisioned with Station"
        hcl         = true
        sensitive   = false
      }
    } : {},
    try(length(azurerm_network_security_group.this) > 0) ? {
      network_security_groups = {
        value       = replace(jsonencode(azurerm_network_security_group.this), "/(\".*?\"):/", "$1 = ") # Credit: https://brendanthompson.com/til/2021/03/hcl-enabled-tfe-variables
        category    = "terraform"
        description = "NSG(s) provisioned with Station"
        hcl         = true
        sensitive   = false
      }
    } : {}
  )
}


