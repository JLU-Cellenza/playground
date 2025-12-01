# CI/CD Workflow Generator for AIS Platform

## Purpose
Automate GitHub Actions workflow generation for Terraform-based AIS platform projects.

## Activation

**MANDATORY PROJECT NAME PARAMETER REQUIRED**

Ask: **"Set up CI/CD workflows for project: [PROJECT_NAME]"**

The `PROJECT_NAME` parameter is **mandatory** and must be explicitly provided. The assistant will not proceed without it.

Examples:
- ✅ `"Set up CI/CD workflows for project: project-simple-ipaas"`
- ✅ `"Set up CI/CD workflows for project: project-demo-ipaas-by-ai"`
- ❌ `"Set up CI/CD workflows"` (INVALID - project name missing)

When activating with a valid project name, the assistant will:
1. Validate the project exists in the workspace
2. Prompt for Terraform backend details (resource group, storage account, container, key)
3. Generate workflows that accept the project name as an input parameter

---

## What I Generate

**IMPORTANT**: All workflow files are created in **`.github/workflows/`** at the **repository root**, NOT inside project directories.

All workflows accept **project name as a mandatory input parameter** using GitHub Actions `workflow_dispatch` input.

### 1. `terraform-ci.yaml` - PR Validation
- **Location**: `.github/workflows/terraform-ci.yaml` (repo root)
- Runs on: Pull requests OR Manual trigger (`workflow_dispatch`)
- Input: `project_name` (dropdown, required - must select from available projects)
- Actions: `fmt`, `validate`, `plan`, security scan (TFLint/Checkov)
- Working directory: `./${{ inputs.project_name }}/env/${{ inputs.environment }}/`
- Output: Plan artifact for review

Note: Generated workflows will include a step to create a `backend.tfvars` file on the runner from provided backend details so the workflows call `terraform init -backend-config=backend.tfvars`.

### 2. `deploy.yaml` - Infrastructure Deployment
- **Location**: `.github/workflows/deploy.yaml` (repo root)
- Runs on: Manual trigger (`workflow_dispatch`) ONLY
- Input: 
  - `project_name` (dropdown, required - must select from available projects)
  - `environment` (dropdown, required - dev/staging/prod)
- Actions: `init`, `plan`, `apply`
- Working directory: `./${{ inputs.project_name }}/env/${{ inputs.environment }}/`
- Output: Deployed resources, configuration

### 3. `destroy.yaml` - Infrastructure Teardown
- **Location**: `.github/workflows/destroy.yaml` (repo root)
- Runs on: Manual trigger (`workflow_dispatch`) ONLY
- Input: 
  - `project_name` (dropdown, required - must select from available projects)
  - `environment` (dropdown, required - dev/staging/prod)
- Actions: `plan -destroy`, manual approval, `destroy`
- Working directory: `./${{ inputs.project_name }}/env/${{ inputs.environment }}/`
- Output: Destruction confirmation

---

### APIM-Specific Workflows (if APIM detected)

If the project contains an `apim/` directory, **additional APIM-specific workflows** will be generated:

### 4. `apim-ci.yaml` - APIM PR Validation
- **Location**: `.github/workflows/apim-ci.yaml` (repo root)
- Runs on: Pull requests OR Manual trigger (`workflow_dispatch`)
- Input: `project_name` (dropdown, required - filtered to projects with APIM)
- Actions: `fmt`, `validate`, `plan` for APIM configuration
- Working directory: `./${{ inputs.project_name }}/apim/`
- Output: APIM plan artifact for review

### 5. `apim-deploy.yaml` - APIM Deployment
- **Location**: `.github/workflows/apim-deploy.yaml` (repo root)
- Runs on: Manual trigger (`workflow_dispatch`) ONLY
- Input: 
  - `project_name` (dropdown, required - filtered to projects with APIM)
  - `environment` (dropdown, required - dev/staging/prod)
  - `confirm` (string, required - must type "YES" to confirm)
