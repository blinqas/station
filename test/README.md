# Terraform Station Tests

This folder contains all testing done with Station. As of now, these are ran locally from a developer's machine. This folder is supposed to make development and testing much easier. In the future this will run in GHA as well.

## How to run

```bash
az login

terraform login

terraform init

# Replace empty strings with your environment's values.
TFE_ORGANIZATION="" \
TF_VAR_tfc_organization_name="" \
TF_VAR_tfc_project_name="" \
terraform plan -out plan.tfplan

terraform apply -out plan.tfplan
```

