# Azure Integration Services (AIS) Platform - Specification Template

> **Purpose:** This template provides all required information for generating a complete, production-ready Azure Integration Services platform using Terraform.
> 
> **Instructions:** Fill out all sections marked with `[REQUIRED]`. Optional sections can be left blank or removed. The more detail you provide, the more accurate the generated platform will be.

---

## 1. Project Identification [REQUIRED]

### Basic Information

| Field | Value | Notes |
|-------|-------|-------|
| **Project Name** | `[REQUIRED]` | 3-8 lowercase alphanumeric characters (e.g., `ipaas3`, `salesint`) |
| **Organization Abbreviation** | `[REQUIRED]` | 3-6 lowercase letters (e.g., `clz` for Cellenza) |
| **Project Description** | `[REQUIRED]` | Brief description of the integration platform purpose |
| **Owner/Team** | `[REQUIRED]` | Team or individual responsible for this platform |
| **Cost Center** | `[OPTIONAL]` | Billing code or cost center (default: `demo`) |

**Example:**
```yaml
Project Name: ipaas3
Organization: clz
Description: Enterprise iPaaS for customer data integration
Owner: Integration Team
Cost Center: IT-2024-Q4
```

---

## 2. Azure Configuration [REQUIRED]

### Subscription & Location

| Field | Value | Notes |
|-------|-------|-------|
| **Azure Subscription ID** | `[REQUIRED or "use existing"]` | Full GUID or "use GitHub Actions secret" |
| **Azure Region** | `[REQUIRED]` | e.g., `francecentral`, `westeurope`, `eastus2` |
| **Resource Group Name** | `[REQUIRED or "auto-generate"]` | Existing RG name or "create new" |
| **Resource Group Action** | `[REQUIRED]` | `create-new` or `use-existing` |

**Example:**
```yaml
Subscription ID: use GitHub Actions (configured separately)
Region: francecentral
Resource Group: rg-dev-clz-ipaas3-01
Action: create-new
```

---

## 3. Environment Configuration [REQUIRED]

### Target Environments

Select which environments to generate (check all that apply):

- [ ] **Dev** - Development environment
- [ ] **Test** - Testing/QA environment
- [ ] **Staging** - Pre-production staging
- [ ] **Production** - Production environment

**Initial Environment to Generate:** `[REQUIRED - select one]`  
Example: `dev`

---

## 4. Platform Services [REQUIRED]

### Core Services

For each service, specify **YES** or **NO**, and provide configuration details if YES.

#### 4.1 API Management (APIM)

- **Include APIM?** `[REQUIRED: YES/NO]`

If YES, provide:

| Field | Value | Options/Notes |
|-------|-------|---------------|
| **SKU** | `[REQUIRED]` | `Developer_1`, `Basic_1`, `Standard_1`, `StandardV2_1`, `Premium_1` |
| **Capacity** | `[OPTIONAL]` | Number of units (default: 1) |
| **Publisher Name** | `[REQUIRED]` | Organization name for developer portal |
| **Publisher Email** | `[REQUIRED]` | Contact email for API publisher |
| **Custom Domain** | `[OPTIONAL]` | Custom domain for gateway (or leave blank) |

**Example:**
```yaml
Include APIM: YES
SKU: StandardV2_1
Capacity: 1
Publisher Name: Cellenza
Publisher Email: admin@cellenza.com
Custom Domain: (leave blank for dev)
```

#### 4.2 Service Bus

- **Include Service Bus?** `[REQUIRED: YES/NO]`

If YES, provide:

| Field | Value | Options/Notes |
|-------|-------|---------------|
| **SKU** | `[REQUIRED]` | `Basic`, `Standard`, `Premium` |
| **Queue Names** | `[REQUIRED]` | Comma-separated list (e.g., `inbound-queue,outbound-queue,deadletter`) |
| **Topic Names** | `[OPTIONAL]` | Comma-separated list or leave blank |
| **Max Delivery Count** | `[OPTIONAL]` | Default: 10 |
| **Message TTL** | `[OPTIONAL]` | Default: P14D (14 days) |

**Example:**
```yaml
Include Service Bus: YES
SKU: Standard
Queue Names: inbound-queue, processing-queue, response-queue
Topic Names: (leave blank)
Max Delivery Count: 10
Message TTL: P14D
```

#### 4.3 Logic Apps Standard

- **Include Logic Apps?** `[REQUIRED: YES/NO]`

If YES, provide:

| Field | Value | Options/Notes |
|-------|-------|---------------|
| **Number of Logic Apps** | `[REQUIRED]` | Total count (e.g., 5) |
| **App Service Plans** | `[REQUIRED]` | How to distribute (see examples below) |
| **Plan SKU** | `[REQUIRED]` | `WS1`, `WS2`, `WS3` |
| **Runtime Version** | `[OPTIONAL]` | Default: `~4` |

