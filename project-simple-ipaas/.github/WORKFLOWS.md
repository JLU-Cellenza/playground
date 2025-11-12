# GitHub Actions Workflows - Quick Reference

## Available Workflows

### 1. Terraform CI (terraform-ci.yaml)
**Purpose:** Validate Terraform on pull requests  
**Trigger:** Automatic on PR to `main` or `develop`  
**Duration:** ~3-5 minutes  
**Actions:**
- Format check (`terraform fmt`)
- Validation (`terraform validate`)
- Plan generation
- Security scanning (TFLint + Checkov)
- PR comment with results

---

### 2. Deploy Infrastructure (deploy.yaml)
**Purpose:** Deploy infrastructure to Azure  
**Trigger:** 
- Automatic on push to `main`
- Manual via Actions UI

**Duration:** ~5-10 minutes  
**Environments:** `dev`, `prd`  
**Actions:**
- Terraform init (remote backend)
- Terraform plan
- Terraform apply (if changes)
- Save outputs as artifacts

**Manual Trigger:**
```
Actions → Deploy Infrastructure → Run workflow
  Environment: [dev/prd]
  → Run workflow
```

---

### 3. Destroy Infrastructure (destroy.yaml)
**Purpose:** Tear down infrastructure  
**Trigger:** Manual only  
**Duration:** ~5-10 minutes  
**Environments:** `dev`, `prd`  
**Approval:** Required via environment protection  
**Actions:**
- Validate "destroy" confirmation
- Plan destruction
- Manual approval gate
- Execute destroy

**Manual Trigger:**
```
Actions → Destroy Infrastructure → Run workflow
  Environment: [dev/prd]
  Confirmation: "destroy"
  → Run workflow → Approve
```

---

## Required GitHub Secrets

| Secret | Description | Example |
|--------|-------------|---------|
| `AZURE_CLIENT_ID` | Service Principal Client ID | `a1b2c3d4-...` |
| `AZURE_CLIENT_SECRET` | Service Principal Secret | `********` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `12345678-...` |
| `AZURE_TENANT_ID` | Azure AD Tenant ID | `87654321-...` |
| `TF_BACKEND_RESOURCE_GROUP` | State storage RG | `rg-terraform-state` |
| `TF_BACKEND_STORAGE_ACCOUNT` | State storage account | `sttfstate123456` |
| `TF_BACKEND_CONTAINER` | State container | `tfstate` |
| `TF_BACKEND_KEY` | State file key | `simple-ipaas-dev.tfstate` |

---

## Common Workflows

### Deploy Development Environment
```
1. Make changes in feature branch
2. Open PR → terraform-ci.yaml runs automatically
3. Review plan in PR comments
4. Merge to main → deploy.yaml runs automatically
```

### Manual Deployment
```
Actions → Deploy Infrastructure
  Environment: dev
  → Run workflow
```

### Destroy Development (cleanup)
```
Actions → Destroy Infrastructure
  Environment: dev
  Confirmation: "destroy"
  → Run workflow
  → Wait for approval
  → Infrastructure destroyed
```

---

## Workflow Files Location

```
.github/
└── workflows/
    ├── terraform-ci.yaml      # PR validation
    ├── deploy.yaml            # Deployment
    └── destroy.yaml           # Destruction
```

---

## Artifacts

Workflows generate artifacts that can be downloaded:

| Workflow | Artifact | Retention | Contents |
|----------|----------|-----------|----------|
| terraform-ci | `terraform-plan-{pr}` | 30 days | Terraform plan |
| deploy | `terraform-outputs-{env}-{run}` | 90 days | JSON outputs |
| destroy | `destroy-plan-{env}` | 7 days | Destroy plan |

**Download:** Actions → Workflow run → Artifacts section

---

## Troubleshooting

### "Backend initialization failed"
✅ Verify backend secrets in GitHub
✅ Check Azure Storage Account exists
✅ Verify Service Principal has access

### "Authentication failed"
✅ Verify Service Principal credentials
✅ Check subscription ID is correct
✅ Ensure SP has Contributor role

### "State lock"
✅ Wait for other workflows to complete
✅ Check for failed workflows
✅ Force unlock via local Terraform if needed

### "Plan shows unexpected changes"
✅ Check for manual changes in Azure Portal
✅ Review recent deployments
✅ Run `terraform plan` locally to compare

---

## Best Practices

✅ Always create PR for changes (triggers validation)  
✅ Review plan before merging  
✅ Use manual deployment for first-time setup  
✅ Destroy dev environment when not in use  
✅ Require approval for production changes  
✅ Monitor workflow runs for failures  
✅ Keep secrets rotated regularly  

---

## Next Steps

1. **Setup:** Follow [DEPLOYMENT-SETUP.md](DEPLOYMENT-SETUP.md)
2. **Deploy:** Use workflows to deploy infrastructure
3. **Monitor:** Check Azure Portal for resources
4. **Iterate:** Make changes via PR workflow

---

**Full Documentation:** [DEPLOYMENT-SETUP.md](DEPLOYMENT-SETUP.md)
