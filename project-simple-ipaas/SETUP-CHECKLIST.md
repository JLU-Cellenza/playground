# GitHub Actions Setup Checklist

Use this checklist to ensure your GitHub Actions CI/CD is properly configured.

## ✅ Prerequisites

- [ ] GitHub repository created for `project-simple-ipaas`
- [ ] Azure subscription with admin access
- [ ] Azure CLI installed (`az --version`)
- [ ] Terraform >= 1.5.0 installed (`terraform --version`)
- [ ] GitHub CLI installed (optional) (`gh --version`)

---

## ✅ Azure Setup

### Service Principal
- [ ] Created Service Principal with Contributor role
- [ ] Saved `clientId` (AZURE_CLIENT_ID)
- [ ] Saved `clientSecret` (AZURE_CLIENT_SECRET)
- [ ] Saved `subscriptionId` (AZURE_SUBSCRIPTION_ID)
- [ ] Saved `tenantId` (AZURE_TENANT_ID)
- [ ] Tested authentication with `az login --service-principal`

**Commands:**
```bash
az ad sp create-for-rbac \
  --name "sp-github-simple-ipaas" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```

### Terraform State Backend
- [ ] Created resource group for state storage
- [ ] Created Storage Account (globally unique name)
- [ ] Created blob container named `tfstate`
- [ ] Verified storage account access
- [ ] Saved resource group name
- [ ] Saved storage account name
- [ ] Saved container name

**Commands:**
```bash
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="sttfstate$(date +%s)"  # Unique name
CONTAINER_NAME="tfstate"
LOCATION="francecentral"

az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --sku Standard_LRS

az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME
```

---

## ✅ GitHub Repository Setup

### Code Push
- [ ] Cloned repository locally
- [ ] Workflows exist in `.github/workflows/`
- [ ] Committed all files
- [ ] Pushed to GitHub

**Commands:**
```bash
cd project-simple-ipaas
git add .github/
git add DEPLOYMENT-SETUP.md
git add README.md
git commit -m "Add GitHub Actions CI/CD workflows"
git push origin main
```

### GitHub Secrets
- [ ] Added `AZURE_CLIENT_ID`
- [ ] Added `AZURE_CLIENT_SECRET`
- [ ] Added `AZURE_SUBSCRIPTION_ID`
- [ ] Added `AZURE_TENANT_ID`
- [ ] Added `TF_BACKEND_RESOURCE_GROUP`
- [ ] Added `TF_BACKEND_STORAGE_ACCOUNT`
- [ ] Added `TF_BACKEND_CONTAINER`
- [ ] Added `TF_BACKEND_KEY` (e.g., `simple-ipaas-dev.tfstate`)

**Via GitHub UI:**
```
Settings → Secrets and variables → Actions → New repository secret
```

**Via GitHub CLI:**
```bash
gh secret set AZURE_CLIENT_ID --body "<value>"
gh secret set AZURE_CLIENT_SECRET --body "<value>"
gh secret set AZURE_SUBSCRIPTION_ID --body "<value>"
gh secret set AZURE_TENANT_ID --body "<value>"
gh secret set TF_BACKEND_RESOURCE_GROUP --body "rg-terraform-state"
gh secret set TF_BACKEND_STORAGE_ACCOUNT --body "<storage-account-name>"
gh secret set TF_BACKEND_CONTAINER --body "tfstate"
gh secret set TF_BACKEND_KEY --body "simple-ipaas-dev.tfstate"
```

### GitHub Environments (Recommended)
- [ ] Created `dev` environment
- [ ] Created `prd` environment
- [ ] Created `dev-destroy` environment
- [ ] Created `prd-destroy` environment
- [ ] Configured required reviewers for `prd`
- [ ] Configured required reviewers for `prd-destroy`

**Steps:**
```
Settings → Environments → New environment
  Name: dev
  → Configure environment
```

For production environments:
```
Environment: prd
  ✅ Required reviewers: [Add team members]
  ✅ Wait timer: 0 minutes (or as needed)
  ✅ Deployment branches: main only
```

---

## ✅ Terraform Configuration

### Development Variables
- [ ] Reviewed `env/dev/dev.tfvars.example`
- [ ] Updated organization name
- [ ] Updated project name
- [ ] Updated Azure region
- [ ] Updated owner email
- [ ] Updated cost center
- [ ] Committed `env/dev/dev.tfvars` (if using committed vars)

**Important:** If using sensitive values, configure via GitHub environment variables instead.

### Production Variables (if applicable)
- [ ] Copied `env/prd/prd.tfvars.example` to `env/prd/prd.tfvars`
- [ ] Updated all production values
- [ ] Set `keyvault_purge_protection = true`
- [ ] Set appropriate storage replication (`GRS` or `ZRS`)
- [ ] Set appropriate Logic App SKU (`WS2` or `WS3`)
- [ ] Added separate backend key secret for production

---

## ✅ First Deployment

### Workflow Verification
- [ ] Workflows visible in Actions tab
- [ ] No syntax errors in workflow files
- [ ] Secrets properly configured (masked in logs)

### Initial Deploy
- [ ] Triggered manual deployment via Actions UI
- [ ] Workflow completed successfully
- [ ] Downloaded terraform outputs artifact
- [ ] Verified resources in Azure Portal

