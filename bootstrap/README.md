# Station bootstrapping

This folder contains Terraform files to bootstrap Azure and Terraform Cloud for Station.

## What does it do?

1. Create a service principal in Azure AD
2. Assigns it Global Administrator on the logged in Azure AD tenant
3. Assigns it Owner on the logged in subscription
4. Create two Federated Identity Credential configurations for OIDC between the Terraform Cloud Workspace it provisions for Station Deployments.
5. Creates a Terraform Cloud Project in the logged in Terraform Cloud Organization
6. Creates a Terraform Cloud Workspace for the bootstrap state
7. Creates a Terraform Cloud Workspace for the deployment state
8. Connects the deployment workspace with the user specified VCS repo
9. Creates Terraform Environment variables in the deployment workspace for Azure authentication

## Why the need for this?

Provisioning all these resources and linking them together and what not is very cumbersome. This hopefully solves that and makes it easier to understand what Station requires.

Demoing Station is also very fast now!


## Usage

**IMPORTANT!** Do not run scripts from the internet without understanding what they do.

### Before you begin:
1. **Update the Bootstrap Script**:  
   Update the bootstrap script with your own values. Carefully read the variable names and comments to enter the correct values.

#### Environment Variables you need to set in the script

You will have to set either `TF_VAR_vcs_repo_github_app_installation_id` or `TF_VAR_vcs_repo_oauth_token_id`

   | Variable Name                                | Required/Optional | Description                                                                                         | Where to source the value                                                                                                                                             |
   | -------------------------------------------- | ----------------- | --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   | `TF_CLOUD_ORGANIZATION`                      | Required          | Name of your Terraform Cloud organization.                                                          | Your Terraform Cloud dashboard.                                                                                                                                       |
   | `TF_WORKSPACE`                               | Required          | Name of the workspace for storing the bootstrap state.           Just set a name for the workspace. |
   | `TF_VAR_tfc_organization_name`               | Required          | Organization name in Terraform Cloud.                                                               | Same as `TF_CLOUD_ORGANIZATION`.                                                                                                                                      |
   | `TF_VAR_bootstrap_tfc_workspace_name`        | Required          | Workspace name for storing the bootstrap state.                                                     | Same as `TF_WORKSPACE`.                                                                                                                                               |
   | `TF_VAR_tfc_project_name`                    | Required          | Decide a project name 'station'.                                                                    | Decide a name for the new project .                                                                                                                                   |
   | `TF_VAR_deployments_tfc_workspace_name`      | Required          | Workspace for station deployments.                                                                  | Decide a name for the deployments workspace                                                                                                                           |
   | `TF_VAR_vcs_repo_github_app_installation_id` | Optional          | ID for GitHub app installation in TFC.                                                              | [Terraform Cloud GitHub Installations](https://app.terraform.io/api/v2/github-app/installations)                                                                      |
   | `TF_VAR_vcs_repo_oauth_token_id`             | Optional          | Alternative to GitHub app installation ID.                                                          | Your GitHub settings or GitHub app integration in Terraform Cloud.                                                                                                    |
   | `TF_VAR_subscription_ids`                    | Required          | Azure Subscriptions where Station should have owner permissions.                                    | Use: `az account list --query "[?tenantId=='yourTenantID'].{Name:name, ID:id}" --output table`                                                                        |
   | `TF_VAR_vcs_repo_PAT`                        | Required          | Personal Access Token (PAT) for TFC to create repositories.                                         | [GitHub PAT Documentation](https://docs.github.com/en/enterprise-server@3.6/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) |
   | `TF_VAR_tfc_token`                           | Required          | Token for Terraform Cloud. Can be a team or organization token.                                     | Your Terraform Cloud dashboard under user settings or organization settings.                                                                                          |
   | `GITHUB_OWNER`                               | Required          | Target GitHub username or organization for the provider.                                            | Your GitHub username or organization name.                                                                                                                            |
   | `GITHUB_TOKEN`                               | Required          | Authentication token for GitHub provider.                                                           | Same as `TF_VAR_vcs_repo_PAT`.                                                                                                                                        |
   | `TF_VAR_vcs_repo_owner`                      | Required          | Owner of the repository in GitHub.                                                                  | Same as `GITHUB_OWNER`.                                                                                                                                               |
   | `TF_VAR_vcs_repo_name`                       | Optional          | Default repository name. Can be overridden in `variables.tf`.                                       | Decide a name for the new repository or use the default from `variables.tf`.                                                                                          |



1. **Log in to Azure**:  
   ```bash
   az login --tenant YourTenantID
   ```

2. **Log in to Terraform Cloud CLI**:  
   ```bash
   terraform login
   ```

3. **Setup Repository**:  
   Create a new repository in your organization to hold station deployments and ensure that Terraform Cloud (TFC) has been integrated with your organization. Also, confirm that the GitHub app for TFC is installed.

4. **Run the Script**:  
   ```bash
   ./bootstrap.sh
   ```

```


