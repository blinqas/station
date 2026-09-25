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

Set **exactly one** of `config.github` or `config.gitlab` in `lz.auto.tfvars`. The checked-in example selects GitHub. A GitLab bootstrap requires GitLab.com and an existing group; self-managed GitLab is not covered by this configuration.

---

## 1. Set Up Service Accounts

> [!NOTE]
> For GitHub, HCP Terraform binds a GitHub App to a user, not to an organization. Use a dedicated GitHub user for the App installation. For GitLab, the user that connects HCP Terraform needs Maintainer access to the landing-zone project so it can create webhooks.

For **GitHub**:

1. Create a dedicated GitHub user.
2. Invite the user to your organization.
3. Give the user administrator permissions in the organization.

Use this account for all GitHub App actions below.

For **GitLab**, use a dedicated GitLab user that can create private projects in the target group, commit to their default branches, and maintain the landing-zone project for HCP Terraform webhooks. Create its API token in step 3. The HCP Terraform VCS connection may use the same user.

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

Create the GitHub App for Station landing-zone management:

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

1. Confirm that the GitLab service user can create private projects in the target group or subgroup and commit to their default branches.
2. Create a personal access token with the `api` scope for that user. Set `GITLAB_TOKEN` for local bootstrap authentication. If the landing-zone workspace will also manage GitLab projects, set `TF_VAR_gitlab_token` instead; this installs the same token as a sensitive `GITLAB_TOKEN` variable in that workspace. The initial landing-zone repository contains no GitLab resources.
3. Note the full group path (for example, `platform/landing-zones`); use it for `gitlab.group`.

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

1. In HCP Terraform, open **Settings > Providers > Add VCS Provider**, then select **GitLab > GitLab.com**.
2. [Register the HCP Terraform application in GitLab](https://developer.hashicorp.com/terraform/cloud-docs/vcs/gitlab-com), using the redirect URI shown by HCP Terraform. Authorize it as a user with Maintainer access to the target projects. Select **All Projects** for the VCS provider: the HCP Terraform project does not exist until the first apply. You can narrow its scope after bootstrap.
3. Find the OAuth token ID (`ot-...`) associated with that VCS provider. You can retrieve it through the [HCP Terraform OAuth tokens API](https://developer.hashicorp.com/terraform/cloud-docs/api-docs/oauth-tokens). Set `terraform_cloud.vcs_repo_oauth_token_id` to this **ID**, not the GitLab access token or the OAuth client ID.

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
export GITLAB_TOKEN="your-gitlab-api-token"
```

Only if the landing-zone workspace must also manage GitLab projects, export the token as a Terraform variable too. This gives that workspace the same API token:

```bash
export TF_VAR_gitlab_token="$GITLAB_TOKEN"
```
```

### Configure the Variables

1. Fill in `lz.auto.tfvars`. Keep the `github` block from the example for GitHub, or replace that entire block with the `gitlab` block below. Do not set both.

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

### Run Terraform

1. Check that the Azure CLI is using the tenant and subscription specified in `lz.auto.tfvars`, then run these commands.

```bash
export TF_WORKSPACE=$(awk -F'"' '/bootstrap_workspace_name/ {print $2}' lz.auto.tfvars)
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
```

The generated bootstrap repository is a copy of the bootstrap configuration. Its `module "station"` source is `../.`, so a later run from a clone requires the Station repository checked out as its parent directory. Keep the selected VCS credentials available when running it. The generated landing-zone repository starts with only `providers.tf` and `variables.tf`; add landing-zone configuration before expecting it to deploy resources.

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
terraform plan -out plan.tfplan
terraform apply plan.tfplan
unset TF_CLOUD_ORGANIZATION
unset TF_WORKSPACE
```

### Optional: Tear Down the Deployment

> [!IMPORTANT]
> Only do this when you intend to delete the Station deployment, its workspaces, and both generated repositories. Do not run `terraform destroy` as routine post-bootstrap cleanup. The final destroy can fail to update state after state migration; check the remote state and remaining resources before treating it as complete.

1. Run these commands to destroy the deployment.

```bash
export TF_CLOUD_ORGANIZATION=$(awk -F'"' '/organization_name/ {print $2}' lz.auto.tfvars)
export TF_WORKSPACE=$(awk -F'"' '/bootstrap_workspace_name/ {print $2}' lz.auto.tfvars)
terraform destroy
```
2. Enter `yes` to destroy the environment
3. Continue

```bash
unset TF_CLOUD_ORGANIZATION
unset TF_WORKSPACE
rm -rf .terraform.tfstate.d .terraform 
```
