# CI/CD Workflow Generator for AIS Platform

## Purpose
Automate GitHub Actions workflow generation for Terraform-based AIS platform projects.

## Activation
Ask: **"Set up CI/CD workflows for [project-path]"**

When activating, the assistant will prompt for Terraform backend details (resource group, storage account, container, key). Example: `"Set up CI/CD workflows for c:\Workspace\playground\project-simple-ipaas"`

---

## What I Generate

### 1. `terraform-ci.yaml` - PR Validation
- Runs on: Pull requests
- Actions: `fmt`, `validate`, `plan`, security scan (TFLint/Checkov)
- Output: Plan artifact for review

Note: Generated workflows will include a step to create a `backend.tfvars` file on the runner from provided backend details so the workflows call `terraform init -backend-config=backend.tfvars`.

### 2. `deploy.yaml` - Infrastructure Deployment
- Runs on: Push to `main`/`master`
- Actions: `init`, `plan`, `apply`
- Output: Deployed resources, configuration

### 3. `destroy.yaml` - Infrastructure Teardown
- Runs on: Manual trigger (`workflow_dispatch`)
- Actions: `plan -destroy`, manual approval, `destroy`
- Output: Destruction confirmation

---

## What I Analyze

From your project, I will detect:
- **Modules**: All modules in `modules/` directory
- **Environments**: Configurations in `env/dev/`, `env/staging/`, `env/prod/`
- **Backend**: State storage configuration from `backend.tfvars`

If a `backend.tfvars` is not present, the assistant will prompt for these values and embed a runner step that creates the `backend.tfvars` from repository secrets or inline values (prefer secrets for safety).
- **Cloud Provider**: Azure, AWS, or GCP based on resources
- **Naming Patterns**: Resource naming conventions from `locals.tf`

---

## Required GitHub Secrets

I'll identify which secrets you need to configure:

**Azure:**
- `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
- `TF_BACKEND_STORAGE_ACCOUNT`, `TF_BACKEND_CONTAINER`, `TF_BACKEND_KEY`
  
Additionally the assistant may request these secrets to be set so the workflow can create the `backend.tfvars` securely at runtime:
- `TF_BACKEND_RESOURCE_GROUP` (resource group name for backend)

**AWS:**
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `TF_BACKEND_BUCKET`, `TF_BACKEND_REGION`, `TF_BACKEND_DYNAMODB_TABLE`

**GCP:**
- `GCP_SERVICE_ACCOUNT_KEY`, `GCP_PROJECT_ID`
- `TF_BACKEND_BUCKET`, `TF_BACKEND_PREFIX`

---

## Workflow Best Practices Applied

✅ State locking and remote backend  
✅ Plan artifacts for PR review  
✅ Manual approval for destroy operations  
✅ Concurrency control (no parallel deploys)  
✅ Masked secrets in logs  
✅ Environment-specific configurations  

---

## Example Output Structure

```
.github/
└── workflows/
    ├── terraform-ci.yaml      # Validation on PRs
    ├── deploy.yaml            # Deploy on merge to main
    └── destroy.yaml           # Manual teardown
```

---

## Usage Examples

### Basic Setup
```
"Set up CI/CD for c:\Workspace\playground\project-simple-ipaas"
```

### With Customization
```
"Set up CI/CD for my project with Slack notifications and cost estimation"
```

### Multi-Environment
```
"Generate workflows for dev and prod environments with approval gates"
```

---

## Customization Options

Ask me to add:
- Slack/Teams/email notifications
- Cost estimation (Infracost)
- Multi-environment deployments
- Approval requirements
- Drift detection schedules
- Compliance scanning (KICS, Terrascan)
- OIDC authentication instead of secrets

---

## How I Work

1. **Analyze** your project structure and Terraform configuration
2. **Extract** environment variables, modules, and backend settings
3. **Generate** three workflow YAML files with inline documentation
    - Each workflow includes a step that creates `backend.tfvars` from secrets (if present) or uses a provided backend snippet. The workflows then call `terraform init -backend-config=backend.tfvars`.
4. **Provide** setup instructions for GitHub Secrets
5. **Validate** workflow syntax and best practices

---

## Prerequisites

Before using generated workflows:
- [ ] GitHub repository created
- [ ] Cloud provider credentials/service principal configured
- [ ] Terraform backend (Storage Account/S3/GCS) provisioned
- [ ] Branch protection rules on `main` (recommended)

---

## Quick Reference

| Workflow | Trigger | Duration | Approval |
|----------|---------|----------|----------|
| terraform-ci | PR | 3-5 min | No |
| deploy | Push to main | 5-10 min | Optional |
| destroy | Manual | 5-10 min | Required |

---

**Version**: 1.0  
**Compatible**: Terraform ≥1.5.0, GitHub Actions  
**Supports**: Azure, AWS, GCP
