#!/bin/bash

# Provider authentication (`tfe`)
export TF_CLOUD_ORGANIZATION="your-org" #Name of your Terraform Cloud organization 
export TF_WORKSPACE="station-bootstrap" # Name of the station bootstrap workspace. This is used to store the state for the bootstrap 

# Terraform variables
export TF_VAR_tfc_organization_name=$TF_CLOUD_ORGANIZATION
export TF_VAR_bootstrap_tfc_workspace_name=$TF_WORKSPACE
# 
export TF_VAR_tfc_project_name="station" #The name of the new TFC project for station
export TF_VAR_deployments_tfc_workspace_name="station-deployments" #Workspace name for station deployments
export TF_VAR_vcs_repo_github_app_installation_id="ghain-yourKey" #This can be found here https://app.terraform.io/api/v2/github-app/installations. This requeries that the github terraform app has allready beenn installed the github org you want to use
export TF_VAR_subscription_ids="[\"YourSubscriptionID1\"], \"YourSubscriptionID2\"]" #Set of Azure Subscription that Station should be added as owner of. Use this command to get the subscriptions: az account list --query "[?tenantId=='yourTenantID'].{Name:name, ID:id}" --output table
export TF_VAR_vcs_repo_PAT="ghp_GithubPersonalAccessToken" #Create a PAT that will be passed to TFC to be able to create repositories. https://docs.github.com/en/enterprise-server@3.6/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
export TF_VAR_tfc_token="" #This can be both a team or org token
# Github variables
export GITHUB_OWNER="Github-username-or-org" #Used for the github provider to select what org/user to target
export GITHUB_TOKEN=$TF_VAR_vcs_repo_PAT #Used for the github provider for auth
export TF_VAR_vcs_repo_owner=$GITHUB_OWNER
export TF_VAR_vcs_repo_name="station-deployments_test" #this is set as a default in varibles.tf

# Color definitions
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

# Validation to ensure you're not trying to bootstrap into the wrong Azure tenant 
echo -e "${GREEN}Starting the bootstrap process against this tenant:${RESET} \n \n "

TENANT_ID=$(az account show --query "tenantId" -o tsv)

if [ -z "$TENANT_ID" ]; then
    echo -e "${RED}Failed to retrieve active tenant ID. Please ensure you're logged in using 'az login'.${RESET}"
    exit 1
fi

echo -e "${YELLOW}Azure Account Information:${RESET}"
az account show | jq '. | {tenantId, name, user}'
echo -e "\n"

# Display environment variables to the user
echo -e "\n${YELLOW}Environment Variables:${RESET}"

echo -e "${BLUE}TF_CLOUD_ORGANIZATION:${RESET} ${GREEN}$TF_CLOUD_ORGANIZATION${RESET}"
echo -e "${BLUE}TF_WORKSPACE:${RESET} ${GREEN}$TF_WORKSPACE${RESET}"
echo -e "${BLUE}TF_VAR_tfc_project_name:${RESET} ${GREEN}$TF_VAR_tfc_project_name${RESET}"
echo -e "${BLUE}TF_VAR_deployments_tfc_workspace_name:${RESET} ${GREEN}$TF_VAR_deployments_tfc_workspace_name${RESET}"
echo -e "${BLUE}TF_VAR_vcs_repo_github_app_installation_id:${RESET} ${GREEN}$TF_VAR_vcs_repo_github_app_installation_id${RESET}"
echo -e "${BLUE}TF_VAR_subscription_ids:${RESET} ${GREEN}$TF_VAR_subscription_ids${RESET}"
echo -e "${BLUE}TF_VAR_vcs_repo_PAT:${RESET} ${GREEN}$TF_VAR_vcs_repo_PAT${RESET}"
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