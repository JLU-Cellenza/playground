# Architecture - Project iPaaS 3

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     Azure Subscription                                   │
│                  3314da4a-7f83-4380-9d92-7b96c6fa78c6                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    Resource Group: rg-dev-clz-ipaas3-01                 │
│                         Region: France Central                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      API Layer                                   │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │  API Management (apim-dev-clz-ipaas3-01)                        │   │
│  │  ├─ SKU: StandardV2_1                                           │   │
│  │  ├─ Gateway URL: https://apim-dev-clz-ipaas3-01.azure-api.net  │   │
│  │  ├─ Developer Portal: Enabled                                   │   │
│  │  └─ Managed Identity: System-Assigned                           │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│                                    │ Routes API calls                    │
│                                    ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                   Messaging Layer                                │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │  Service Bus (sb-dev-clz-ipaas3-01)                             │   │
│  │  ├─ SKU: Standard                                               │   │
│  │  ├─ Queue: inbound-queue                                        │   │
│  │  │   ├─ Max Delivery: 10                                        │   │
│  │  │   ├─ Lock Duration: 5 min                                    │   │
│  │  │   ├─ TTL: 14 days                                            │   │
│  │  │   └─ Dead Letter: Enabled                                    │   │
│  │  └─ FQDN: sb-dev-clz-ipaas3-01.servicebus.windows.net          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│                     Managed Identity Authentication                      │
│                                    ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                   Processing Layer                               │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │  App Service Plan 1 (asp-dev-clz-ipaas3-01) - WS1              │   │
│  │  ├─ Logic App 01 (logic-dev-clz-ipaas3-01)                     │   │
│  │  │   └─ Storage: stladevclzipaas301                            │   │
│  │  ├─ Logic App 02 (logic-dev-clz-ipaas3-02)                     │   │
│  │  │   └─ Storage: stladevclzipaas302                            │   │
│  │  └─ Logic App 03 (logic-dev-clz-ipaas3-03)                     │   │
│  │      └─ Storage: stladevclzipaas303                            │   │
│  │                                                                  │   │
│  │  App Service Plan 2 (asp-dev-clz-ipaas3-02) - WS1              │   │
│  │  ├─ Logic App 04 (logic-dev-clz-ipaas3-04)                     │   │
│  │  │   └─ Storage: stladevclzipaas304                            │   │
│  │  └─ Logic App 05 (logic-dev-clz-ipaas3-05)                     │   │
│  │      └─ Storage: stladevclzipaas305                            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│                     Managed Identity Access                              │
│                                    ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                   Security & Storage Layer                       │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │  Key Vault (kv-dev-clz-ipaas3-01)                               │   │
│  │  ├─ SKU: Standard                                               │   │
│  │  ├─ Authorization: RBAC                                         │   │
│  │  ├─ Secrets:                                                    │   │
│  │  │   ├─ servicebus-connection-string                           │   │
│  │  │   └─ storage-config-connection-string                       │   │
│  │  └─ URI: https://kv-dev-clz-ipaas3-01.vault.azure.net          │   │
│  │                                                                  │   │
│  │  Storage (stcfgdevclzipaas301)                                  │   │
│  │  ├─ SKU: Standard_LRS                                           │   │
│  │  ├─ Tables:                                                     │   │
│  │  │   ├─ platformconfig                                         │   │
│  │  │   └─ metadata                                               │   │
│  │  └─ Access: Managed Identity from Logic Apps                   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                   Observability Layer                            │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │  Log Analytics (la-dev-clz-ipaas3-01)                           │   │
│  │  ├─ Retention: 30 days                                          │   │
│  │  ├─ Data Sources:                                               │   │
│  │  │   ├─ All Logic Apps diagnostics                             │   │
│  │  │   ├─ Service Bus metrics                                    │   │
│  │  │   ├─ Storage diagnostics                                    │   │
│  │  │   └─ APIM logs                                              │   │
│  │  └─ Integration: Application Insights                          │   │
│  │                                                                  │   │
│  │  Application Insights (appi-dev-clz-ipaas3-01)                  │   │
│  │  ├─ Type: Web                                                   │   │
│  │  ├─ Retention: 30 days                                          │   │
│  │  ├─ Connected To: All 5 Logic Apps                             │   │
│  │  └─ Telemetry: Traces, Dependencies, Exceptions                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### API Management (StandardV2)

**Purpose:** API gateway, request routing, rate limiting, transformation

**Key Features:**
- Auto-scaling based on load
- Built-in developer portal
- Policy framework (CORS, rate limiting, JWT validation)
- Backend routing to Logic Apps
- System-assigned managed identity

**Deployment Time:** 25-30 minutes

### Service Bus (Standard)

