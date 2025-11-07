# Terraform CI (GitHub Actions)

This repository includes a GitHub Actions workflow that performs Terraform formatting, initialization (with backend), validation and planning. It also supports an optional manual apply.

Required repository Secrets
- `AZURE_CREDENTIALS` - JSON credentials for GitHub `azure/login` action. Create with `az ad sp create-for-rbac --sdk-auth` and store the output JSON in this secret.
- `BACKEND_RG` - Name of the resource group that holds the Terraform state storage account (e.g. `rg-terraform-state-yourid`).
- `BACKEND_SA` - Name of the storage account used for tfstate (must be globally unique).
- `BACKEND_CONTAINER` - Name of the blob container to store tfstate (e.g. `tfstate`).
- `TERRAFORM_APPLY` (optional) - Set to `true` if you want to allow the workflow_dispatch to run `terraform apply`. This prevents accidental applies.

How the workflow runs
- On push to `main` and on pull requests it will run `terraform fmt -check`, `terraform init` (with backend configured from secrets), `terraform validate`, and `terraform plan`.
- For a manual run (Actions -> Terraform CI -> Run workflow) choose environment `dev` or `prd`. To let the workflow perform `terraform apply`, set `auto_apply` to `true` and ensure the `TERRAFORM_APPLY` secret equals `true`.

Bootstrap backend resources
1. Create resource group, storage account and container (example, replace placeholders):

```powershell
az group create -n rg-terraform-state-<SUBSCRIPTION> -l francecentral
az storage account create -n stterraformstate<UNIQUE_SUFFIX> -g rg-terraform-state-<SUBSCRIPTION> -l francecentral --sku Standard_LRS
az storage container create -n tfstate --account-name stterraformstate<UNIQUE_SUFFIX>
```

2. Set repository secrets with the values you've used (BACKEND_RG, BACKEND_SA, BACKEND_CONTAINER) and `AZURE_CREDENTIALS`.

Notes
- The workflow uses the environment path `env/dev` or `env/prd` inside the repo. Ensure your `backend.tfvars` files are correctly populated if you prefer not to use repository secrets for backend config.
- For production, harden the storage account (private endpoints, secure transfer, firewall rules) and consider using a dedicated service principal with limited scope for CI.