**Distribution Examples:**
- `2 plans: 3+2` = Plan 1 has 3 Logic Apps, Plan 2 has 2
- `1 plan: 5` = All 5 Logic Apps on one plan
- `3 plans: 2+2+1` = Three plans with 2, 2, and 1 apps

**Example:**
```yaml
Include Logic Apps: YES
Number of Logic Apps: 5
Distribution: 2 plans (3 apps on plan 1, 2 apps on plan 2)
Plan SKU: WS1
Runtime Version: ~4
```

#### 4.4 Azure Functions

- **Include Azure Functions?** `[REQUIRED: YES/NO]`

If YES, provide:

| Field | Value | Options/Notes |
|-------|-------|---------------|
| **Number of Function Apps** | `[REQUIRED]` | Total count |
| **Runtime** | `[REQUIRED]` | `node`, `dotnet`, `python`, `java` |
| **Runtime Version** | `[REQUIRED]` | e.g., `18` for Node, `8` for .NET |
| **Plan Type** | `[REQUIRED]` | `Consumption`, `Premium`, `App Service Plan` |

**Example:**
```yaml
Include Functions: NO
```

#### 4.5 Key Vault

- **Include Key Vault?** `[REQUIRED: YES/NO]`

If YES, provide:

| Field | Value | Options/Notes |
|-------|-------|---------------|
| **SKU** | `[OPTIONAL]` | `standard` or `premium` (default: standard) |
| **Purge Protection** | `[OPTIONAL]` | `true` or `false` (default: false for dev) |
| **Soft Delete Retention** | `[OPTIONAL]` | Days (7-90, default: 7) |
| **Initial Secrets** | `[OPTIONAL]` | List secrets to create (values provided separately) |

**Example:**
```yaml
Include Key Vault: YES
SKU: standard
Purge Protection: false (dev environment)
Soft Delete Retention: 7 days
Initial Secrets: servicebus-connection, storage-connection, api-key
```

#### 4.6 Storage Accounts

- **Platform Config Storage?** `[REQUIRED: YES/NO]`

If YES, provide:

| Field | Value | Options/Notes |
|-------|-------|---------------|
| **Replication** | `[OPTIONAL]` | `LRS`, `GRS`, `RAGRS`, `ZRS` (default: LRS) |
| **Container Names** | `[OPTIONAL]` | Comma-separated list |
| **Table Names** | `[OPTIONAL]` | Comma-separated list |
| **Queue Names** | `[OPTIONAL]` | Comma-separated list |

**Example:**
```yaml
Platform Config Storage: YES
Replication: LRS
Containers: (leave blank)
Tables: platformconfig, metadata, lookup
Queues: (leave blank)
```

- **Additional Storage Accounts?** `[OPTIONAL]`
  - Describe purpose and configuration for each additional account needed

#### 4.7 Observability

- **Include Log Analytics?** `[REQUIRED: YES/NO]`
- **Include Application Insights?** `[REQUIRED: YES/NO]`

If YES, provide:

| Field | Value | Options/Notes |
|-------|-------|---------------|
| **Log Retention (days)** | `[OPTIONAL]` | Default: 30 (range: 30-730) |
| **Application Type** | `[OPTIONAL]` | Default: `web` |

**Example:**
```yaml
Log Analytics: YES
Application Insights: YES
Retention: 30 days
Application Type: web
```

---

## 5. Networking [REQUIRED]

### Network Configuration

| Field | Value | Options/Notes |
|-------|-------|---------------|
| **Network Type** | `[REQUIRED]` | `public` or `vnet-integrated` |
| **VNet Name** | `[REQUIRED if vnet-integrated]` | Existing VNet name or "create new" |
| **Subnet Names** | `[REQUIRED if vnet-integrated]` | Comma-separated (e.g., `integration,data,management`) |
| **Private Endpoints** | `[REQUIRED]` | `YES` or `NO` |
| **Services for Private Endpoints** | `[REQUIRED if YES]` | Which services need private endpoints? |

**Example (Public - Dev/Test):**
```yaml
Network Type: public
VNet: N/A
Private Endpoints: NO
```

**Example (VNet - Production):**
```yaml
Network Type: vnet-integrated
VNet: vnet-prod-clz-hub-01 (existing)
Subnets: integration-subnet, data-subnet
Private Endpoints: YES
Services: Key Vault, Storage, Service Bus
```

---

## 6. Backend State Configuration [REQUIRED]

### Terraform State Management

