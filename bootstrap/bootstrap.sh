#!/bin/bash

# Terraform Cloud (TFC) Authentication details
export TF_CLOUD_ORGANIZATION="your-org"                                     # Organization name in Terraform Cloud.
export TF_WORKSPACE="station-bootstrap"                                     # Workspace for storing the bootstrap state.

# Terraform-specific variables
export TF_VAR_tfc_organization_name=$TF_CLOUD_ORGANIZATION                  # Set organization name from above variable.
export TF_VAR_bootstrap_tfc_workspace_name=$TF_WORKSPACE                    # Set workspace name from above variable.
export TF_VAR_tfc_project_name="station"                                    # Project name in Terraform Cloud for 'station'.
export TF_VAR_deployments_tfc_workspace_name="station-deployments"          # Workspace for station deployments.
export TF_VAR_vcs_repo_github_app_installation_id="ghain-yourKey"           # ID for GitHub app installation in TFC. Ensure GitHub Terraform app is pre-installed: https://app.terraform.io/api/v2/github-app/installations.
# export TF_VAR_vcs_repo_oauth_token_id=""                                  # Alternative to GitHub app installation ID. Use either this or the above.
export TF_VAR_subscription_ids="[\"Subscription_1\"], [\"Subscription_2\"]" # Azure Subscriptions where Station should have owner permissions. Fetch using: az account list --query "[?tenantId=='yourTenantID'].{Name:name, ID:id}" --output table
export TF_VAR_vcs_repo_PAT="ghp_GithubPersonalAccessToken"                  # Personal Access Token (PAT) for TFC to create repositories. Documentation: https://docs.github.com/en/enterprise-server@3.6/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
export TF_VAR_tfc_token="YourTFCToken"                                      # Token for Terraform Cloud, can be a team or organization token. https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens

# GitHub-related variables
export GITHUB_OWNER="Github-username-or-org"                                # Target GitHub username or organization for the provider.
export GITHUB_TOKEN=$TF_VAR_vcs_repo_PAT                                    # Authentication token for GitHub provider.
export TF_VAR_vcs_repo_owner=$GITHUB_OWNER                                  # Set repository owner from above variable.
export TF_VAR_vcs_repo_name="station-deployments_test"                      # Default repository name (can be overridden in variables.tf).

# Color definitions
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# Validation to ensure you're not trying to bootstrap into the wrong Azure tenant
echo -e "${GREEN}Starting the bootstrap process against this tenant:${RESET} \n \n "

TENANT_ID=$(az account show --query "tenantId" -o tsv)

if [ -z "$TENANT_ID" ]; then
    echo -e "${RED}Failed to retrieve active tenant ID. Please ensure you're logged in using 'az login'.${RESET}"
    exit 1
fi

echo -e "${YELLOW}Azure Account Information:${RESET}"
az account show | jq '. | {tenantId, name, user}'

# Removing the escaping and converting to a single array
SUBSCRIPTION_IDS_CLEANED=$(echo $TF_VAR_subscription_ids | sed 's/\\//g')

echo -e "${YELLOW}Selected Azure subscription(s):${RESET} ${GREEN}$SUBSCRIPTION_IDS_CLEANED${RESET}"

# Splitting the values and querying Azure for each
IFS=',' read -ra SUBSCRIPTIONS <<<"$SUBSCRIPTION_IDS_CLEANED"
for sub in "${SUBSCRIPTIONS[@]}"; do
    SUB_CLEAN=$(echo $sub | tr -d '[]" ')
    echo -en " \n ${YELLOW} Details for subscription ID $SUB_CLEAN: ${RESET}"
    az account show --subscription $SUB_CLEAN | jq '. | {tenantId, name, user}'
done

# Display environment variables to the user
echo -e "\n${YELLOW}Environment Variables:${RESET}"

echo -e "${BLUE}TF_CLOUD_ORGANIZATION:${RESET} ${GREEN}$TF_CLOUD_ORGANIZATION${RESET}"
echo -e "${BLUE}TF_WORKSPACE:${RESET} ${GREEN}$TF_WORKSPACE${RESET}"
echo -e "${BLUE}TF_VAR_tfc_project_name:${RESET} ${GREEN}$TF_VAR_tfc_project_name${RESET}"
echo -e "${BLUE}TF_VAR_deployments_tfc_workspace_name:${RESET} ${GREEN}$TF_VAR_deployments_tfc_workspace_name${RESET}"
echo -e "${BLUE}TF_VAR_vcs_repo_github_app_installation_id:${RESET} ${GREEN}$TF_VAR_vcs_repo_github_app_installation_id${RESET}"
echo -e "${BLUE}TF_VAR_subscription_ids:${RESET} ${GREEN}$TF_VAR_subscription_ids${RESET}"
echo -e "${BLUE}TF_VAR_vcs_repo_PAT:${RESET} ${GREEN}[hidden for security]${RESET}"
echo -e "${BLUE}TF_VAR_tfc_token:${RESET} ${GREEN}[hidden for security]${RESET}"
echo -e "${BLUE}GITHUB_OWNER:${RESET} ${GREEN}$GITHUB_OWNER${RESET}"
echo -e "${BLUE}GITHUB_TOKEN:${RESET} ${GREEN}[hidden for security]${RESET}"
echo -e "${BLUE}TF_VAR_vcs_repo_owner:${RESET} ${GREEN}$TF_VAR_vcs_repo_owner${RESET}"
echo -e "${BLUE}TF_VAR_vcs_repo_name:${RESET} ${GREEN}$TF_VAR_vcs_repo_name${RESET}"

### Prompt the user if they want to continue###
echo -e " \n Do you want to proceed with the above settings? [y/n]"
read -p "" answer

[[ $answer =~ ^[Yy] ]] || exit

echo "${GREEN}Starting the bootstrap!${RESET}"

rm ./providers.tf
rm -rf ./terraform.tfstate.d
rm .terraform.lock.hcl
rm -rf ./.terraform

cp "./providers/providers_local_state.tf" "./providers.tf"

terraform init -upgrade

terraform plan -out "./plan.tfplan"

terraform apply "./plan.tfplan"

# Re-run and migrate state to Terraform Cloud

rm "./providers.tf"
cp "./providers/providers.tf" "./providers.tf"
cp "terraform.tfstate" "terraform.tfstate.before-migration.backup"
rm "terraform.tfstate"

terraform init

terraform plan -out "./plan.tfplan"
