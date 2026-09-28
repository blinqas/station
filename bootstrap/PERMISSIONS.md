# Station bootstrap permissions

Bootstrap assigns permissions to the **Station managed identity** used by the landing-zone HCP Terraform workspace. Set the root-level `station_capabilities` input in the bootstrap configuration to select its Microsoft Graph **application permissions**. Each activity defaults to `false`; leaving the object unset selects no optional activities. These switches grant permissions to the identity; they do not create or disable Station resources.

The identity always receives **Application.Read.All** because the Station module unconditionally reads the Microsoft Graph service principal (`data.azuread_service_principal.msgraph`). The pinned AzureAD provider requires this application permission (or `Directory.Read.All`) for an app-only lookup. Thus, all switches set to `false` does **not** mean zero Graph access. Bootstrap also assigns **Azure subscription Owner** for Azure resources and Azure RBAC; Graph activities do not change that assignment.

| Activity (`station_capabilities` key) | Graph application permission(s) | What it enables and its scope |
| --- | --- | --- |
| Always (no switch) | `Application.Read.All` | Read applications and service principals tenant-wide; required by the Station module's Graph lookup. |
| `manage_applications` | `Application.ReadWrite.All` | Create and manage application registrations and their service principals tenant-wide. See ownership constraint below. |
| `manage_groups` | `Group.ReadWrite.All` | Create and manage ordinary groups, their properties, and membership tenant-wide. |
| `manage_group_membership` | `Group.ReadWrite.All` | Add/remove members of **any ordinary group**, including pre-existing groups the identity does not own. Also grants group property and membership management tenant-wide; this is the same permission as `manage_groups`. |
| `grant_application_permissions` | `AppRoleAssignment.ReadWrite.All` | Assign application roles (including Graph API permissions) to service principals tenant-wide. `Application.Read.All` above supplies the other permission required by the provider. |
| `assign_directory_roles` | `RoleManagement.ReadWrite.Directory` | Assign Entra directory roles using the AzureAD provider, including privileged roles. Also required to create role-assignable groups or edit their membership. |

Permissions are deduplicated: turning on both group switches results in **one** `Group.ReadWrite.All` assignment. Graph permissions are tenant-wide, not restricted to the bootstrap resource group, Azure subscription, Station-created objects, or the repository. Restrict who can change and run the landing-zone configuration accordingly.

## Configure activities

At the **top level** of `lz.auto.tfvars`, alongside `config` (not inside it), add only the activities you need:

```hcl
station_capabilities = {
  manage_applications           = false
  manage_groups                 = false
  manage_group_membership       = true
  grant_application_permissions = false
  assign_directory_roles        = false
}
```

You may omit any key; it defaults to `false`. For example, `station_capabilities = {}` grants only the baseline Graph permission. If Station will manage applications with service principals, create groups, and grant those applications API permissions, enable `manage_applications`, `manage_groups`, and `grant_application_permissions` explicitly. The role-assignment switch is **opt-in on the ordinary Station identity**, not a separate privileged workflow. It permits grants to the identity itself and other principals, including powerful tenant-wide roles; treat access to its Terraform configuration as privileged.

### Provider and Graph limitations

- **Applications:** Station adds the landing-zone identity as an owner of applications it creates, but its service-principal resource does not set service-principal owners. [AzureAD v3.9.0 requires ownership of *both* objects](https://github.com/hashicorp/terraform-provider-azuread/blob/v3.9.0/docs/resources/service_principal.md#api-permissions) for `Application.ReadWrite.OwnedBy`. Consequently `manage_applications` uses the broader `Application.ReadWrite.All` to support the existing application + service-principal lifecycle. If specifying user principals as application owners, [the provider may additionally need `User.Read.All`](https://github.com/hashicorp/terraform-provider-azuread/blob/v3.9.0/docs/resources/application.md#api-permissions); this switch does not add it.
- **Groups:** [AzureAD v3.9.0 `azuread_group_member`](https://github.com/hashicorp/terraform-provider-azuread/blob/v3.9.0/docs/resources/group_member.md#api-permissions) requires `Group.ReadWrite.All` or `Directory.ReadWrite.All` for app-only access to a group it does not own. `GroupMember.ReadWrite.All` alone is not documented as sufficient for that provider resource, so the membership activity uses `Group.ReadWrite.All`. If specifying **user owners** on a group, [the group resource additionally requires `User.Read.All` or an equivalent directory permission](https://github.com/hashicorp/terraform-provider-azuread/blob/v3.9.0/docs/resources/group.md#api-permissions); it is not granted automatically. Default Station-managed groups add the identity as an owner.
- **Member types:** The provider supports user, group, and service-principal members. Ordinary user and supported group membership uses the group permission above. [Microsoft Graph's add-member API](https://learn.microsoft.com/en-us/graph/api/group-post-members?view=graph-rest-1.0#permissions) also requires `Application.ReadWrite.All` to add a **service principal** as a member (enable `manage_applications` only if this is needed). Role-assignable group membership additionally requires `RoleManagement.ReadWrite.Directory` (enable `assign_directory_roles`). Dynamic group membership is rule-driven and cannot be manually edited. Graph also limits which member types can join security versus Microsoft 365 groups; the switches cannot bypass these limits.
- **Automatic grants by the Station module:** When the landing-zone configuration specifies `groups` or `applications`, the unchanged Station module unconditionally grants its identity additional Graph app roles (`User.ReadBasic.All` and `Group.Read.All` for groups; `Application.ReadWrite.OwnedBy` for applications). Those assignments require `grant_application_permissions = true` on the Station identity for the run to succeed. When an application has a service principal and `required_resource_access`, `auto_admin_consent` also defaults to `true` and creates additional app-role assignments; setting it to `false` suppresses these extra assignments, **not** the automatic group/application grants. A false capability switch does not disable these resources: the future run may fail for lack of permission. Consult the module configuration before reducing grants.

## Entra directory role: a separate option

`enable_privileged_role_administrator = true` assigns the **Privileged Role Administrator Entra directory role** to the Station identity. It defaults to `false` and remains independent of the `assign_directory_roles` **Microsoft Graph application permission**. Neither setting enables the other. With app-only AzureAD provider authentication, [the directory-role assignment resource](https://github.com/hashicorp/terraform-provider-azuread/blob/v3.9.0/docs/resources/directory_role_assignment.md#api-permissions) requires `RoleManagement.ReadWrite.Directory` (or `Directory.ReadWrite.All`); the directory role alone is not a substitute. Both the Graph permission and the PRA role can permit assignment of very powerful roles, including Global Administrator. Review each separately.

## Migration from the previous bootstrap defaults

The previous bootstrap granted five Graph permissions by default: `Application.ReadWrite.OwnedBy`, `Group.ReadWrite.All`, `GroupMember.ReadWrite.All`, `User.Read.All`, and `AppRoleAssignment.ReadWrite.All`. With no optional activities selected, Terraform will **plan revocations** of all five and add `Application.Read.All`. Selecting a switch keeps the address of any retained permission keyed by its Graph name; the other assignments are removed. `Application.ReadWrite.All` replaces `Application.ReadWrite.OwnedBy` for application management. Review the plan and the landing-zone configuration's required operations **before applying** this migration; removing an active permission can break later runs. This configuration does not change the subscription Owner assignment.

## References

- [Microsoft Graph permissions reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [AzureAD provider v3.9.0 API permission documentation](https://github.com/hashicorp/terraform-provider-azuread/tree/v3.9.0/docs)
- [Entra built-in directory roles](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference)
