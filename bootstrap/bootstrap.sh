#!/bin/bash

# Provider authentication (`tfe`)
export TF_CLOUD_ORGANIZATION="managed-devops" #Name of your Terraform Cloud organization 
export TF_WORKSPACE="station-bootstrap" # Name of the station bootstrap workspace. 

# Terraform variables
export TF_VAR_tfc_organization_name=$TF_CLOUD_ORGANIZATION
export TF_VAR_bootstrap_tfc_workspace_name=$TF_WORKSPACE
# 
export TF_VAR_tfc_project_name="station" #The name of the new TFC project for station
export TF_VAR_deployments_tfc_workspace_name="station-deployments" #Workspace name for station deployments
export TF_VAR_vcs_repo_identifier="yourOrg/station-deployments" #Name of the station deployments repo. This hsa to be created manualy
export TF_VAR_vcs_repo_branch="trunk" #Name of the default branch for the repo you just created
export TF_VAR_vcs_repo_github_app_installation_id="ghain-YourIdHere" #This can be found here https://app.terraform.io/api/v2/github-app/installations. This requeris that the github terraform app has allready beenn installed 
export TF_VAR_subscription_ids="["UUID1", "UUID2"]" #Set of Azure Subscription that Station should be added as owner of. Use this command to get the subscriptions: az account list --query "[?tenantId=='yourTenantID'].{Name:name, ID:id}" --output table

# Validation to ensure your not trying to bootstrap into the wrong Azure tenant 
echo -e "Starting the bootstrap proccess against this tenant: \n \n "

TENANT_ID=$(az account show --query "tenantId" -o tsv)

if [ -z "$TENANT_ID" ]; then
    echo "Failed to retrieve active tenant ID. Please ensure you're logged in using 'az login'."
    exit 1
fi

az account show


for i in {10..1}
do
    echo "You have $i sec to abort the script before the bootstrap start"
    sleep 1
done

echo "Starting the bootstrap!"


rm ./providers.tf

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