TFE_ORGANIZATION="blinq-west-lab"
TF_VAR_tfc_organization_name="blinq-west-lab"
TF_VAR_tfc_project_name="test"
TF_VAR_tenant_id="058acfd5-2d6b-4a8b-9b2c-7f077f2229b8"
TF_VAR_subscription_id="24721414-40ad-41f7-ab9d-8b4e519ed12b"
ARM_SUBSCRIPTION_ID="24721414-40ad-41f7-ab9d-8b4e519ed12b"
bash terraform init
bash terraform test -filter /tests/application.tftest.hcl