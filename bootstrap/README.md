# Station Bootstrap

This directory holds the bootstrap process for **Station**. Station is a Terraform module that creates secure, automated landing zones in Azure. The landing zones are ready for infrastructure deployment.

---

## Who This Guide Is For

This guide is for DevOps engineers and platform engineers who deploy Azure infrastructure with GitHub and HCP Terraform. The bootstrap creates a complete CI/CD flow with GitHub Apps, HCP Terraform, and OIDC-based identity.

---

## Prerequisites

- A GitHub account: user, organization, or enterprise.
- An HCP Terraform account.
- The Terraform CLI.

---

## Overview

The bootstrap does these tasks:

1. Creates two GitHub Apps. The first app connects HCP Terraform to GitHub. The second app lets Terraform manage GitHub with the `integrations/github` provider.
2. Creates service accounts. HCP Terraform binds a GitHub App to a user, not to an organization. The bootstrap uses service accounts for this reason.
3. Links the GitHub organization to HCP Terraform.
4. Runs the first Terraform apply. The apply creates the Station landing zones and moves the state to HCP Terraform.

---

## 1. Create the GitHub Service Account

> [!NOTE]
> HCP Terraform binds a GitHub App to a user, not to an organization. This service account works around that limit.

1. Create a new GitHub user.
2. Invite the user to your organization.
3. Give the user administrator permissions in the organization.

Use this account for all GitHub App actions in this guide.

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

## 3. Create the GitHub App for Station Landing Zone Management

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

---

## 4. Create the GitHub App for the HCP Terraform VCS Link

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

---

## 5. Run the Bootstrap

### Set the Environment Variables

1. Run the commands for your shell.

```bash
export TF_VAR_github_app_pem_file=$(base64 -i ./station-landing-zones.pem)
export TF_VAR_tfe_token="your-tfc-token"
export TFE_TOKEN="$TF_VAR_tfe_token"
export TF_TOKEN="$TF_VAR_tfe_token"
```

### Configure the Variables

1. Fill in the configuration file `lz.auto.tfvars`:

```hcl
# hints
vcs_repo_github_app_installation_id = "<string>" # Installation ID from step 4.3 (ghain-xxxxxx...)
github.provider.id                  = "<string>" # App ID from step 3
github.provider.installation_id     = "<string>" # Installation ID from step 3
```

### Run Terraform

1. Run these commands.

```bash
export TF_WORKSPACE=$(awk -F'"' '/bootstrap_workspace_name/ {print $2}' lz.auto.tfvars)
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
```

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

```bash
terraform plan -out plan.tfplan
terraform apply plan.tfplan
unset TF_CLOUD_ORGANIZATION
unset TF_WORKSPACE
```

### Clean Up

> [!IMPORTANT]
> The final `terraform destroy` command fails to update the state. The state already moved to HCP Terraform. This error is expected. Ignore it.

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
