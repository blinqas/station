# Design Decision: Auto-Approving Application Roles in `required_resource_access`

**Date:** March 2, 2025  
**Author:** Sander Blomvågnes  

## Context  

Previously, when using `var.applications.app_name.required_resource_access`, only the `resource_app_id` needed to be provided. However, roles were not automatically assigned, requiring a Global Admin to manually grant the necessary permissions in Entra ID after deployment.  

To enable automatic assignment of permissions, we now require the following details:  

- The **role ID** (e.g., `User.Read.All`)  
- The **client ID** of the service principal where permissions should be assigned (e.g., Microsoft Graph)  
- The **object ID** of the service principal where permissions should be assigned. This ID is generated when creating the tenant and differs across tenants, unlike the client ID and role ID.  

## Reasoning  

- The same person who approves the pull request to create the application is often the one who manually grants permissions in Entra ID. Automating this process avoids redundant approval steps.  
- Reducing the number of resources created in the module helps lower Terraform Cloud (TFC) costs and improves Terraform plan execution time.  
- Instead of mimicking the `required_resource_access` block definition from the `azuread` provider, we now require users to provide **both** `client_id` and `object_id`. This avoids using a data source to look up missing values, streamlining the module implementation.  

## Implementation  

With this approach, resource definitions can be centralized in the deployment repository, passing values to the module rather than creating a new resource each time the module is used.  

### Example  

```hcl
data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "MicrosoftGraph" {
  client_id    = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing = true
}

resource "azuread_service_principal" "Office365ExchangeOnline" {
  client_id    = data.azuread_application_published_app_ids.well_known.result.Office365ExchangeOnline
  use_existing = true
}

module "example" {
  applications = {
    example_app = {
      display_name = "Example app"

      required_resource_access = {
        graph = {
          resource_app_id    = azuread_service_principal.MicrosoftGraph.client_id
          resource_object_id = azuread_service_principal.MicrosoftGraph.object_id
          resource_access = {
            application_group_read_all = {
              # This will NOT require admin consent after deployment
              id   = "5b567255-7703-4780-807c-7be8301ae99b"
              type = "Role"
            }
          }
        }

        exchange_online = {
          admin_consent     = true
          resource_app_id   = azuread_service_principal.Office365ExchangeOnline.client_id
          resource_object_id = azuread_service_principal.Office365ExchangeOnline.object_id
          resource_access = {
            delegated_ews_accessasuser_all = {
              id   = "3b5f3d61-589b-4a3c-a359-5dd4b5ee5bd5"
              type = "Scope"
            }

            application_ews_accessasuser_all = {
              # This will require admin consent after deployment
              id   = "dc890d15-9560-4a4c-9b7f-a736ec74ec40"
              type = "Role"
            }
          }
        }
      }
    }
  }
}


``` 

#### Known Limitations or drawbacks
- The `var.application` block now differs more from the `azuread_application` resource, which may require additional documentation or user education.

#### Summary  
This change enables automatic assignment of application roles to the service principal, eliminating the need for manual consent in Entra ID after deployment. This improves efficiency, reduces redundant approvals, and optimizes resource usage in the module