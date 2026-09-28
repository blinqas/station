# Station Bootstrap

This directory holds the bootstrap process for **Station**. Station is a Terraform module that creates landing zones in Azure. Choose either GitHub or GitLab.com for the bootstrap repositories and the HCP Terraform VCS connection. Add your landing-zone Terraform configuration to the generated repository after bootstrap.

---

## Who This Guide Is For

This guide is for DevOps engineers and platform engineers who deploy Azure infrastructure with GitHub or GitLab.com and HCP Terraform. The bootstrap creates two private repositories, connects the landing-zone repository to HCP Terraform, and provisions OIDC-based identity.

---

## Prerequisites

- A GitHub organization or a GitLab.com group (including a subgroup).
- An HCP Terraform account.
- The Terraform CLI.
- The Azure CLI, signed in to the tenant and subscription selected in `lz.auto.tfvars`. The bootstrap operator needs permission to create and assign Azure resources and the Microsoft Graph app roles listed in [PERMISSIONS.md](PERMISSIONS.md). Confirm these permissions before the first apply.

---

## Overview

The bootstrap does these tasks:

1. Uses a preconfigured GitHub App or GitLab token to create private bootstrap and landing-zone repositories and seed their configuration.
2. Connects the landing-zone repository to HCP Terraform using the selected VCS connection.
3. Runs the first Terraform apply locally, then migrates the bootstrap state to HCP Terraform on the second initialization.

Set **exactly one** of `config.github` or `config.gitlab` in `lz.auto.tfvars`. The checked-in example selects GitLab. A GitLab bootstrap requires GitLab.com and an existing group; self-managed GitLab is not covered by this configuration.

---

## 1. Set Up Service Accounts

> [!NOTE]
> For GitHub, HCP Terraform binds a GitHub App to a user, not an organization. Use a dedicated GitHub user for the installation.
> GitLab service accounts cannot sign in through the GitLab UI. Connect HCP Terraform through its API in step 4.

For **GitHub**:

1. Create a dedicated GitHub user.
2. Invite the user to your organization.
3. Give the user administrator permissions in the organization.

Use this account for all GitHub App actions below.

For **GitLab**:

