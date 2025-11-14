# Changelog - Project iPaaS 3

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-14

### Added

#### Platform Services
- **API Management** (StandardV2_1) - Production-ready API gateway
- **Service Bus** (Standard) - Central message broker with `inbound-queue`
- **5 Logic Apps Standard** - Distributed across 2 App Service Plans (WS1)
  - Plan 1: Logic Apps 01, 02, 03
  - Plan 2: Logic Apps 04, 05
- **Key Vault** - RBAC-based secrets management
- **Storage Account** - Platform configuration tables (`platformconfig`, `metadata`)
- **Log Analytics** - 30-day retention for centralized logging
- **Application Insights** - Integrated monitoring for all Logic Apps

#### Modules
- `modules/apim` - API Management module
- `modules/app_insights` - Application Insights module
- `modules/keyvault` - Key Vault module with RBAC
- `modules/log_analytics` - Log Analytics Workspace module
- `modules/logicapp` - Logic App Standard module (supports shared App Service Plans)
- `modules/servicebus` - Service Bus namespace with queues
- `modules/storage` - Storage Account module (blobs, tables, queues)

#### Security Features
- **Managed Identities** - System-assigned for all Logic Apps
- **RBAC Assignments** - Automated role assignments
  - Logic Apps → Service Bus (Data Receiver)
  - Logic Apps → Key Vault (Secrets User)
  - Terraform → Key Vault (Secrets Officer - auto-assigned)
- **Key Vault Secrets** - Service Bus and Storage connection strings
- **No Hardcoded Secrets** - All sensitive values in Key Vault or outputs marked sensitive

#### Infrastructure as Code
- **Terraform 1.5.0+** - Infrastructure automation
- **Azure Provider 4.0** - Required for Logic Apps Standard
- **Remote State** - Backend storage in Azure (`stocommoniac01`)
- **Separate APIM Deployment** - Isolated state file for independent lifecycle
- **Environment Overlays** - Dev environment configuration

#### Documentation
- `README.md` - Complete platform documentation
- `env/dev/RUNBOOK.md` - Deployment runbook with step-by-step instructions
- `apim/README.md` - APIM deployment guide
- Module READMEs - Documentation for each module
- `CHANGELOG.md` - This file

#### CI/CD
- GitHub Actions integration (`.github/workflows/terraform-apim-deploy.yml` updated)
- Manual deployment workflows with confirmation gates
- Environment-based deployments (dev, prd)

### Configuration

#### Naming Convention
- Pattern: `<service>-<env>-<org>-<project>-<instance>`
- Organization: `clz` (Cellenza)
- Project: `ipaas3`
- Environment: `dev`
- Examples:
  - APIM: `apim-dev-clz-ipaas3-01`
  - Service Bus: `sb-dev-clz-ipaas3-01`
  - Logic Apps: `logic-dev-clz-ipaas3-01` to `logic-dev-clz-ipaas3-05`
  - Key Vault: `kv-dev-clz-ipaas3-01`
  - Storage (config): `stcfgdevclzipaas301`

#### Naming Validation
- **Storage Account**: 3-24 chars, lowercase alphanumeric, 2-digit suffix
- **Key Vault**: 3-24 chars, alphanumeric + hyphens, 2-digit suffix
- All resources: Mandatory numeric instance suffix (01, 02, etc.)

#### Resource Group
- Name: `rg-dev-clz-ipaas3-01`
- Location: `francecentral`

#### Backend Configuration
- Storage Account: `stocommoniac01`
- Resource Group: `rg-common-iac-01`
- Container: `terraform`
- State Files:
  - Main Platform: `project-ipaas3-dev.tfstate`
  - APIM: `project-ipaas3-dev-apim.tfstate`

### Technical Details

#### App Service Plans
- **Plan 1** (asp-dev-clz-ipaas3-01): Hosts Logic Apps 01, 02, 03
- **Plan 2** (asp-dev-clz-ipaas3-02): Hosts Logic Apps 04, 05
- SKU: WS1 (Windows, Logic App Standard tier)

#### Service Bus
- Namespace: `sb-dev-clz-ipaas3-01`
- Queue: `inbound-queue`
- Max Delivery Count: 10
- Lock Duration: 5 minutes (PT5M)
- Message TTL: 14 days (P14D)
- Dead Lettering: Enabled on message expiration

#### Storage Accounts
- **Config Storage**: `stcfgdevclzipaas301` (tables: platformconfig, metadata)
- **Logic App Storage**: `stladevclzipaas301` to `stladevclzipaas305` (one per Logic App)
- Replication: Standard_LRS
- TLS: Minimum 1.2
- Public Access: Disabled for nested items

#### Key Vault
- Name: `kv-dev-clz-ipaas3-01`
- SKU: Standard
- Authorization: RBAC (no access policies)
- Soft Delete: 7 days retention
- Purge Protection: Disabled (dev environment)
- Public Network Access: Enabled

#### Observability
- Log Analytics Workspace: `la-dev-clz-ipaas3-01` (30-day retention)
- Application Insights: `appi-dev-clz-ipaas3-01` (integrated with Log Analytics)

### Deployment

#### Deployment Order
1. Main Platform (`env/dev/`) - 8-12 minutes
   - Creates Resource Group, all services except APIM
2. APIM (`apim/`) - 25-30 minutes
   - Deploys APIM in existing Resource Group

#### Prerequisites
- Azure CLI installed and authenticated
- Terraform 1.5.0+ installed
- Azure subscription with Contributor access
- Backend storage account exists

### Known Limitations

- **APIM Deployment Time**: 25-30 minutes (Azure platform limitation)
- **Dev Environment Only**: Production environment not yet configured
- **Public Networking**: No VNet integration or Private Endpoints (by design for dev)
- **Manual Workflows**: Requires manual deployment from Logic Apps portal

### Cost Estimation (Monthly - Dev)

| Service | Quantity | Estimated Cost |
|---------|----------|----------------|
| APIM StandardV2_1 | 1 | ~$650 USD |
| Service Bus Standard | 1 | ~$10 USD |
| Logic Apps WS1 | 5 | ~$200 USD |
| Storage Accounts | 6 | ~$6 USD |
| Key Vault | 1 | ~$1 USD |
| Log Analytics | 1 | ~$50 USD |

**Total**: ~$920 USD/month

### References

- Azure Provider: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- Build Instructions: `.github/instructions/build-ais-platform.instructions.md`
- Terraform Best Practices: `.github/instructions/terraform.instructions.md`
- Azure Terraform Guide: `.github/instructions/terraform-azure.instructions.md`

---

## Future Enhancements

### Planned for v1.1.0
- [ ] Production environment configuration
- [ ] VNet integration for secure networking
- [ ] Private Endpoints for Key Vault and Storage
- [ ] Automated workflow deployment to Logic Apps
- [ ] API definitions in APIM
- [ ] Custom domains for APIM

### Under Consideration
- [ ] Multi-region deployment
- [ ] Azure DevOps Pipelines integration
- [ ] Policy as Code (Azure Policy)
- [ ] Cost optimization alerts
- [ ] Disaster recovery procedures

---

**Version**: 1.0.0  
**Release Date**: 2025-11-14  
**Author**: Terraform AIS Platform Generator  
**Organization**: Cellenza