- **Pre-Deployment Validations:**
  - ✅ Verify project has `apim/` directory (explicit error if missing)
  - ✅ Verify destination Resource Group exists in Azure (explicit error if missing; requires main platform deployed first)
  - ✅ Verify Terraform Apply secret is enabled
- Actions: `init`, `plan`, `apply` for APIM
- Working directory: `./${{ inputs.project_name }}/apim/`
- Output: Deployed APIM resources, configuration
- **⚠️ Important:** APIM takes 25-30 minutes to provision. Deploy main platform **first** to create Resource Group and Log Analytics.

### 6. `apim-destroy.yaml` - APIM Teardown
- **Location**: `.github/workflows/apim-destroy.yaml` (repo root)
- Runs on: Manual trigger (`workflow_dispatch`) ONLY
- Input: 
  - `project_name` (dropdown, required - filtered to projects with APIM)
  - `environment` (dropdown, required - dev/staging/prod)
  - `confirm` (string, required - must type "DESTROY-APIM" to confirm)
- **Pre-Destruction Validations:**
  - ✅ Verify project has `apim/` directory (explicit error if missing)
  - ✅ Verify Terraform Destroy secret is enabled
- Actions: `plan -destroy`, manual approval, `destroy` for APIM
- Working directory: `./${{ inputs.project_name }}/apim/`
- Output: APIM destruction confirmation

**Key Design**: Single set of workflows at repo root serve ALL projects by accepting project name at runtime. APIM workflows are generated only if APIM module is detected in the project.

**Deployment Sequence (CRITICAL):**
1. Deploy main platform **first** (Standard Deploy workflow) → creates Resource Group, Log Analytics, all core services
2. Wait 5-10 minutes for main platform to stabilize
3. Deploy APIM **second** (APIM Deploy workflow) → uses data sources to reference existing Resource Group and Log Analytics
4. Validation gates prevent APIM deployment if Resource Group doesn't exist

**Destruction Sequence (CRITICAL):**
1. Destroy APIM **first** (APIM Destroy workflow)
2. Wait 30-60 seconds for APIM to be removed
3. Destroy main platform **second** (Standard Destroy workflow)

---

## What I Analyze

From your **selected project**, I will detect:
- **Project Name**: Validated against workspace projects
- **Project Structure**: Check for APIM directory (`{PROJECT_NAME}/apim/`) to determine if APIM workflows are needed
- **Modules**: All modules in `{PROJECT_NAME}/modules/` directory
- **Environments**: Configurations in `{PROJECT_NAME}/env/dev/`, `{PROJECT_NAME}/env/staging/`, `{PROJECT_NAME}/env/prod/`
- **APIM Configuration**: If `{PROJECT_NAME}/apim/` exists, analyze APIM-specific Terraform files
- **Backend**: State storage configuration from `{PROJECT_NAME}/env/{environment}/backend.tfvars` (and `{PROJECT_NAME}/apim/backend.tfvars` if APIM exists)

If a `backend.tfvars` is not present, the assistant will prompt for these values and embed a runner step that creates the `backend.tfvars` from repository secrets or inline values (prefer secrets for safety).
- **Cloud Provider**: Azure, AWS, or GCP based on resources
- **Naming Patterns**: Resource naming conventions from `{PROJECT_NAME}/env/{environment}/locals.tf`

---

## Available Projects

The following projects are available in this workspace:
- `project-simple-ipaas` (Standard AIS platform - no APIM)
- `project-demo-ipaas-by-ai` (Full AIS platform - includes APIM)

**Note**: You must specify one of these project names when setting up CI/CD workflows.

**APIM Detection**: Projects with an `apim/` directory will automatically trigger generation of 3 additional APIM-specific workflows.

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
└── workflows/                          # ← WORKFLOWS AT REPO ROOT
    ├── terraform-ci.yaml              # Validation (accepts project_name input)
    ├── deploy.yaml                    # Deploy (accepts project_name + environment inputs)
    ├── destroy.yaml                   # Teardown (accepts project_name + environment inputs)
    ├── apim-ci.yaml                   # APIM Validation (generated only if APIM detected)
    ├── apim-deploy.yaml               # APIM Deploy (generated only if APIM detected)
    └── apim-destroy.yaml              # APIM Teardown (generated only if APIM detected)

