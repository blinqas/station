#!/bin/bash

read -p 'Terraform Cloud Organization Name: ' tfc_organization_name
read -p 'Name of TFC workspace to store bootstrap state: ' tfc_bootstrap_workspace_name

cp "./providers/providers_local_state.tf" "./providers.tf"

terraform init -upgrade

terraform workspace new "$tfc_bootstrap_workspace_name"

terraform plan -out "./plan.tfplan"

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
terraform plan -out "./plan.tfplan"