| Field | Value | Options/Notes |
|-------|-------|---------------|
| **Backend Type** | `[REQUIRED]` | `azurerm` (Azure Storage) or `local` (not recommended) |
| **Storage Account Name** | `[REQUIRED if azurerm]` | Existing storage account or "use existing" |
| **Resource Group** | `[REQUIRED if azurerm]` | Storage account resource group |
| **Container Name** | `[REQUIRED if azurerm]` | Default: `terraform` |
| **State File Key Pattern** | `[OPTIONAL]` | Default: `{project}-{env}.tfstate` |

**Example:**
```yaml
Backend Type: azurerm
Storage Account: stocommoniac01 (use existing)
Resource Group: rg-common-iac-01
Container: terraform
State File Pattern: project-ipaas3-{env}.tfstate
```

---

## 7. Naming & Tagging [REQUIRED]

### Resource Naming

**Pattern:** `<service>-<env>-<org>-<project>-<instance>`

Naming is auto-generated, but you can override if needed:

| Field | Value | Options/Notes |
|-------|-------|---------------|
| **Use Auto-Naming?** | `[REQUIRED]` | `YES` (recommended) or `NO` (provide custom) |
| **Numeric Suffix Required?** | `[REQUIRED]` | `YES` (recommended) or `NO` |

If custom naming, provide examples:
```yaml
APIM: custom-apim-name-01
Service Bus: custom-sb-name-01
Logic Apps: custom-logic-app-{01-05}
```

### Mandatory Tags

| Tag Key | Tag Value | Notes |
|---------|-----------|-------|
| **environment** | `[AUTO from env]` | Auto-populated |
| **project** | `[AUTO from project name]` | Auto-populated |
| **organization** | `[AUTO from org abbrev]` | Auto-populated |
| **cost_center** | `[REQUIRED]` | Billing code |
| **owner** | `[REQUIRED]` | Team or individual |

### Additional Tags (Optional)

Add any custom tags:
```yaml
department: Integration
compliance: ISO27001
data_classification: internal
```

---

## 8. Security & Compliance [REQUIRED]

### Authentication & Authorization

| Field | Value | Options/Notes |
|-------|-------|---------------|
| **Use Managed Identities?** | `[REQUIRED]` | `YES` (recommended) or `NO` |
| **Key Vault Authorization** | `[REQUIRED]` | `RBAC` (recommended) or `Access Policies` |
| **Terraform SP RBAC** | `[REQUIRED]` | `auto-assign` (recommended) or `manual` |

**Example:**
```yaml
Managed Identities: YES (all services)
Key Vault Auth: RBAC
Terraform SP: auto-assign "Key Vault Secrets Officer"
```

### Compliance Requirements

Check all that apply:

- [ ] **GDPR** - EU data protection
- [ ] **HIPAA** - Healthcare data
- [ ] **PCI-DSS** - Payment card data
- [ ] **SOC 2** - Security controls
- [ ] **ISO 27001** - Information security
- [ ] **Custom** - Describe: _______________

---

## 9. Integration Requirements [OPTIONAL]

### External Systems

List systems this platform will integrate with:

| System Name | Type | Direction | Protocol | Notes |
|-------------|------|-----------|----------|-------|
| Salesforce | CRM | Bidirectional | REST API | OAuth 2.0 |
| SAP | ERP | Inbound | RFC | VPN required |
| SQL Server | Database | Outbound | T-SQL | Managed identity |

### Data Sources

| Source | Type | Access Method | Frequency |
|--------|------|---------------|-----------|
| Azure SQL | Database | Managed Identity | Real-time |
| Blob Storage | Files | SAS token | Batch (hourly) |
| Cosmos DB | NoSQL | Connection string | Real-time |

---

## 10. Deployment Preferences [REQUIRED]

### CI/CD Configuration

| Field | Value | Options/Notes |
|-------|-------|---------------|
| **Use GitHub Actions?** | `[REQUIRED]` | `YES` or `NO` |
| **Use Azure DevOps?** | `[REQUIRED]` | `YES` or `NO` |
| **Manual Deployment?** | `[REQUIRED]` | `YES` or `NO` |
| **Approval Gates** | `[OPTIONAL]` | Which environments require approval? |

**Example:**
```yaml
GitHub Actions: YES
Azure DevOps: NO
Manual Deployment: YES (initial deployment)
Approval Gates: Production only (2 approvers)
```

### Deployment Order

- **Deploy APIM Separately?** `[REQUIRED]` `YES` (recommended) or `NO`
- **Deployment Sequence:** `[OPTIONAL]` Describe any specific order requirements

---

## 11. Monitoring & Alerting [OPTIONAL]

### Alerting Rules

