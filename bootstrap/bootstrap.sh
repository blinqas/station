#!/bin/bash

read -rp 'Terraform Cloud Organization Name: ' tfc_organization_name
read -rp 'Name of TFC workspace to store bootstrap state: ' tfc_bootstrap_workspace_name

TENANT_ID=$(az account show --query "tenantId" -o tsv)

if [ -z "$TENANT_ID" ]; then
    echo "Failed to retrieve active tenant ID. Please ensure you're logged in using 'az login'."
    exit 1
fi

echo Available subscriptions:; echo; echo
az account list --query "[?tenantId=='$TENANT_ID'].{Name:name, ID:id}" --output table
echo; echo; echo

echo "Update the variables.tfvars.json file with the subscriptions_ids you want station to have access to"; echo; echo
# Prompt the user
read -p 'Have you updated the variables.tfvars.json file with the Azure Subscriptions? [y/n]: ' answer

# Exit if the answer is 'no' or invalid
if [[ ${answer,,} != "y" && ${answer,,} != "yes" ]]; then
    echo "Exiting."
    exit 1
fi

read -p 'Have you updated variables.tfvars.json with the authentication options for github. [y/n]: ' answer
# Exit if the answer is 'no' or invalid
if [[ ${answer,,} != "y" && ${answer,,} != "yes" ]]; then
    echo "Exiting."
    exit 1
fi

FILE="variables.tfvars.json" #File where we define github auth and the subscription_ids

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq to parse JSON."
    exit 1
fi


# Extract the values from the tfvars file
vcs_repo_github_app_installation_id=$(jq -r '.vcs_repo_github_app_installation_id' "$FILE")
vcs_repo_oauth_token_id=$(jq -r '.vcs_repo_oauth_token_id' "$FILE")
subscription_ids_count=$(jq '.subscription_ids | length' "$FILE")
#Validate that either of the vsc_ variables has beed changed to someting else than null
if [[ "$vcs_repo_github_app_installation_id" != "null" && "$vcs_repo_oauth_token_id" != "null" ]]; then
    echo "Error: Both vcs_repo_github_app_installation_id and vcs_repo_oauth_token_id are set. Only one of them should be set."
    exit 1
elif [[ "$vcs_repo_github_app_installation_id" == "null" && "$vcs_repo_oauth_token_id" == "null" ]]; then
    echo "Error: Both vcs_repo_github_app_installation_id and vcs_repo_oauth_token_id are null. One of them should be set."
    exit 1
else
    echo "The Github config has been provided"; echo; echo
fi

# Validate subscription_ids array is not empty
if [ "$subscription_ids_count" -eq 0 ]; then
    echo "Error: subscription_ids array is empty."
    exit 1
else 
    echo "One or more subscription IDs has been provided"; echo; echo  
fi

cp "./providers/providers_local_state.tf" "./providers.tf"

terraform init -upgrade

terraform workspace new "$tfc_bootstrap_workspace_name"

terraform plan -var-file="variables.tfvars.json" -out "./plan.tfplan"

terraform apply "./plan.tfplan"

# # # 
#
# Re-run and migrate state to Terraform Cloud

rm "./providers.tf"
cp "./providers/providers.tf" "./providers.tf"
cp "terraform.tfstate" "terraform.tfstate.before-migration.backup"
rm "terraform.tfstate"

TF_CLOUD_ORGANIZATION=$tfc_organization_name \
TF_WORKSPACE=$tfc_bootstrap_workspace_name \
terraform init

TF_CLOUD_ORGANIZATION=$tfc_organization_name \
TF_WORKSPACE=$tfc_bootstrap_workspace_name \
terraform plan

