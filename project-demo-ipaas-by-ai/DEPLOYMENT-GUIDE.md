# Infrastructure Management Guide

## 🚀 Deployment

### Deploy via GitHub CLI
```bash
# Deploy to dev
gh workflow run terraform-deploy.yml -f environment=dev -f confirm=YES

# Deploy to prd
gh workflow run terraform-deploy.yml -f environment=prd -f confirm=YES
```

### Deploy via GitHub UI
1. Go to: https://github.com/JLU-Cellenza/playground/actions/workflows/terraform-deploy.yml
2. Click **"Run workflow"**
3. Select environment: `dev` or `prd`
4. Type `YES` in confirm field
5. Click **"Run workflow"**

---

## 🔥 Destroy Infrastructure

⚠️ **WARNING: This is irreversible! All data will be lost!**

### Prerequisites
First, enable destroy capability:
```bash
gh secret set TERRAFORM_DESTROY --body "true"
```

### Destroy via GitHub CLI
```bash
# Destroy dev environment
gh workflow run terraform-destroy.yml -f environment=dev -f confirm=DESTROY

# Destroy prd environment
gh workflow run terraform-destroy.yml -f environment=prd -f confirm=DESTROY
```

### Destroy via GitHub UI
1. Go to: https://github.com/JLU-Cellenza/playground/actions/workflows/terraform-destroy.yml
2. Click **"Run workflow"**
3. Select environment: `dev` or `prd`
4. Type **`DESTROY`** (all caps) in confirm field
5. Click **"Run workflow"**

### After Destroy
Disable destroy for safety:
```bash
gh secret set TERRAFORM_DESTROY --body "false"
```

---

## 📊 Monitor Deployments

### Watch workflow progress
```bash
gh run watch
```

### List recent runs
```bash
# All workflows
gh run list --limit 5

# Deploy workflow only
gh run list --workflow=terraform-deploy.yml --limit 5

# Destroy workflow only
gh run list --workflow=terraform-destroy.yml --limit 5
```

### View specific run
```bash
gh run view <RUN_ID>
gh run view <RUN_ID> --log
```

---

## 🔐 Required Secrets

| Secret | Value | Purpose |
|--------|-------|---------|
| `AZURE_CREDENTIALS` | Service Principal JSON | Azure authentication |
| `TERRAFORM_APPLY` | `"true"` | Enable deployments |
| `TERRAFORM_DESTROY` | `"false"` (default) | Enable destroy (set to `"true"` only when needed) |

---

## 🛡️ Safety Features

### Deployment Protection
- ✅ Manual approval required
- ✅ Must type `YES` to confirm
- ✅ `TERRAFORM_APPLY` secret must be enabled

### Destroy Protection (Triple Safety)
- ⚠️ Must type `DESTROY` (exact, all caps) to confirm
- ⚠️ `TERRAFORM_DESTROY` secret must be explicitly enabled
- ⚠️ 5-second delay before execution
- ⚠️ Shows destroy plan before execution

---

## 📦 What Gets Deployed

### Core Infrastructure
- Resource Group (`rg-{env}-cellenza-mvpipaas-01`)
- Log Analytics Workspace (`la-{env}-cellenza-mvpipaas-01`)
- Application Insights (`appi-{env}-cellenza-mvpipaas-01`)

### Integration Services
- API Management (`apim-{env}-cellenza-mvpipaas-01`)
- Service Bus Namespace (`sb-{env}-cellenza-mvpipaas-01`)
  - Queue: `inbound`
- Logic App Workflow 01 (`loa-{env}-cellenza-mvpipaas-workflow-01`)
- Logic App Workflow 02 (`loa-{env}-cellenza-mvpipaas-workflow-02`)
- Function App (`func-{env}-cellenza-mvpipaas-helpers-01`)

### Storage Accounts
- Platform Storage (`stpl{env}mvpipaas01`)
  - Containers: `configurations`, `schemas`, `templates`
- Function Storage (`stfn{env}mvpipaas01`)
- Logic App 01 Storage (`stla{env}mvpipaas01`)
- Logic App 02 Storage (`stla{env}mvpipaas02`)

### Monitoring
- Diagnostic settings on all resources
- Logs sent to Log Analytics Workspace

### Security
- System-assigned managed identities
- RBAC role assignments
- Private endpoints (when configured)

---

## ⏱️ Estimated Times

- **Deployment**: 15-30 minutes (APIM takes the longest)
- **Destroy**: 10-15 minutes
- **CI Validation**: 2-3 minutes

---

## 🔍 Troubleshooting

### Check workflow logs
```bash
gh run view <RUN_ID> --log
```

### View Azure resources
```bash
az group show --name rg-dev-cellenza-mvpipaas-01
az resource list --resource-group rg-dev-cellenza-mvpipaas-01 --output table
```

### Check Terraform state
```bash
cd project-demo-ipaas-by-ai/env/dev
terraform init -backend-config=backend.tfvars
terraform state list
terraform show
```