Define critical alerts to configure:

| Metric | Threshold | Action | Severity |
|--------|-----------|--------|----------|
| Service Bus Dead Letters | > 10 messages | Email + SMS | Critical |
| Logic App Failure Rate | > 5% | Email | Warning |
| APIM Response Time | > 2 seconds (p95) | Email | Warning |
| Storage Capacity | > 80% | Email | Info |

### Log Analytics Queries

Provide any custom KQL queries needed:

```kusto
// Example: Failed workflows in last hour
AzureDiagnostics
| where TimeGenerated > ago(1h)
| where Category == "WorkflowRuntime"
| where Level == "Error"
```

---

## 12. Cost Constraints [OPTIONAL]

### Budget Information

| Field | Value | Notes |
|-------|-------|-------|
| **Monthly Budget** | `[OPTIONAL]` | USD or local currency |
| **Cost Alerts** | `[OPTIONAL]` | Email when exceeding threshold |
| **Auto-Shutdown** | `[OPTIONAL]` | Non-prod environments shutdown schedule |

**Example:**
```yaml
Monthly Budget: $1,000 USD
Cost Alert: Email when 80% spent
Auto-Shutdown: Dev environment off on weekends
```

---

## 13. Special Requirements [OPTIONAL]

### Custom Configurations

Describe any specific requirements not covered above:

```yaml
- APIM must support OAuth 2.0 with Azure AD B2C
- Logic Apps need SAP connector license
- Service Bus requires sessions enabled on specific queues
- Storage must support hierarchical namespace (Data Lake Gen2)
- Key Vault needs HSM-backed keys for production
```

### Performance Requirements

| Service | Requirement | SLA |
|---------|-------------|-----|
| APIM | < 500ms response time | 99.9% |
| Logic Apps | < 5 min execution time | 99.95% |
| Service Bus | < 1 sec message latency | 99.9% |

---

## 14. Documentation Preferences [OPTIONAL]

### Generated Documentation

Check which documents to generate:

- [x] **README.md** - Platform overview (always generated)
- [x] **ARCHITECTURE.md** - Architecture diagrams & data flows
- [x] **RUNBOOK.md** - Deployment procedures
- [x] **CHANGELOG.md** - Version history
- [ ] **API_DOCUMENTATION.md** - API specifications
- [ ] **TROUBLESHOOTING.md** - Common issues & solutions
- [ ] **DISASTER_RECOVERY.md** - DR procedures

### Documentation Format

- **Diagrams:** `ASCII` (default), `Mermaid`, `PlantUML`, or `None`
- **Code Examples:** `PowerShell`, `Bash`, or `Both`
- **Detail Level:** `Concise`, `Standard` (default), or `Comprehensive`

---

## 15. Validation Checklist

Before submitting this specification, ensure:

- [ ] All `[REQUIRED]` fields are completed
- [ ] Azure region is valid and available
- [ ] Resource names comply with Azure limits (24 chars for Storage/Key Vault)
- [ ] Service combinations are compatible (e.g., APIM + Logic Apps)
- [ ] Backend storage account exists or will be created
- [ ] Networking configuration is realistic for environment
- [ ] Cost estimates are within budget constraints
- [ ] Security requirements are clearly specified
- [ ] Deployment preferences are feasible

---

## 16. Example: Complete Specification

### Quick Example (Minimal Configuration)

```yaml
PROJECT:
  name: ipaas3
  org: clz
  description: Customer integration platform
  owner: Integration Team

AZURE:
  subscription: use GitHub Actions
  region: francecentral
  resource_group: rg-dev-clz-ipaas3-01 (create new)

ENVIRONMENT:
  initial: dev

SERVICES:
  apim: YES (StandardV2_1)
  service_bus: YES (Standard, queue: inbound-queue)
  logic_apps: YES (5 apps, 2 plans: 3+2, WS1)
  key_vault: YES (standard, RBAC)
  storage_config: YES (tables: platformconfig, metadata)
  observability: YES (30-day retention)

NETWORKING:
  type: public

BACKEND:
  storage: stocommoniac01 (existing)
  rg: rg-common-iac-01
  container: terraform

SECURITY:
  managed_identities: YES
  key_vault_auth: RBAC
  terraform_sp: auto-assign

DEPLOYMENT:
  github_actions: YES
  apim_separate: YES
```

---

## 17. Submission

Once completed, provide this specification via:

1. **Copy/paste** the filled template in chat
2. **Upload** as a YAML/JSON file
3. **Reference** an existing specification file in your repository

---

**Template Version:** 1.0.0  
**Last Updated:** 2025-11-14  
**Maintained By:** Azure Integration Services Platform Generator