project-simple-ipaas/                   # ← PROJECT WITHOUT APIM (3 workflows only)
└── env/
    ├── dev/
    │   ├── main.tf
    │   ├── backend.tfvars
    │   └── ...
    └── prod/
        └── ...

project-demo-ipaas-by-ai/              # ← PROJECT WITH APIM (6 workflows total)
├── env/
│   └── dev/
│       └── ...
└── apim/                              # ← APIM detected = 3 extra workflows generated
    ├── main.tf
    ├── backend.tfvars
    └── ...
```

**Architecture**: One centralized workflow set serves multiple projects via runtime inputs. APIM workflows are conditionally generated based on project structure.

---

## APIM Deployment Prerequisites & Validation Controls

**CRITICAL:** APIM must be deployed **after** the main platform. Both workflows now enforce strict validation gates.

### Pre-Deployment Validation (APIM Deploy Workflow)

The APIM Deploy workflow (`apim-deploy.yaml`) performs automated checks **before** running Terraform:

1. **Project APIM Directory Check**
   - Validates that the selected project has an `apim/` directory
   - **Fails explicitly** if project lacks APIM support
   - Error message lists available APIM projects

2. **Resource Group Existence Check**
   - Queries Azure to verify the destination Resource Group exists
   - Uses Resource Group name from `{project}/env/{environment}/locals.tf`
   - **Fails explicitly** if Resource Group not found
   - Error message instructs user to deploy main platform first

### Why These Controls Matter

| Scenario | Without Controls | With Controls |
|----------|------------------|---------------|
| APIM deploy before main platform | Terraform hangs, data sources fail, 401 errors | Workflow stops immediately with clear error message |
| Wrong project selected | Deploys APIM to unexpected location | Workflow validates project has apim/ and stops |
| Manual Resource Group deletion | APIM deployment fails mid-way | Pre-deployment check catches missing RG upfront |
| Incomplete Terraform setup | Cryptic Azure provider errors | Clear, actionable error messages |

### Correct Deployment Sequence

```
Step 1: Deploy Main Platform
  └─ Command: gh workflow run "Terraform Deploy" -f project_name=project-demo-ipaas-by-ai -f environment=dev -f confirm=YES
  └─ Output: Resource Group + Log Analytics + all services (5-10 min)
  └─ ✅ Check: az group show --name rg-dev-clz-sipaas

Step 2: Wait 5 minutes (for RBAC propagation)

Step 3: Deploy APIM
  └─ Command: gh workflow run "Deploy APIM" -f project_name=project-demo-ipaas-by-ai -f environment=dev -f confirm=YES
  └─ Pre-checks:
     ├─ ✅ Validates apim/ directory exists
     ├─ ✅ Validates Resource Group exists (created in Step 1)
     └─ ✅ Validates Terraform Apply secret is enabled
  └─ Output: APIM service (25-30 min)
```

### Validation Errors & Resolution

**Error: "Project does not have an apim/ directory"**
- Cause: Wrong project selected or project lacks APIM module
- Resolution: Use `project-demo-ipaas-by-ai` (only project with APIM)

**Error: "Destination Resource Group '$RG_NAME' does not exist"**
- Cause: Main platform not deployed yet
- Resolution: Deploy main platform first using Standard Deploy workflow

**Error: "Could not determine resource group name"**
- Cause: `locals.tf` missing or malformed
- Resolution: Ensure `{project}/env/{environment}/locals.tf` defines `resource_group_name`

### Destroy Sequence (Reverse Order)

```
Step 1: Destroy APIM First
  └─ Command: gh workflow run "Destroy APIM" -f project_name=project-demo-ipaas-by-ai -f environment=dev -f confirm=DESTROY-APIM
  └─ Output: APIM removed (5-10 min)

Step 2: Destroy Main Platform
  └─ Command: gh workflow run "Terraform Destroy" -f project_name=project-demo-ipaas-by-ai -f environment=dev -f confirm=DESTROY
  └─ Output: All resources destroyed (5-10 min)
