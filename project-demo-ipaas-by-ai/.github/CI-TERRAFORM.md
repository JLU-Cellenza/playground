# Terraform CI/CD (GitHub Actions)# Terraform CI (GitHub Actions)



This repository includes GitHub Actions workflows that perform Terraform formatting, initialization, validation, planning, and deployment. Workflows are located at the repository root in `.github/workflows/`.This repository includes a GitHub Actions workflow that performs Terraform formatting, initialization (with backend), validation and planning. It also supports an optional manual apply.



## Required Repository SecretsRequired repository Secrets

- `AZURE_CREDENTIALS` - JSON credentials for GitHub `azure/login` action. Create with `az ad sp create-for-rbac --sdk-auth` and store the output JSON in this secret.

- `AZURE_CREDENTIALS` - JSON credentials for GitHub `azure/login` action. Create with `az ad sp create-for-rbac --sdk-auth` and store the output JSON in this secret.- `BACKEND_RG` - Name of the resource group that holds the Terraform state storage account (e.g. `rg-terraform-state-yourid`).

- `TERRAFORM_APPLY` (optional) - Set to `true` to allow the workflows to run `terraform apply`. This prevents accidental applies.- `BACKEND_SA` - Name of the storage account used for tfstate (must be globally unique).

- `BACKEND_CONTAINER` - Name of the blob container to store tfstate (e.g. `tfstate`).

## Backend Configuration- `TERRAFORM_APPLY` (optional) - Set to `true` if you want to allow the workflow_dispatch to run `terraform apply`. This prevents accidental applies.



The workflows use the backend configuration from `backend.tfvars` files in each environment directory:How the workflow runs

- `project-demo-ipaas-by-ai/env/dev/backend.tfvars`- On push to `main` and on pull requests it will run `terraform fmt -check`, `terraform init` (with backend configured from secrets), `terraform validate`, and `terraform plan`.

- `project-demo-ipaas-by-ai/env/prd/backend.tfvars`- For a manual run (Actions -> Terraform CI -> Run workflow) choose environment `dev` or `prd`. To let the workflow perform `terraform apply`, set `auto_apply` to `true` and ensure the `TERRAFORM_APPLY` secret equals `true`.



**No backend secrets are needed in GitHub!** The backend configuration is read directly from these files.Bootstrap backend resources

1. Create resource group, storage account and container (example, replace placeholders):

## How the Workflows Run

```powershell

### Terraform CI (`terraform-ci.yml`)az group create -n rg-terraform-state-<SUBSCRIPTION> -l francecentral

- Runs on push to `main` and on pull requestsaz storage account create -n stterraformstate<UNIQUE_SUFFIX> -g rg-terraform-state-<SUBSCRIPTION> -l francecentral --sku Standard_LRS

- Automatically runs against the `dev` environmentaz storage container create -n tfstate --account-name stterraformstate<UNIQUE_SUFFIX>

- Performs: `terraform fmt -check`, `terraform init`, `terraform validate`, and `terraform plan````

- For manual runs (Actions → Terraform CI → Run workflow):

  - Choose environment: `dev` or `prd`2. Set repository secrets with the values you've used (BACKEND_RG, BACKEND_SA, BACKEND_CONTAINER) and `AZURE_CREDENTIALS`.

  - Set `auto_apply` to `true` to run `terraform apply` (requires `TERRAFORM_APPLY` secret = `true`)

Notes

### Terraform Deploy (`terraform-deploy.yml`)- The workflow uses the environment path `env/dev` or `env/prd` inside the repo. Ensure your `backend.tfvars` files are correctly populated if you prefer not to use repository secrets for backend config.

- Manual workflow only (Actions → Terraform Deploy → Run workflow)- For production, harden the storage account (private endpoints, secure transfer, firewall rules) and consider using a dedicated service principal with limited scope for CI.

- Choose environment: `dev` or `prd`
- Type `YES` in the confirm field
- Requires `TERRAFORM_APPLY` secret set to `true`
- Runs a full plan and apply with approval gates

## Bootstrap Backend Resources

The backend storage must exist before running the workflows. Based on your `backend.tfvars`:

```powershell
# 1. Create resource group for Terraform state (if not exists)
az group create -n rg-common-iac-01 -l francecentral

# 2. Create storage account for Terraform state (if not exists)
az storage account create `
  -n stocommoniac01 `
  -g rg-common-iac-01 `
  -l francecentral `
  --sku Standard_LRS

# 3. Create container for state files (if not exists)
az storage container create `
  -n terraform `
  --account-name stocommoniac01
```

## Setup GitHub Secrets

### 1. Create Service Principal

```powershell
# Replace with your subscription ID
$subscriptionId = "YOUR-SUBSCRIPTION-ID"

az ad sp create-for-rbac `
  --name "sp-github-terraform-ipaas" `
  --role Contributor `
  --scopes /subscriptions/$subscriptionId `
  --sdk-auth
```

Copy the entire JSON output.

### 2. Add Secrets to GitHub

Go to your repository → Settings → Secrets and variables → Actions → New repository secret:

**AZURE_CREDENTIALS**: Paste the JSON from step 1:
```json
{
  "clientId": "00000000-0000-0000-0000-000000000000",
  "clientSecret": "your-secret-here",
  "subscriptionId": "00000000-0000-0000-0000-000000000000",
  "tenantId": "00000000-0000-0000-0000-000000000000"
}
```

**TERRAFORM_APPLY**: Set to `true` (allows deployments):
```
true
```

## Testing the Workflows

### Test CI Workflow
1. Make a change to any Terraform file in `project-demo-ipaas-by-ai/`
2. Commit and push to a branch
3. Create a pull request to `main`
4. The CI workflow will automatically run and show plan results

### Test Deploy Workflow
1. Go to Actions → Terraform Deploy → Run workflow
2. Select environment: `dev`
3. Type `YES` in the confirm field
4. Click "Run workflow"
5. Monitor the deployment progress

## Troubleshooting

### Workflow not running?
- Ensure workflows are at repository root: `.github/workflows/`
- Check that file paths in triggers are correct
- Verify branch name is `main` (not `master`)

### Authentication errors?
- Verify `AZURE_CREDENTIALS` secret is valid JSON
- Check service principal has Contributor role
- Ensure service principal hasn't expired

### Backend initialization fails?
- Confirm storage account `stocommoniac01` exists
- Verify resource group `rg-common-iac-01` exists
- Check container `terraform` exists in the storage account
- Ensure service principal has access to the storage account

### Plan fails with missing variables?
- Ensure `.tfvars` files exist in each environment directory
- Check that variable names match between `variables.tf` and `.tfvars`
- Verify no sensitive values are needed (use secrets if required)

## Security Notes

- Service principal credentials are never exposed in logs
- Terraform state is stored securely in Azure Storage
- All secrets are managed through GitHub Secrets
- For production, consider using managed identities or OIDC federation
- Enable private endpoints on the storage account for enhanced security