**Steps:**
```
Actions → Deploy Infrastructure → Run workflow
  Environment: dev
  → Run workflow
```

**Verify in Azure:**
- [ ] Resource Group created: `rg-dev-cellenza-simpleipaas`
- [ ] Storage Account created: `stdevcellenzasimpleipaas01`
- [ ] Service Bus namespace created: `svb-dev-cellenza-simpleipaas-01`
- [ ] Key Vault created: `kv-dev-cellenza-simpleipaas-01`
- [ ] Logic App created: `loa-dev-cellenza-simpleipaas-01`

---

## ✅ Testing Workflows

### PR Validation
- [ ] Created feature branch
- [ ] Made Terraform change
- [ ] Opened pull request
- [ ] CI workflow triggered automatically
- [ ] Plan posted as PR comment
- [ ] All checks passed

**Steps:**
```bash
git checkout -b test/workflow-validation
# Make a small change to env/dev/main.tf
git add .
git commit -m "Test: Verify CI workflow"
git push origin test/workflow-validation
# Open PR on GitHub
```

### Deployment Workflow
- [ ] Merged PR to main
- [ ] Deploy workflow triggered automatically
- [ ] Infrastructure updated (if changes)
- [ ] Outputs saved as artifact

### Destroy Workflow (Test)
- [ ] Triggered destroy workflow
- [ ] Typed "destroy" in confirmation
- [ ] Approval required (if configured)
- [ ] Infrastructure destroyed successfully
- [ ] Re-deployed for verification

---

## ✅ Security & Compliance

### Branch Protection
- [ ] Enabled branch protection on `main`
- [ ] Required PR reviews (recommended: 1+)
- [ ] Required status checks (CI workflow)
- [ ] No force pushes allowed
- [ ] No deletions allowed

**Steps:**
```
Settings → Branches → Add branch protection rule
  Branch name pattern: main
  ✅ Require a pull request before merging
  ✅ Require status checks to pass (select terraform-ci)
  ✅ Require branches to be up to date
```

### Security Scanning
- [ ] TFLint configured and running
- [ ] Checkov security scan active
- [ ] Reviewed security findings
- [ ] Fixed any critical issues

### Access Control
- [ ] Service Principal has minimum required permissions
- [ ] Production environment requires approval
- [ ] Secrets have appropriate access restrictions
- [ ] Audit logging enabled

---

## ✅ Documentation

- [ ] Read [DEPLOYMENT-SETUP.md](DEPLOYMENT-SETUP.md)
- [ ] Read [.github/WORKFLOWS.md](.github/WORKFLOWS.md)
- [ ] Read [env/dev/RUNBOOK.md](env/dev/RUNBOOK.md)
- [ ] Updated README with project-specific details
- [ ] Documented any custom configurations

---

## ✅ Ongoing Operations

### Regular Tasks
- [ ] Monitor workflow runs for failures
- [ ] Review Terraform drift (manual runs)
- [ ] Rotate Service Principal credentials quarterly
- [ ] Update Terraform provider versions
- [ ] Review and optimize costs
- [ ] Destroy dev environment when not in use

### Monitoring
- [ ] Set up Azure cost alerts
- [ ] Configure deployment notifications (Slack/Teams)
- [ ] Review Azure Activity Logs
- [ ] Monitor GitHub Actions usage/quotas

---

## 📊 Verification Commands

**Test Service Principal:**
```bash
az login --service-principal \
  --username $AZURE_CLIENT_ID \
  --password $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID

az account show
```

**Verify State Backend:**
```bash
az storage account show \
  --name <storage-account-name> \
  --resource-group rg-terraform-state
```

**Test GitHub Secrets (via workflow):**
```
Actions → Deploy Infrastructure → Run workflow (dry run)
```

**Check Resources:**
```bash
az group show --name rg-dev-cellenza-simpleipaas
az resource list --resource-group rg-dev-cellenza-simpleipaas --output table
```

---

## 🎉 Success Criteria

Your setup is complete when:

✅ All GitHub Secrets configured  
✅ Workflows run without errors  
✅ PR validation posts plan comments  
✅ Deployment creates Azure resources  
✅ Destroy workflow removes resources  
✅ Branch protection active on main  
✅ Environment approvals configured  
✅ Documentation reviewed  

---

## 🆘 Troubleshooting

If you encounter issues, check:

1. **GitHub Secrets:** Settings → Secrets → Verify all 8 secrets
2. **Service Principal:** Test authentication with `az login --service-principal`
3. **Storage Backend:** Verify storage account exists and is accessible
4. **Workflow Logs:** Actions → Failed run → View detailed logs
5. **Terraform State:** Check state file exists in Azure Storage
6. **Azure Resources:** Portal → Resource Groups → Verify resources

**Common Issues:**
- Missing secrets → Add via Settings → Secrets
- Invalid SP credentials → Regenerate with `az ad sp credential reset`
- State lock → Wait or force unlock locally
- Plan changes → Review drift in Azure Portal

---

## 📚 Additional Resources

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [DEPLOYMENT-SETUP.md](DEPLOYMENT-SETUP.md) - Full setup guide
- [.github/WORKFLOWS.md](.github/WORKFLOWS.md) - Workflows quick reference

---

**Setup Version:** 1.0  
**Last Updated:** November 12, 2025
