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

2. **Log in to Azure**:  
   ```bash
   az login --tenant YourTenantID
   ```

3. **Log in to Terraform Cloud CLI**:  
   ```bash
   terraform login
   ```

4. **Setup Repository**:  
   Create a new repository in your organization to hold station deployments and ensure that Terraform Cloud (TFC) has been integrated with your organization. Also, confirm that the GitHub app for TFC is installed.

5. **Run the Script**:  
   ```bash
   ./bootstrap.sh
   ```

```