**Purpose:** Central message broker for asynchronous communication

**Configuration:**
- **Queue:** `inbound-queue` - receives messages from external systems
- **Dead Letter Queue:** Automatically created for failed messages
- **Sessions:** Disabled (can be enabled per queue)
- **Partitioning:** Disabled

**Access Pattern:**
- Logic Apps use managed identity (no connection strings)
- RBAC role: "Azure Service Bus Data Receiver"

### Logic Apps Standard (5 instances)

**Purpose:** Workflow execution engine for integration logic

**Distribution:**
- **Plan 1 (WS1):** 3 Logic Apps (scale together)
- **Plan 2 (WS1):** 2 Logic Apps (independent scaling)

**Runtime:**
- Node.js v18
- Functions runtime v4
- Local.settings.json not used (app settings managed by Terraform)

**Storage:**
- Each Logic App has dedicated storage account
- Used for workflow state, bindings, function artifacts

### Key Vault (RBAC-based)

**Purpose:** Centralized secrets management

**Access Control:**
- **Terraform SP:** Key Vault Secrets Officer (create/update/delete)
- **Logic Apps:** Key Vault Secrets User (read-only)
- **Manual Access:** Requires RBAC assignment

**Secrets Stored:**
- Service Bus connection string (fallback)
- Storage config connection string
- Any custom secrets added by workflows

### Storage Accounts

**Platform Config Storage:**
- Name: `stcfgdevclzipaas301`
- Tables: `platformconfig`, `metadata`
- Purpose: Configuration data, lookup tables

**Logic App Storage (5x):**
- Names: `stladevclzipaas301` to `stladevclzipaas305`
- Purpose: Workflow state, artifacts
- Auto-configured via Logic App parameters

### Observability Stack

**Log Analytics Workspace:**
- All diagnostic logs centralized
- 30-day retention (configurable)
- Kusto Query Language (KQL) for analysis

**Application Insights:**
- Distributed tracing across Logic Apps
- Dependency tracking
- Performance monitoring
- Exception tracking

## Network Architecture

### Current (Dev Environment)

```
Internet
   │
   ▼
APIM Public Endpoint
   │
   ▼
Service Bus (Public)
   │
   ▼
Logic Apps (Public)
   │
   ▼
Key Vault (Public) + Storage (Public)
```

**Security:**
- HTTPS/TLS 1.2 enforced
- Managed identity authentication (no passwords)
- RBAC authorization
- Azure AD integration

### Future (Production)

```
Internet
   │
   ▼
APIM (Custom Domain + WAF)
   │
   ▼
VNet (Subnet: Integration)
   │
   ├─ Service Bus (Private Endpoint)
   ├─ Logic Apps (VNet Integration)
   ├─ Key Vault (Private Endpoint)
   └─ Storage (Private Endpoint)
```

## Data Flow

### Typical Message Processing Flow

1. **External System** → HTTP POST to APIM gateway
2. **APIM** → Apply policies, route to backend
3. **Backend** → Send message to Service Bus queue `inbound-queue`
4. **Service Bus** → Queue message (persistent storage)
5. **Logic App (any of 5)** → Trigger on new message
6. **Logic App** → Process message, retrieve secrets from Key Vault
7. **Logic App** → Query config from Storage tables
8. **Logic App** → Execute business logic
9. **Logic App** → Send result to downstream system or storage
10. **App Insights** → Record telemetry

### Error Handling

- **Service Bus:** Failed messages → Dead Letter Queue after 10 retries
- **Logic Apps:** Workflow failures → Retry policies + error logs
- **APIM:** 4xx/5xx errors → Logged + returned to caller
- **Monitoring:** All errors visible in Log Analytics + App Insights

## Security Architecture

### Authentication & Authorization

| Component | Identity | Access Method |
|-----------|----------|---------------|
| APIM | System-Assigned MI | Azure AD |
| Logic Apps (5x) | System-Assigned MI | Azure AD |
| Service Bus | N/A | Managed Identity + RBAC |
| Key Vault | N/A | Managed Identity + RBAC |
| Storage | N/A | Managed Identity + RBAC |

### RBAC Assignments

```
Logic Apps (01-05)
  ├─ "Azure Service Bus Data Receiver" → Service Bus Namespace
  └─ "Key Vault Secrets User" → Key Vault

Terraform Service Principal
  └─ "Key Vault Secrets Officer" → Key Vault (deployment only)
```

### Secrets Management

**Never in Code:**
- ❌ Connection strings in .tf files
- ❌ API keys in variables
- ❌ Passwords in app settings

**Always in Key Vault:**
- ✅ Service Bus connection string (fallback)
- ✅ Storage connection strings
- ✅ Third-party API keys
- ✅ Database passwords

