# Station Bootstrap - Permissions & Security

This document explains the least-privilege permission model used by the Station bootstrap process.

---

## Overview

The bootstrap process provisions a **Managed Identity** that will be used by HCP Terraform to deploy landing zones via the Station module. This identity requires specific permissions in both **Azure (RBAC)** and **Entra ID (Microsoft Graph)**.

By default, **no Entra ID directory roles are assigned**. The optional `enable_privileged_role_administrator` variable can be set to `true` if directory role assignments are required.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         PERMISSION ARCHITECTURE                              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────┐         ┌─────────────────┐         ┌────────────────┐  │
│  │  Human (Admin)  │         │ Station Identity│         │  Landing Zone  │  │
│  │  runs bootstrap │  ───▶   │ (Managed ID)    │  ───▶   │  Identities    │  │
│  │  ONE TIME       │         │ ONGOING         │         │  LIMITED       │  │
│  └─────────────────┘         └─────────────────┘         └────────────────┘  │
│         │                           │                           │            │
│         ▼                           ▼                           ▼            │
│  • Global Admin (to bootstrap)  • Graph API Perms          • Owned by        │ 
│  • Owner on subscription        • Owner on subscription      Station ID      │  
│                                 • (Optional) Priv Role     • Scoped perms    │
│                                   Admin if enabled                           │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Default Permissions (Least-Privilege)

### Azure RBAC

| Role | Scope | Purpose | Reference |
|------|-------|---------|-----------|
| **Owner** | Subscription | Create/manage Azure resources, assign RBAC roles | [Azure built-in roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner) |

### Microsoft Graph API Permissions (Application)

| Permission | Purpose | Reference |
|------------|---------|-----------|
| `Application.ReadWrite.OwnedBy` | Create and manage App Registrations where the identity is an owner | [Docs](https://learn.microsoft.com/en-us/graph/permissions-reference#applicationreadwriteownedby) |
| `Group.ReadWrite.All` | Create and manage Entra ID security groups | [Docs](https://learn.microsoft.com/en-us/graph/permissions-reference#groupreadwriteall) |
| `GroupMember.ReadWrite.All` | Add/remove members from groups | [Docs](https://learn.microsoft.com/en-us/graph/permissions-reference#groupmemberreadwriteall) |
| `User.Read.All` | Read user profiles (required for group member validation) | [Docs](https://learn.microsoft.com/en-us/graph/permissions-reference#userreadall) |
| `AppRoleAssignment.ReadWrite.All` | Grant API permissions to service principals | [Docs](https://learn.microsoft.com/en-us/graph/permissions-reference#approleassignmentreadwriteall) |

---

## Optional: Privileged Role Administrator

Set `enable_privileged_role_administrator = true` to grant the **Privileged Role Administrator** directory role.

### Why is this OFF by default?

From [Microsoft's documentation](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference#privileged-role-administrator):

> *"This role grants the ability to manage assignments for all Microsoft Entra roles including the Global Administrator role."*

**⚠️ This means privilege escalation is possible.** The Station identity could assign Global Administrator to any user, group, or service principal — including ones controlled by anyone with write access to the landing zone repository.

### When to enable it

Only set `enable_privileged_role_administrator = true` if:

1. Landing zones **genuinely require** Entra ID directory roles (e.g., `Directory Readers`, `Application Administrator`)
2. You have **strict repository access controls** in place
3. You understand and accept the **privilege escalation risk**

### Comparison

| Capability | Default (Graph API only) | With Privileged Role Admin |
|------------|--------------------------|----------------------------|
| Create Azure resources | ✅ | ✅ |
| Assign Azure RBAC roles | ✅ | ✅ |
| Create App Registrations (owned) | ✅ | ✅ |
| Create Security Groups (owned) | ✅ | ✅ |
| Grant Graph API permissions | ✅ | ✅ |
| Assign directory roles to LZs | ❌ | ✅ |
| Assign Global Administrator | ❌ | ✅ ⚠️ |

---

## Why Graph API Permissions Are Usually Sufficient

Most landing zone workloads don't need directory roles:

| Common Need | Directory Role Required? | Graph API Alternative |
|-------------|--------------------------|----------------------|
| Read users/groups | ❌ No | `User.Read.All`, `Group.Read.All` |
| Read directory objects | ❌ No | `Directory.Read.All` |
| Manage owned applications | ❌ No | `Application.ReadWrite.OwnedBy` |
| Create security groups | ❌ No | `Group.ReadWrite.All` |
| Assign Azure RBAC | ❌ No | Azure `Owner` role |

Directory roles are only needed for specialized scenarios like Conditional Access management or PIM.

---

## What the Station Identity CAN Do (Default)

✅ Create Azure resources (VMs, Storage, Networking, etc.)  
✅ Assign Azure RBAC roles to landing zone identities  
✅ Create Entra ID App Registrations (owned by Station)  
✅ Create Entra ID Security Groups (owned by Station)  
✅ Add members to groups it owns  
✅ Grant Microsoft Graph API permissions to service principals  

## What the Station Identity CANNOT Do (Default)

❌ Assign Entra ID directory roles to landing zones  
❌ Modify applications/groups it doesn't own  
❌ Grant tenant-wide admin consent  
❌ Create or update users  
❌ Manage Conditional Access policies  

---

## Security Recommendations

### Repository Access Control

The repository that triggers Terraform runs must be secured:

1. **Restrict access** - Only authorized personnel should have access
2. **Require PR reviews** - No direct pushes to main branch
3. **Enable branch protection** - Require status checks and approvals
4. **Enforce MFA** - All users must use multi-factor authentication
5. **Audit logs** - Enable and monitor GitHub audit logs

### Reducing Permissions Further

If you don't need certain capabilities, modify the `app_role_assignments` in `main.tf`:

| If you don't need... | Remove... |
|----------------------|-----------|
| Creating Entra ID groups | `Group.ReadWrite.All`, `GroupMember.ReadWrite.All` |
| Creating App Registrations | `Application.ReadWrite.OwnedBy` |
| Granting API permissions | `AppRoleAssignment.ReadWrite.All` |

---

## References

- [Microsoft Graph permissions reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Entra ID built-in roles](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference)
- [Privileged Role Administrator](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference#privileged-role-administrator)
- [Azure built-in roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
- [Least privilege best practices](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/best-practices#1-apply-principle-of-least-privilege)
- [Workload identity federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)