1. As an Owner of the top-level group, create a [group service account](https://docs.gitlab.com/user/profile/service_accounts/).
2. Open the target group or subgroup in GitLab, then select **Manage > Members > Invite members**.
3. Enter the service account's username, select the **Maintainer** role, and select **Invite**. This role is inherited by new projects and lets HCP Terraform create webhooks.
4. In the target group, select **Settings > General > Permissions and group features**. Check that **Minimum role required to create projects** is **Maintainer** or lower. If it is higher, set it to **Maintainer** and select **Save changes**.
5. Check that the group's default branch protection lets Maintainers push. GitLab's default **Fully protected** setting does.

---

## 2. Create the HCP Terraform Service Account

[Background](https://github.com/hashicorp/terraform-provider-tfe/issues/853#issuecomment-1545808240)

1. Create a dedicated HCP Terraform user.
2. Add the user to the `owners` team.
3. Create a User API Token. [Link](https://app.terraform.io/app/settings/tokens)
   - Description: `Station Landing Zones`
   - Expiration: Shorter is better and requires rotation.
4. Store the token in a safe location.

---

## 3. Configure Repository Management

### GitHub

Terraform uses this app to manage GitHub with the `integrations/github` provider.

1. Create a new GitHub App at `https://github.com/organizations/<your-org>/settings/apps/new`.

   Use these settings:
   - Name: `Station LZ (Org Name)`
   - Description: GitHub App for Terraform-based organization and repository management with Station
   - Homepage: `<your org’s website>`
   - **Webhook: Disabled**
   - **Repository permissions:**
     - Administration: Read and write
     - Contents: Read and write

2. Create a private key. Save the key as `station-landing-zones.pem` in the bootstrap directory.
3. Take a note of the App ID, this is used later as the `github.provider.id` value.
4. Install the app in your GitHub organization.
5. Take a note of the Installation ID (numbers in the URL), this is used later as the `github.provider.installation_id`

### GitLab.com

Create a personal access token for the group service account with the `api` scope.

1. Go to `Group > Settings > Service accounts`
2. On the Service Account, click `⋮ > Manage access tokens > Add new token`
3. 
4. Set `TF_VAR_gitlab_token` to this token before bootstrap (see step 5). Station also installs it as a sensitive `GITLAB_TOKEN` variable in the landing-zone workspace.
5. Note the full group path (for example, `platform/landing-zones`); use it for `gitlab.group`.

---

## 4. Connect HCP Terraform to the Selected VCS

### GitHub

Create the GitHub App for the HCP Terraform VCS link:

HCP Terraform uses this app to watch GitHub commits and start runs.

> [!CAUTION]
> Do this step as the GitHub service account from step 1. Authenticate to HCP Terraform as the HCP Terraform service account from step 2.

1. In HCP Terraform, go to **Settings > VCS Providers > Add VCS Provider**. [Link](https://app.terraform.io/app/<Terraform Cloud Organization>/settings/version-control/add)
2. Follow the flow to register the GitHub App.
> [!CAUTION]
> If GitHub App is `Installed` (even if it is not), go to step 2.1.

**Steps only required when Add VCS Provider page says GitHub App is already installed**
2.1. Go to Workspaces > Create new in Default project > Create
2.2. Select `Version control workflow`
2.3. Click GitHub > Github.com which triggers the App Installation process
2.4. Install in your Github Organization
2.4. Exit the Create workspace page and continue to step 3

3. Copy the GitHub App installation ID at the bottom of the **Settings > Tokens** page: https://app.terraform.io/app/settings/tokens. The ID looks like `ghain-xxxxxxxxxxxx`.

### GitLab.com

1. Export the HCP Terraform token and the GitLab service account token as shown in step 5.
2. Create the GitLab.com VCS connection using the [HCP Terraform OAuth Clients API](https://developer.hashicorp.com/terraform/cloud-docs/api-docs/oauth-clients#create-an-oauth-client). Replace `<organization>` with your HCP Terraform organization name:

```bash
curl --request POST "https://app.terraform.io/api/v2/organizations/<organization>/oauth-clients" \
  --header "Authorization: Bearer $TF_VAR_tfe_token" \
  --header "Content-Type: application/vnd.api+json" \
  --data @- <<EOF
{"data":{"type":"oauth-clients","attributes":{"service-provider":"gitlab_hosted","http-url":"https://gitlab.com","api-url":"https://gitlab.com/api/v4","oauth-token-string":"$TF_VAR_gitlab_token"}}}
EOF
```

3. Copy the OAuth client ID (`oc-...`) from the response.
4. List its token IDs using the [HCP Terraform OAuth tokens API](https://developer.hashicorp.com/terraform/cloud-docs/api-docs/oauth-tokens). Replace `<client-id>` with the ID from step 3:

```bash
curl "https://app.terraform.io/api/v2/oauth-clients/<client-id>/oauth-tokens" \
  --header "Authorization: Bearer $TF_VAR_tfe_token"
```

5. Set `terraform_cloud.vcs_repo_oauth_token_id` to the returned `ot-...` ID. Do not use the `oc-...` ID or the GitLab token here.

> [!NOTE]
> Leave this VCS connection available to **All Projects** for bootstrap. You can limit it to selected projects after the first apply creates the HCP Terraform project.

---

## 5. Run the Bootstrap

### Set the Environment Variables

1. Set the HCP Terraform token and the credentials for **your selected VCS**:

```bash
export TF_VAR_tfe_token="your-tfc-token"
export TFE_TOKEN="$TF_VAR_tfe_token"
export TF_TOKEN="$TF_VAR_tfe_token"

# GitHub only:
export TF_VAR_github_app_pem_file=$(base64 -i ./station-landing-zones.pem)

# GitLab only (do not export the GitHub PEM for GitLab):
export TF_VAR_gitlab_token="your-gitlab-api-token"
```

### Configure the Variables

1. Fill in `lz.auto.tfvars`. Keep the `github` block from the example for GitHub, or replace that entire block with the `gitlab` block below. Do not set both.
2. If you have other `*.auto.tfvars` files in this directory, Terraform loads them too. The commands below give `lz.auto.tfvars` precedence for values present in both files.

```hcl
# Inside config.terraform_cloud, for GitHub:
vcs_repo_github_app_installation_id = "ghain-..." # Step 4, GitHub

# Inside config.github.provider:
id              = "..." # GitHub App ID from step 3
installation_id = "..." # GitHub App installation ID from step 3
```

For GitLab, remove `vcs_repo_github_app_installation_id` from `config.terraform_cloud` and set `vcs_repo_oauth_token_id = "ot-..."` instead. Replace `config.github` with:

```hcl
gitlab = {
  group                 = "platform/landing-zones"
  repository            = "alz"
  description           = "Terraform Configuration for Landing Zones"
  branch                = "main"
  bootstrap_repository  = "alz-bootstrap"
  bootstrap_description = "Terraform Configuration for Bootstrap of Azure Landing Zones"
  bootstrap_branch      = "main"
}
```

### Select Station identity activities

At the top level of `lz.auto.tfvars`, **outside** `config`, select the activities the landing-zone Station identity needs:

```hcl
station_capabilities = {
  manage_applications           = false
  manage_groups                 = false
  manage_group_membership       = true
  grant_application_permissions = false
  assign_directory_roles        = false
}
```

All keys are optional and default to `false`. The identity still receives the baseline `Application.Read.All` Graph permission for the Station module's service-principal lookup and Azure subscription Owner for Azure resources. These switches grant Graph permissions; they do not control which resources the Station module creates. `manage_groups` and `manage_group_membership` both grant tenant-wide `Group.ReadWrite.All`, so use either switch only when that scope is acceptable. `grant_application_permissions` opts the ordinary identity into tenant-wide app-role assignments, including grants to itself. `manage_applications` grants tenant-wide `Application.ReadWrite.All` because the existing module does not set owners on its service principals. `assign_directory_roles` grants tenant-wide `RoleManagement.ReadWrite.Directory` and is separate from `enable_privileged_role_administrator` (an Entra directory role). See [PERMISSIONS.md](PERMISSIONS.md) for the activity-to-permission table, member-type limits, and application auto-consent prerequisites. On upgrades, review the plan: the prior five default Graph grants are subject to revocation.

| Activity | Graph application permission |
| --- | --- |
| Always (including all switches off) | `Application.Read.All` |
| `manage_applications` | `Application.ReadWrite.All` |
| `manage_groups` | `Group.ReadWrite.All` |
| `manage_group_membership` | `Group.ReadWrite.All` (also permits group property changes) |
| `grant_application_permissions` | `AppRoleAssignment.ReadWrite.All` |
| `assign_directory_roles` | `RoleManagement.ReadWrite.Directory` |

### Run Terraform

1. Check that the Azure CLI is using the tenant and subscription specified in `lz.auto.tfvars`, then run these commands.

```bash
export TF_WORKSPACE=$(awk -F'"' '/bootstrap_workspace_name/ {print $2}' lz.auto.tfvars)
terraform init
terraform plan -var-file=lz.auto.tfvars -out plan.tfplan
terraform apply plan.tfplan
```

The generated bootstrap repository is a copy of the bootstrap configuration. Its `module "station"` source is `../.`, so a later run from a clone requires the Station repository checked out as its parent directory. Keep the selected VCS credentials available when running it. The generated landing-zone repository starts with `providers.tf`, the shared `variables.tf`, and either `variables.github.tf` or `variables.gitlab.tf` (plus `variables.bootstrap.tf` for GitLab); add landing-zone configuration before expecting it to deploy resources.

### Move the State to HCP Terraform


Log into Terraform Cloud using CLI before continuing:

1. `terraform login`
2. Enter `yes`
3. Close the browser window, and enter the Station Landing Zones User API Token from step 2.
4. Continue

```bash
export TF_CLOUD_ORGANIZATION=$(awk -F'"' '/organization_name/ {print $2}' lz.auto.tfvars)
export TF_WORKSPACE=$(awk -F'"' '/bootstrap_workspace_name/ {print $2}' lz.auto.tfvars)
terraform init
```

5. Enter `yes` to migrate state.

Keep the same VCS credentials exported for the second plan and apply. The bootstrap workspace uses local execution, so the CLI continues to use your local GitHub or GitLab authentication.

```bash
terraform plan -var-file=lz.auto.tfvars -out plan.tfplan
terraform apply plan.tfplan
unset TF_CLOUD_ORGANIZATION
unset TF_WORKSPACE
```

### Use the Landing-Zone Workspace Inputs

1. Run the bootstrap plan and apply again after updating this configuration. It adds the five Terraform variables to the landing-zone workspace and a bootstrap-managed `variables.bootstrap.tf` to the GitLab landing-zone repository.
2. In HCP Terraform, open the landing-zone workspace's **Variables** page. Check for `vcs_repo_oauth_token_id`, `tfe_organization_name`, `tenant_id`, `gitlab_group`, and `subscription_id`.
3. In the landing-zone repository's `main.tf`, refer to these values as `var.vcs_repo_oauth_token_id`, `var.tfe_organization_name`, `var.tenant_id`, `var.gitlab_group`, and `var.subscription_id`.

### Optional: Tear Down the Deployment

> [!IMPORTANT]
> Only do this when you intend to delete the Station deployment, its workspaces, and both generated repositories. Do not run `terraform destroy` as routine post-bootstrap cleanup. The final destroy can fail to update state after state migration; check the remote state and remaining resources before treating it as complete.

1. Run these commands to destroy the deployment.

```bash
export TF_CLOUD_ORGANIZATION=$(awk -F'"' '/organization_name/ {print $2}' lz.auto.tfvars)
export TF_WORKSPACE=$(awk -F'"' '/bootstrap_workspace_name/ {print $2}' lz.auto.tfvars)
terraform destroy -var-file=lz.auto.tfvars
```
2. Enter `yes` to destroy the environment
3. Continue

```bash
unset TF_CLOUD_ORGANIZATION
unset TF_WORKSPACE
rm -rf .terraform.tfstate.d .terraform 
```