```

---

## Usage Examples

### Basic Setup (REQUIRED FORMAT)
```
"Set up CI/CD workflows for project: project-simple-ipaas"
```
This generates 3 workflows (terraform-ci, deploy, destroy)

```
"Set up CI/CD workflows for project: project-demo-ipaas-by-ai"
```
This generates 6 workflows (3 standard + 3 APIM-specific)

### Deploying with Specific Project (Once workflows are created)
```
"Trigger deployment for project: project-simple-ipaas to dev environment"
```

### With Customization
```
"Set up CI/CD workflows for project: project-demo-ipaas-by-ai with Slack notifications and cost estimation"
```

### Multi-Environment
```
"Set up CI/CD workflows for project: project-simple-ipaas for dev and prod environments with approval gates"
```

⚠️ **All examples must include the project name as a mandatory parameter**

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

1. **Validate Project Name** (FIRST STEP - MANDATORY)
   - Check that the provided project name exists in workspace
   - Abort if project name is missing or invalid
   - Display available projects if invalid

2. **Check Existing Workflows** (SECOND STEP - MANDATORY)
   - Scan `.github/workflows/` directory for existing workflow files
   - Check for:
     - `terraform-ci.yaml`, `deploy.yaml`, `destroy.yaml`
     - `apim-ci.yaml`, `apim-deploy.yaml`, `apim-destroy.yaml`
   - If ANY workflows exist:
     - **STOP and prompt user** with options:
       - ✅ "Overwrite existing workflows" (replace all)
       - ✅ "Merge with existing workflows" (keep existing, add missing)
       - ✅ "Skip generation" (abort)
       - ✅ "Review differences first" (show what would be created/changed)
     - **WAIT for user decision** before proceeding
   - If NO workflows exist: Proceed to next step
   
3. **Detect APIM Module**
   - Check if `{PROJECT_NAME}/apim/` directory exists
   - If YES: Generate 6 workflows (3 standard + 3 APIM-specific)
   - If NO: Generate 3 workflows (standard only)
   
4. **Analyze** the selected project structure and Terraform configuration

5. **Extract** environment variables, modules, and backend settings from the specified project

6. **Generate** workflow YAML files **in `.github/workflows/` at repo root** with inline documentation
   - **Standard workflows** (always generated):
     - Each workflow includes:
       - `workflow_dispatch` input requiring `project_name` selection (dropdown with available projects)
       - `environment` input for deploy/destroy workflows (dev/staging/prod)
       - Dynamic working directory: `./${{ inputs.project_name }}/env/${{ inputs.environment }}/`
       - Dynamic backend state key: `terraform/${{ inputs.project_name }}/${{ inputs.environment }}/terraform.tfstate`
       - Validation step to check project directory exists before running Terraform
       - Step to create `backend.tfvars` from secrets at runtime
       - Workflows call `terraform init -backend-config=backend.tfvars`
   
   - **APIM workflows** (generated only if `apim/` directory detected):
     - Same structure as standard workflows but:
       - Working directory: `./${{ inputs.project_name }}/apim/`
       - Backend state key: `terraform/${{ inputs.project_name }}/apim/terraform.tfstate`
       - Project name dropdown filtered to only show projects with APIM
   
7. **Provide** setup instructions for GitHub Secrets

8. **Validate** workflow syntax and best practices

**Critical Rules**: 
- Workflows are NEVER created inside project directories. They are always created in `.github/workflows/` at the repository root and use input parameters to determine which project to operate on.
- Existing workflows are NEVER overwritten without explicit user confirmation.

## Mandatory Input Parameter Enforcement

⚠️ **The `project_name` parameter is REQUIRED and NON-NEGOTIABLE**

- ✅ Requests **WITH** project name: Proceed normally
- ❌ Requests **WITHOUT** project name: 
  - Do not generate workflows
  - Prompt user: *"Please specify the project name. Available projects: project-simple-ipaas, project-demo-ipaas-by-ai"*
  - Wait for user to provide valid project name before proceeding

**Why this is important**: This ensures workflows are generated for the correct project and prevents accidental deployments to the wrong infrastructure.

---

## Workflow File Location Requirements

🎯 **Workflows MUST be created at repository root**

- ✅ **Correct**: `.github/workflows/terraform-ci.yaml` (at repo root)
- ✅ **Correct**: `.github/workflows/deploy.yaml` (at repo root)
- ✅ **Correct**: `.github/workflows/destroy.yaml` (at repo root)
- ❌ **WRONG**: `project-simple-ipaas/.github/workflows/deploy.yaml`
- ❌ **WRONG**: `project-demo-ipaas-by-ai/.github/workflows/terraform-ci.yaml`

**Rationale**: 
- One set of workflows serves ALL projects in the monorepo
- Projects are selected via `workflow_dispatch` input at runtime
- No duplication of workflow code across projects
- Centralized workflow management and updates

---

## Existing Workflow Detection & Handling

⚠️ **Before creating any workflows, the assistant MUST check for existing files**

**Detection Process**:
1. Check if `.github/workflows/` directory exists
2. Scan for existing workflow files (terraform-ci.yaml, deploy.yaml, destroy.yaml, apim-*.yaml)
3. If ANY workflows exist:
   - **HALT** workflow generation
   - **DISPLAY** list of existing workflows found
   - **PROMPT** user with options:
     - `Overwrite all` - Replace all existing workflows with new ones
     - `Merge` - Keep existing, only add missing workflows
     - `Skip` - Cancel generation
     - `Review` - Show diff of what would change
   - **WAIT** for user response before proceeding

**Example Prompt**:
```
⚠️ Existing workflows detected in .github/workflows/:
- terraform-ci.yaml
- deploy.yaml

