# Project iPaaS 3 - Azure Integration Services Platform

Production-ready Azure Integration Services (AIS) platform built with Terraform, featuring APIM, Logic Apps, Service Bus, and Key Vault.

## Platform Overview

This platform provides a complete integration solution with:

- **API Management** - StandardV2 for API gateway and management
- **Service Bus** - Central message broker with `inbound-queue`
- **5 Logic Apps Standard** - Distributed across 2 App Service Plans (WS1)
- **Key Vault** - Centralized secrets management with RBAC
- **Storage Account** - Platform configuration tables
- **Observability** - Log Analytics + Application Insights

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Resource Group                            │
│                  rg-dev-clz-ipaas3-01                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐    ┌─────────────────┐                    │
│  │    APIM      │    │   Service Bus   │                    │
│  │ StandardV2_1 │───▶│   Standard      │                    │
│  └──────────────┘    │ inbound-queue   │                    │
│                      └─────────────────┘                    │
│                              │                               │
│                              ▼                               │
│  ┌─────────────────────────────────────────┐                │
│  │         5 Logic Apps Standard           │                │
│  ├─────────────────────────────────────────┤                │
│  │  App Service Plan 1 (WS1)               │                │
│  │  ├─ Logic App 01                        │                │
│  │  ├─ Logic App 02                        │                │
│  │  └─ Logic App 03                        │                │
│  │                                          │                │
│  │  App Service Plan 2 (WS1)               │                │
│  │  ├─ Logic App 04                        │                │
│  │  └─ Logic App 05                        │                │
│  └─────────────────────────────────────────┘                │
│                              │                               │
│                              ▼                               │
│  ┌──────────────┐    ┌─────────────────┐                    │
│  │  Key Vault   │    │   Storage       │                    │
│  │   (RBAC)     │    │   (Config)      │                    │
│  └──────────────┘    └─────────────────┘                    │
│                                                               │
│  ┌──────────────┐    ┌─────────────────┐                    │
│  │Log Analytics │───▶│ App Insights    │                    │
│  └──────────────┘    └─────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

## Resource Naming

All resources follow the pattern: `<service>-<env>-<org>-<project>-<instance>`

**Abbreviations:**
- `env`: `dev`, `test`, `stg`, `prod`
- `org`: `clz` (Cellenza)
- `project`: `ipaas3`
- `instance`: `01`, `02`, etc.

**Examples:**
- API Management: `apim-dev-clz-ipaas3-01`
- Service Bus: `sb-dev-clz-ipaas3-01`
- Logic Apps: `logic-dev-clz-ipaas3-01` through `logic-dev-clz-ipaas3-05`
- Key Vault: `kv-dev-clz-ipaas3-01`
- Storage (config): `stcfgdevclzipaas301`

## Project Structure

```
project-ipaas3/
├── modules/                    # Reusable Terraform modules
│   ├── apim/                   # API Management module
│   ├── app_insights/           # Application Insights module
│   ├── keyvault/               # Key Vault module
│   ├── log_analytics/          # Log Analytics module
│   ├── logicapp/               # Logic App Standard module
│   ├── servicebus/             # Service Bus module
│   └── storage/                # Storage Account module
│
├── env/dev/                    # Dev environment configuration
│   ├── main.tf                 # Main platform deployment
│   ├── variables.tf            # Variable definitions
│   ├── outputs.tf              # Output values
│   ├── locals.tf               # Local values
│   ├── dev.tfvars              # Dev-specific values
│   ├── backend.tfvars          # Backend state config
│   └── RUNBOOK.md              # Deployment runbook
│
├── apim/                       # APIM separate deployment
│   ├── main.tf                 # APIM deployment
│   ├── variables.tf            # Variable definitions
│   ├── outputs.tf              # Output values
│   ├── dev.tfvars              # Dev-specific values
│   ├── backend.tfvars          # APIM backend config
│   └── README.md               # APIM deployment guide
│
└── README.md                   # This file
```

## Quick Start

### Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** v1.5.0+ installed
3. **Azure Subscription** with Contributor access
4. **Backend Storage** exists: `stocommoniac01` in `rg-common-iac-01`

### Deployment (2 Steps)

#### Step 1: Deploy Main Platform

```powershell
cd env/dev

# Initialize
terraform init -backend-config=backend.tfvars

# Plan
terraform plan -var-file=dev.tfvars -out=plan.tfplan

# Apply (8-12 minutes)
terraform apply plan.tfplan
```

#### Step 2: Deploy APIM

```powershell
cd ../../apim

# Initialize
terraform init -backend-config=backend.tfvars

# Plan
terraform plan -var-file=dev.tfvars -out=plan.tfplan

# Apply (25-30 minutes)
terraform apply plan.tfplan
```

### Verification

```powershell
# List all resources
az resource list --resource-group rg-dev-clz-ipaas3-01 --output table

# Test Service Bus
az servicebus queue show --resource-group rg-dev-clz-ipaas3-01 `
  --namespace-name sb-dev-clz-ipaas3-01 `
  --name inbound-queue

# Check APIM gateway
az apim show --name apim-dev-clz-ipaas3-01 `
  --resource-group rg-dev-clz-ipaas3-01 `
  --query gatewayUrl -o tsv
```

## Services Details

### API Management (StandardV2)

- **SKU:** StandardV2_1 (production-ready, auto-scaling)
- **Capacity:** 1 unit
- **Features:** API gateway, developer portal, policies, monitoring
- **Deployment:** Separate from main platform (25-30 min)

