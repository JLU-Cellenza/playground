# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Prerequisites Installation

1. **Install Terraform**
   ```powershell
   # Using Chocolatey
   choco install terraform
   
   # Or download from: https://www.terraform.io/downloads
   ```

2. **Install Azure CLI**
   ```powershell
   # Using Chocolatey
   choco install azure-cli
   
   # Or download from: https://aka.ms/installazurecliwindows
   ```

3. **Verify Installation**
   ```powershell
   terraform version  # Should show >= 1.5.0
   az --version       # Should show Azure CLI
   ```

### First Deployment (Dev Environment)

1. **Login to Azure**
   ```powershell
   az login
   
   # Set your subscription
   $env:ARM_SUBSCRIPTION_ID = "YOUR-SUBSCRIPTION-ID"
   ```

2. **Create Resource Group**
   ```powershell
   az group create `
     --name rg-dev-cellenza-mvpipaas-01 `
     --location francecentral
   ```

3. **Configure Terraform**
   ```powershell
   cd env/dev
   
   # Copy and edit tfvars
   cp dev.tfvars.example dev.tfvars
   notepad dev.tfvars
   ```
   
   **Update these values in `dev.tfvars`:**
   - `apim_publisher_email` - Your valid email address

4. **Initialize & Deploy**
   ```powershell
   # Initialize Terraform
   terraform init
   
   # Format code
   terraform fmt -recursive
   
   # Validate configuration
   terraform validate
   
   # Plan deployment
   terraform plan -var-file=dev.tfvars -out=plan.tfplan
   
   # Review the plan, then apply
   terraform apply plan.tfplan
   ```

5. **Wait for APIM** ⏰
   - API Management takes **30-45 minutes** to deploy
   - Other resources deploy in 5-10 minutes
   - Monitor progress in Azure Portal

6. **Get Outputs**
   ```powershell
   # View all outputs
   terraform output
   
   # Get specific URLs
   terraform output function_app_url
   terraform output apim_gateway_url
   terraform output apim_developer_portal_url
   ```

## 📁 Project Structure

```
project-demo-ipaas-by-ai/
├── modules/              # Reusable Terraform modules
│   ├── apim/            # API Management
│   ├── app_insights/    # Application Insights
│   ├── function_app/    # Azure Functions
│   ├── log_analytics/   # Log Analytics
│   ├── logicapp/        # Logic Apps Standard
│   ├── servicebus/      # Service Bus
│   └── storage/         # Storage Accounts
├── env/
│   ├── dev/             # Development environment
│   └── prd/             # Production environment
├── ARCHITECTURE.md      # System architecture
├── CHANGELOG.md         # Version history
└── README.md            # This file
```

## 🏗️ What Gets Deployed

| Resource | Count | Purpose |
|----------|-------|---------|
| Resource Group | 1 | Container for all resources |
| Log Analytics | 1 | Centralized logging |
| App Insights | 1 | APM monitoring |
| Storage Accounts | 4 | Function, 2x Logic Apps, Platform configs |
| Service Bus | 1 | Message broker (with "inbound" queue) |
| Function App | 1 | Custom connectors & helpers |
| Logic Apps | 2 | Workflow orchestration |
| API Management | 1 | API gateway |
| RBAC Roles | ~15 | Service-to-service authorization |

**Total Resources**: ~35 resources

## 🔐 Security Features

- ✅ All services use Managed Identities
- ✅ RBAC for service-to-service communication
- ✅ TLS 1.2 minimum
- ✅ Diagnostic logs to Log Analytics
- ⚠️ Public access enabled (demo only - disable for production)

## 💰 Cost Estimate

**Development Environment**: ~€250-280/month
- APIM Developer: ~€42
- Service Bus Standard: ~€10
- 2x Logic Apps (WS1): ~€160
- Function App (Consumption): ~€5-10
- Storage (4x): ~€20
- Logging: ~€10-20

## 🧪 Testing Your Deployment

### 1. Test Function App
```powershell
$functionUrl = terraform output -raw function_app_url
Invoke-WebRequest -Uri $functionUrl -UseBasicParsing
```

### 2. Check Service Bus Queue
```powershell
az servicebus queue show `
  --namespace-name sb-dev-cellenza-mvpipaas-01 `
  --name inbound `
  --resource-group rg-dev-cellenza-mvpipaas-01
```

### 3. Access APIM Developer Portal
```powershell
$portalUrl = terraform output -raw apim_developer_portal_url
Start-Process $portalUrl
```

### 4. View Logs in Log Analytics
```powershell
# Get workspace ID
$workspaceId = terraform output -raw log_analytics_workspace_id

# Open in portal
az monitor log-analytics workspace show --ids $workspaceId
```

## 📊 Monitoring

Access monitoring dashboards:
- **Azure Portal**: [https://portal.azure.com](https://portal.azure.com)
- **Log Analytics**: Run Kusto queries (see RUNBOOK.md)
- **App Insights**: View application performance
- **APIM Analytics**: Gateway logs and API metrics

## 🔄 Making Changes

```powershell
# 1. Edit .tf files or tfvars
notepad env/dev/main.tf

# 2. Plan changes
terraform plan -var-file=dev.tfvars -out=plan.tfplan

# 3. Review plan carefully
terraform show plan.tfplan

# 4. Apply changes
terraform apply plan.tfplan
```

## 🗑️ Clean Up

⚠️ **Warning**: This deletes ALL resources

```powershell
terraform plan -destroy -var-file=dev.tfvars -out=destroy.tfplan
terraform apply destroy.tfplan
```

## 🆘 Common Issues

### Storage Account Name Too Long
**Error**: Name exceeds 24 characters  
**Fix**: Shorten project name in tfvars

### APIM Deployment Timeout
**Error**: Deployment takes > 45 minutes  
**Fix**: This is normal for APIM; wait or check Azure Portal for errors

### Managed Identity RBAC Not Working
**Error**: Service can't access Service Bus  
**Fix**: Wait 5-10 minutes for Azure AD propagation, then restart service

### Terraform State Lock
**Error**: State file locked  
**Fix**: Release lock in Azure Portal or wait for timeout

## 📚 Next Steps

1. **Review Architecture**: Read [ARCHITECTURE.md](ARCHITECTURE.md)
2. **Read Runbook**: See [env/dev/RUNBOOK.md](env/dev/RUNBOOK.md)
3. **Deploy Workflows**: Add Logic App workflows
4. **Configure APIM**: Add APIs and policies
5. **Deploy Functions**: Add custom connector code
6. **Set Up Monitoring**: Create alerts and dashboards
7. **Production Deployment**: Use `env/prd/` configuration

## 🔗 Useful Links

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Logic Apps](https://learn.microsoft.com/en-us/azure/logic-apps/)
- [Azure Service Bus](https://learn.microsoft.com/en-us/azure/service-bus-messaging/)
- [Azure API Management](https://learn.microsoft.com/en-us/azure/api-management/)
- [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/)

## 📞 Support

For issues or questions:
- Check [RUNBOOK.md](env/dev/RUNBOOK.md) for troubleshooting
- Review [CHANGELOG.md](CHANGELOG.md) for version history
- Contact: Cellenza Integration Team

---

**Version**: 1.0.0  
**Last Updated**: 2025-11-06  
**Maintained By**: Cellenza