How would you like to proceed?
1. Overwrite all existing workflows
2. Merge (add missing: destroy.yaml, apim-*.yaml)
3. Skip workflow generation
4. Review differences first

Please select an option (1-4):
```

**Safety Rule**: NEVER overwrite existing workflows without explicit user confirmation.

---

## Prerequisites

Before using generated workflows:
- [ ] GitHub repository created
- [ ] Cloud provider credentials/service principal configured
- [ ] Terraform backend (Storage Account/S3/GCS) provisioned
- [ ] Branch protection rules on `main` (recommended)
- [ ] `.github/workflows/` directory exists at repo root (will be created if missing)
- [ ] Multiple projects exist in workspace with structure: `{project-name}/env/{environment}/`
- [ ] Review existing workflows (if any) before generation to avoid conflicts

---

## Quick Reference

### Standard Workflows (Always Generated)
| Workflow | Trigger | Duration | Input | Approval |
|----------|---------|----------|-------|----------|
| terraform-ci | PR OR Manual | 3-5 min | project_name (required) | No |
| deploy | Manual Only | 5-10 min | project_name + environment (both required) | Optional |
| destroy | Manual Only | 5-10 min | project_name + environment (both required) | Required |

### APIM Workflows (Generated if APIM detected)
| Workflow | Trigger | Duration | Input | Approval |
|----------|---------|----------|-------|----------|
| apim-ci | PR OR Manual | 3-5 min | project_name (APIM projects only) | No |
| apim-deploy | Manual Only | 5-10 min | project_name + environment (APIM projects only) | Optional |
| apim-destroy | Manual Only | 5-10 min | project_name + environment (APIM projects only) | Required |

**Workflow Location**: All workflows reside in `.github/workflows/` at repository root.

**Total Workflows**:
- Projects WITHOUT APIM: 3 workflows
- Projects WITH APIM: 6 workflows (3 standard + 3 APIM)

---

**Version**: 1.3  
**Compatible**: Terraform ≥1.5.0, GitHub Actions  
**Supports**: Azure, AWS, GCP  
**Architecture**: Monorepo with centralized workflows serving multiple projects  
**APIM Support**: Automatic detection and dedicated workflow generation  
**Safety**: Existing workflow detection with user confirmation before overwrite