### Service Bus (Standard)

- **SKU:** Standard (supports topics, queues, sessions)
- **Queue:** `inbound-queue` with dead-lettering enabled
- **Max Delivery Count:** 10
- **Lock Duration:** 5 minutes
- **Message TTL:** 14 days

### Logic Apps Standard

- **Count:** 5 Logic Apps
- **Distribution:**
  - Plan 1 (WS1): Logic Apps 01, 02, 03
  - Plan 2 (WS1): Logic Apps 04, 05
- **Runtime:** Node.js v18, Functions runtime v4
- **Connectivity:** Managed identity to Service Bus and Key Vault
- **Storage:** Dedicated storage account per Logic App

### Key Vault

- **SKU:** Standard
- **Authorization:** RBAC (no access policies)
- **Soft Delete:** 7 days retention
- **Purge Protection:** Disabled (dev environment)
- **Secrets:** Service Bus connection, Storage config connection

### Storage Account (Config)

- **Purpose:** Platform configuration tables
- **SKU:** Standard_LRS
- **Tables:** `platformconfig`, `metadata`
- **Access:** Managed identity from Logic Apps

### Observability

- **Log Analytics:** 30-day retention
- **Application Insights:** Integrated with all Logic Apps
- **Diagnostics:** All services send logs to Log Analytics

## Security

### Managed Identities

All services use **system-assigned managed identities** (no service principals):
- Logic Apps → Service Bus (Data Receiver role)
- Logic Apps → Key Vault (Secrets User role)
- Terraform → Key Vault (Secrets Officer role - auto-assigned)

### RBAC Roles

| Principal | Role | Scope | Purpose |
|-----------|------|-------|---------|
| Terraform SP | Key Vault Secrets Officer | Key Vault | Create/manage secrets during deployment |
| Logic App 01-05 | Azure Service Bus Data Receiver | Service Bus | Read messages from queues |
| Logic App 01-05 | Key Vault Secrets User | Key Vault | Read secrets at runtime |

### Secret Management

- **No secrets in code** - All sensitive values stored in Key Vault
- **No connection strings** - Managed identity authentication preferred
- **Sensitive outputs** - Marked as `sensitive = true` in Terraform
- **State encryption** - Backend storage with access keys

## GitHub Actions

This project includes CI/CD workflows:

1. **terraform-platform-deploy.yml** - Deploy main platform
2. **terraform-apim-deploy.yml** - Deploy APIM separately
3. **terraform-platform-destroy.yml** - Destroy main platform
4. **terraform-apim-destroy.yml** - Destroy APIM only

All workflows require manual trigger with confirmation.

## Cost Estimation (Monthly - Dev Environment)

| Service | SKU | Estimated Cost |
|---------|-----|----------------|
| APIM | StandardV2_1 | ~$650 USD |
| Service Bus | Standard | ~$10 USD |
| Logic Apps (5x) | WS1 | ~$200 USD (5 x $40) |
| Storage (6x) | Standard_LRS | ~$6 USD |
| Key Vault | Standard | ~$1 USD |
| Log Analytics | 30-day retention | ~$50 USD |
| App Insights | Basic | Included |

**Total:** ~$920 USD/month

💡 **Tip:** Delete APIM in non-working hours to save ~70% of costs.

## Troubleshooting

### Key Vault Access Denied (403)

**Cause:** Terraform service principal missing "Key Vault Secrets Officer" role

**Solution:** Already auto-assigned in `main.tf`. Wait 60 seconds for role propagation and retry.

### APIM Deployment Timeout

**Cause:** APIM provisioning takes 25-30 minutes by design

**Solution:** Check Azure Portal for status. If > 45 minutes, check quota limits.

### Logic App Storage Connection Error

**Cause:** AzureWebJobsStorage manually configured in app_settings

**Solution:** Remove from app_settings. It's auto-configured via `storage_account_name` parameter.

### Service Bus Connection Failed

**Cause:** Using connection string instead of managed identity

**Solution:** Use `SERVICEBUS_NAMESPACE_FQDN` app setting (already configured).

## Maintenance

### Update Resources

```powershell
# Update main platform
cd env/dev
terraform plan -var-file=dev.tfvars -out=plan.tfplan
terraform apply plan.tfplan

# Update APIM
cd ../../apim
terraform plan -var-file=dev.tfvars -out=plan.tfplan
terraform apply plan.tfplan
```

### Add New Logic App

1. Add storage module in `env/dev/main.tf`
2. Add Logic App module with new instance number
3. Add RBAC assignments
4. Run `terraform apply`

### Destroy Resources

```powershell
# Destroy APIM first (optional - keeps main platform)
cd apim
terraform destroy -var-file=dev.tfvars

# Destroy main platform (destroys everything except APIM)
cd ../env/dev
terraform destroy -var-file=dev.tfvars
```

## Documentation

- **Deployment Runbook:** `env/dev/RUNBOOK.md`
- **APIM Guide:** `apim/README.md`
- **Module READMEs:** `modules/*/README.md`
- **Build Instructions:** `.github/instructions/build-ais-platform.instructions.md`

## Support

For issues or questions:
1. Check `env/dev/RUNBOOK.md` troubleshooting section
2. Review module READMEs for service-specific guidance
3. Check Azure Portal for resource provisioning state
4. Review Terraform plan output for errors

## License

Internal use only - Cellenza

## Version

- **Platform Version:** 1.0.0
- **Terraform:** >= 1.5.0
- **Azure Provider:** ~> 4.0
- **Created:** 2025