**Reference Pattern:**
```
@Microsoft.KeyVault(SecretUri=https://kv-dev-clz-ipaas3-01.vault.azure.net/secrets/my-secret/)
```

## Deployment Architecture

### Infrastructure as Code

```
GitHub Repository
   │
   ├─ modules/          # Reusable Terraform modules
   │   ├─ apim/
   │   ├─ logicapp/
   │   ├─ servicebus/
   │   ├─ keyvault/
   │   └─ storage/
   │
   ├─ env/dev/          # Environment-specific config
   │   ├─ main.tf       # Module instantiation
   │   ├─ variables.tf  # Input variables
   │   └─ dev.tfvars    # Dev values
   │
   └─ apim/             # Separate APIM deployment
       ├─ main.tf
       └─ dev.tfvars
```

### State Management

```
Azure Storage Account: stocommoniac01
   ├─ Container: terraform
   │   ├─ project-ipaas3-dev.tfstate       # Main platform state
   │   └─ project-ipaas3-dev-apim.tfstate  # APIM state (separate)
```

**Why Separate APIM State?**
- Independent lifecycle management
- Faster main platform deployments (no 30-min APIM wait)
- Azure provider issue workaround (managed identity propagation)

## Scalability

### Current Capacity

| Component | SKU | Capacity | Max Throughput |
|-----------|-----|----------|----------------|
| APIM | StandardV2 | 1 unit | Auto-scales |
| Service Bus | Standard | 1 namespace | 1000 ops/sec |
| Logic Apps | WS1 x 2 | 5 apps total | ~100 runs/min |
| Storage | Standard_LRS | Unlimited | 20,000 IOPS |

### Scale-Out Options

**Service Bus:**
- Upgrade to Premium for higher throughput
- Add partitioning for parallel processing
- Enable sessions for ordered processing

**Logic Apps:**
- Scale App Service Plans to WS2/WS3
- Add more App Service Plans
- Distribute load across more Logic Apps

**APIM:**
- Add capacity units (StandardV2_2, StandardV2_3, etc.)
- Multi-region deployment (Premium SKU)
- Enable caching for frequently accessed APIs

## Monitoring & Alerting

### Key Metrics

**Service Bus:**
- Queue length (active messages)
- Dead letter count
- Incoming/outgoing messages per minute

**Logic Apps:**
- Run success rate
- Run duration (p50, p95, p99)
- Failed runs per hour

**APIM:**
- Request count
- Response time (p50, p95)
- 4xx/5xx error rate

**Storage:**
- Table operations per second
- Storage capacity used
- Availability %

### Log Analytics Queries

```kusto
// Failed Logic App runs in last 24 hours
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.WEB"
| where Category == "FunctionAppLogs"
| where Level == "Error"
| where TimeGenerated > ago(24h)
| summarize ErrorCount = count() by Resource
| order by ErrorCount desc

// Service Bus dead letter messages
AzureMetrics
| where ResourceProvider == "MICROSOFT.SERVICEBUS"
| where MetricName == "DeadletteredMessages"
| where TimeGenerated > ago(1h)
| summarize Max = max(Total) by Resource
```

## Disaster Recovery

### Backup Strategy

**Infrastructure:**
- All infrastructure defined in Terraform (version controlled)
- State files backed up in Azure Storage (geo-redundant)

**Data:**
- Service Bus: Messages are transient (14-day retention)
- Storage Tables: Enable point-in-time restore (optional)
- Key Vault: Soft delete enabled (7-day recovery window)

### Recovery Procedures

**Full Environment Loss:**
1. Run: `terraform apply` from version control
2. Restore secrets to Key Vault (from secure backup)
3. Redeploy Logic App workflows (from source control)
4. Restore configuration tables (from backup)

**Estimated RTO:** 1-2 hours  
**Estimated RPO:** 0 hours (infrastructure), variable (data)

## Cost Optimization

### Current Monthly Cost: ~$920 USD

**Breakdown:**
- APIM StandardV2: $650 (71%)
- Logic Apps WS1 x 5: $200 (22%)
- Log Analytics: $50 (5%)
- Service Bus + Storage + Key Vault: $20 (2%)

### Cost Reduction Strategies

**Non-Production:**
- Destroy APIM when not in use (saves ~$650/month)
- Use Developer SKU for APIM (saves ~$600/month)
- Reduce Log Analytics retention to 7 days

**Production:**
- Use Reserved Instances for APIM (save 30-40%)
- Consolidate Logic Apps on fewer plans
- Enable APIM caching to reduce backend calls

---

**Last Updated:** 2025-11-14  
**Version:** 1.0.0  
**Maintained By:** Cellenza Platform Team
