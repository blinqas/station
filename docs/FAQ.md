## FAQ

<details>
  <summary>How do I add app roles to an application?</summary>


To add **app roles** to an application, you need to create an application using the **Station module** with the `applications` block.
This block allows you to define most of the same options as the [`azuread_application`](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) resource. 

However, **`app_role` is not implemented** in this module. Instead, you can define app roles separately using the `azuread_application_app_role` resource.

Since the **landing zone identity** has the `Application.ReadWrite.OwnedBy` role, we can create **app roles** in the landing zone’s Terraform configuration.

```hcl
resource "azuread_application_app_role" "admin" {
  application_id       = "/applications/${var.applications["app_name"].object_id}"
  role_id              = random_uuid.admin_role.id
  allowed_member_types = ["User"]
  description          = "This role grants access to everything in the application. Should be assigned to CCB Admins and Developers."
  display_name         = "Admin"
  value                = "ADMIN"
}
```
</details>


### Azure permsissions
<details>
  <summary>How do I assign roles to a system assigned identity that is out of the resource scope of the landing zone</summary>

Lets image that you want to deploy a resource that only supports **system assigned identity**. This resource would need access to backup and restore any Storage account in the subscription. The system assigned identity would then need a role like `Storage Account Backup Contributor`. As the landing zone identity only have `Owner` permssion on it's resource group/s it does not have the permission to assign the system assigned identiy the required role on a wide scope. 

To work aroun this we can in the deployment repositoiry create an EntraID securty group, assign the RBAC role with a subscription wide scope and pass this group to the landing zone.


1. Create the group in the deployment repository 
    ```hcl
    module "backup" {
    resource_group_name = "backup"
    ....

    groups = {
        storage_account_backup_contributor = {
        display_name     = "Azure - Storage Account Backup Contributors"
        description      = "Group membership lets you perform backup and restore operations on any storage account in the subscription."
        security_enabled = true
        role_assignments = {
            storage_account_backup_contributor = {
            scope                = data.azurerm_subscription.current.id
            role_definition_name = "Storage Account Backup Contributor"
            }
        }
        }
    }
    



2. In the landing zone repositoty we can create the required resource, enable system assigned identity and add it as a member of the group giving the resource the correct permissions.

    ```hcl
        resource "azurerm_data_protection_backup_vault" "storage_accounts" {
        name                       = "bvault-storage-accounts"
        resource_group_name        = data.azurerm_resource_group.workload.name
        location                   = data.azurerm_resource_group.workload.location
        datastore_type             = "VaultStore"
        redundancy                 = "LocallyRedundant"
        retention_duration_in_days = 90
        tags                       = var.tags

        identity {
            type = "SystemAssigned"
        }
        }


    resource "azuread_group_member" "sa_backup_operator" {
    group_object_id  = var.groups.storage_account_backup_contributor.object_id
    member_object_id = azurerm_data_protection_backup_vault.storage_accounts.identity[0].principal_id
    }
    ```
</details>

