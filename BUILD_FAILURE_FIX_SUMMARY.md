# Build Failure Analysis & Fixes

## What Was Fixed

### 1. **Removed Default Environment Input** ✅
The workflows had `default: 'dev'` which could cause:
- Accidental deployments to wrong environment
- Confusion about which environment is selected
- Workflows attempting to use `prd` environment for `project-simple-ipaas` (which only has `dev`)

**Fix**: Now environment MUST be explicitly selected by user - no defaults.

---

## Most Likely Cause of Your Build Failure

Based on the project structure, your build failure was likely due to:

### **Scenario A: Missing GitHub Secrets** (Most Common)
```
Error: AZURERM_CLIENT_ID or ARM_CLIENT_ID environment variable is not set
```
**Solution**: Set up GitHub secrets (see GITHUB_ACTIONS_SETUP.md)

### **Scenario B: Missing Azure Infrastructure**
```
Error: Failed to get existing workspaces: InvalidResourceGroupName
```
**Solution**: Create Azure storage account and container (see GITHUB_ACTIONS_SETUP.md)

### **Scenario C: Environment Not Found**
```
Error: Project directory project-simple-ipaas/env/prd does not exist
```
**Solution**: `project-simple-ipaas` only has `dev`. Either:
- Select `dev` environment only
- Create `env/prd/` if production environment needed

### **Scenario D: Terraform State File Mismatch**
```
Error: Error acquiring the state lock
```
**Solution**: Backend storage account exists but key is wrong. Check `backend.tfvars` matches storage account configuration.

---

## Next Steps to Debug Your Specific Error

1. **Go to GitHub Actions tab**
2. **Find your failed workflow run**
3. **Click the workflow run**
4. **Expand job steps and look for red "X" mark**
5. **Read the error message**
6. **Match error to one of the scenarios above**

---

## What You Need to Do Now

### Step 1: Set Up GitHub Secrets
Follow instructions in `GITHUB_ACTIONS_SETUP.md`:
```
AZURE_CREDENTIALS = <JSON from az ad sp create-for-rbac>
TERRAFORM_APPLY = true
TERRAFORM_DESTROY = true
```

### Step 2: Create Azure Infrastructure
```bash
az group create -n rg-common-iac-01 -l francecentral
az storage account create -n stocommoniac01 -g rg-common-iac-01 -l francecentral --sku Standard_LRS
az storage container create -n terraform --account-name stocommoniac01
```

### Step 3: Verify Configuration Files
Check these files exist and are correct:
- `project-simple-ipaas/env/dev/backend.tfvars` - Has correct storage account details
- `project-simple-ipaas/env/dev/dev.tfvars` - Has all required variables
- `project-simple-ipaas/env/dev/terraform.tf` - Has correct provider config

### Step 4: Re-run Workflow
1. Go to Actions tab
2. Click "Terraform CI"
3. Click "Run workflow"
4. Select:
   - **project_name**: `project-simple-ipaas`
   - **environment**: `dev`
5. Click "Run workflow"

---

## Files Updated

✅ `.github/workflows/terraform-ci.yml` - Removed default environment
✅ `.github/workflows/terraform-deploy.yml` - Removed default environment
✅ `.github/workflows/terraform-destroy.yml` - Removed default environment
✅ `GITHUB_ACTIONS_SETUP.md` - Complete setup guide (NEW)
✅ `WORKFLOW_TROUBLESHOOTING.md` - Troubleshooting guide (NEW)

---

## Quick Checklist

- [ ] GitHub Secrets configured (AZURE_CREDENTIALS, TERRAFORM_APPLY, TERRAFORM_DESTROY)
- [ ] Azure resource group created (rg-common-iac-01)
- [ ] Azure storage account created (stocommoniac01)
- [ ] Azure container created (terraform)
- [ ] backend.tfvars has correct storage account details
- [ ] dev.tfvars has all required variables
- [ ] Workflow can access these files

If you check all boxes and re-run the workflow, it should work!

---

## Still Failing?

Share the error message from GitHub Actions and I can provide more specific help.

