# Quick Start - Deploy via GitHub Actions

Get your Simple iPaaS platform running in Azure using GitHub Actions in **15 minutes**.

---

## Prerequisites

- Azure subscription
- GitHub account
- Azure CLI installed

---

## Step 1: Create Azure Service Principal (5 min)

```bash
# Login to Azure
az login

# Create Service Principal
az ad sp create-for-rbac \
  --name "sp-github-simple-ipaas" \
  --role Contributor \
  --scopes /subscriptions/<YOUR_SUBSCRIPTION_ID> \
  --sdk-auth
```

**Save the output JSON** - you'll need it for GitHub Secrets.

---

## Step 2: Create Terraform State Storage (3 min)

```bash
# Variables (change UNIQUE_ID to something unique)
UNIQUE_ID="$(date +%s)"
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="sttfstate${UNIQUE_ID}"
LOCATION="francecentral"

# Create resources
az group create --name $RESOURCE_GROUP --location $LOCATION

az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name $STORAGE_ACCOUNT

# Display values for GitHub Secrets
echo "TF_BACKEND_RESOURCE_GROUP: $RESOURCE_GROUP"
echo "TF_BACKEND_STORAGE_ACCOUNT: $STORAGE_ACCOUNT"
echo "TF_BACKEND_CONTAINER: tfstate"
```

---

## Step 3: Configure GitHub Secrets (5 min)

Go to your GitHub repository: **Settings → Secrets and variables → Actions → New repository secret**

Add these 8 secrets:

| Secret Name | Get Value From |
|-------------|---------------|
| `AZURE_CLIENT_ID` | Service Principal JSON (`clientId`) |
| `AZURE_CLIENT_SECRET` | Service Principal JSON (`clientSecret`) |
| `AZURE_SUBSCRIPTION_ID` | Service Principal JSON (`subscriptionId`) |
| `AZURE_TENANT_ID` | Service Principal JSON (`tenantId`) |
| `TF_BACKEND_RESOURCE_GROUP` | From Step 2 output |
| `TF_BACKEND_STORAGE_ACCOUNT` | From Step 2 output |
| `TF_BACKEND_CONTAINER` | `tfstate` |
| `TF_BACKEND_KEY` | `simple-ipaas-dev.tfstate` |

**Tip:** Use GitHub CLI to add secrets faster:
```bash
gh secret set AZURE_CLIENT_ID --body "<value>"
gh secret set AZURE_CLIENT_SECRET --body "<value>"
# ... repeat for all secrets
```

---

## Step 4: Push Code to GitHub (1 min)

```bash
cd project-simple-ipaas
git add .
git commit -m "Add GitHub Actions CI/CD"
git push origin main
```

---

## Step 5: Deploy Infrastructure (1 min)

1. Go to GitHub repository
2. Click **Actions** tab
3. Select **Deploy Infrastructure** workflow
4. Click **Run workflow**
5. Select environment: **dev**
6. Click **Run workflow**

⏳ Wait 5-10 minutes for deployment to complete.

---

## ✅ Verify Deployment

### In GitHub:
- Actions → Deploy Infrastructure → Latest run → ✅ Success
- Download **terraform-outputs** artifact to see resource details

### In Azure Portal:
```
Resource Groups → rg-dev-<org>-simpleipaas
```

You should see:
- ✅ Storage Account
- ✅ Service Bus Namespace (with `inbound` queue)
- ✅ Key Vault
- ✅ Logic App Standard
- ✅ App Service Plan

---

## 🎉 Success! What's Next?

### Test the Platform

1. **Send a message to Service Bus:**
   ```bash
   # Get connection string from Key Vault
   az keyvault secret show \
     --vault-name kv-dev-<org>-simpleipaas-01 \
     --name servicebus-connection-string \
     --query value -o tsv
   
   # Use Azure Portal or SDK to send test message to 'inbound' queue
   ```

2. **Access Logic App:**
   ```bash
   # Get Logic App URL
   az logicapp show \
     --resource-group rg-dev-<org>-simpleipaas \
     --name loa-dev-<org>-simpleipaas-01 \
     --query defaultHostName -o tsv
   ```

### Make Changes

1. Create a feature branch
2. Modify Terraform files
3. Open Pull Request
4. Review plan in PR comments
5. Merge → Auto-deploys

### Clean Up (Save Costs)

When done testing:
```
Actions → Destroy Infrastructure
  Environment: dev
  Confirmation: "destroy"
  → Run workflow
```

---

## 📚 Next Steps

- **Configure workflows:** [DEPLOYMENT-SETUP.md](DEPLOYMENT-SETUP.md)
- **Understand workflows:** [.github/WORKFLOWS.md](.github/WORKFLOWS.md)
- **Setup checklist:** [SETUP-CHECKLIST.md](SETUP-CHECKLIST.md)
- **Manual deployment:** [env/dev/RUNBOOK.md](env/dev/RUNBOOK.md)

---

## 🆘 Troubleshooting

**"Backend initialization failed"**
- Verify all 8 GitHub Secrets are configured
- Check storage account name is correct (no typos)

**"Authentication failed"**
- Verify Service Principal JSON was copied correctly
- Test: `az login --service-principal --username $AZURE_CLIENT_ID --password $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID`

**Workflow stuck or failed**
- Check Actions logs for specific error
- Verify Azure subscription has available quota
- Try manual deployment via local Terraform

**Need help?**
- Review workflow logs in detail
- Check [DEPLOYMENT-SETUP.md](DEPLOYMENT-SETUP.md) troubleshooting section
- Verify [SETUP-CHECKLIST.md](SETUP-CHECKLIST.md) items

---

**Total Time:** ~15 minutes  
**Cost:** ~$215/month (destroy when not in use)  
**Region:** East US (configurable in `dev.tfvars`)
