# Azure iPaaS Platform - Architecture

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Azure iPaaS Platform                             │
│                    Cellenza MVP Demo - France Central                    │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                         API Gateway Layer                                 │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  API Management (Developer SKU)                                 │     │
│  │  • apim-dev-cellenza-mvpipaas-01                               │     │
│  │  • Gateway URL: *.azure-api.net                                │     │
│  │  • Developer Portal                                             │     │
│  │  • Rate Limiting, Policies, OAuth                              │     │
│  └────────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                      Workflow Orchestration Layer                         │
│  ┌───────────────────────────────┐  ┌───────────────────────────────┐  │
│  │  Logic App Standard 01        │  │  Logic App Standard 02        │  │
│  │  loa-*-workflow-01            │  │  loa-*-workflow-02            │  │
│  │  • Workflow runtime v4        │  │  • Workflow runtime v4        │  │
│  │  • System Managed Identity    │  │  • System Managed Identity    │  │
│  │  • Node.js 18                 │  │  • Node.js 18                 │  │
│  └───────────────────────────────┘  └───────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
                    │                              │
                    └──────────────┬───────────────┘
                                   ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                       Messaging & Integration Layer                       │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Service Bus Namespace (Standard SKU)                           │     │
│  │  • sb-dev-cellenza-mvpipaas-01                                 │     │
│  │  ┌──────────────────────────────────────────────────────┐     │     │
│  │  │  Queue: "inbound"                                     │     │     │
│  │  │  • Max Delivery: 10                                   │     │     │
│  │  │  • Lock Duration: 5 min                               │     │     │
│  │  │  • TTL: 14 days                                       │     │     │
│  │  │  • Dead Letter: Enabled                               │     │     │
│  │  └──────────────────────────────────────────────────────┘     │     │
│  └────────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                        Compute & Helpers Layer                            │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Function App (Consumption Plan)                                │     │
│  │  • func-dev-cellenza-mvpipaas-helpers-01                       │     │
│  │  • .NET 8 Isolated                                             │     │
│  │  • System Managed Identity                                      │     │
│  │  • Custom Connectors & Helpers                                 │     │
│  └────────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          Storage Layer                                    │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │
│  │ Storage Acct │ │ Storage Acct │ │ Storage Acct │ │ Storage Acct │  │
│  │ Function App │ │ Logic App 01 │ │ Logic App 02 │ │  Platform    │  │
│  │              │ │              │ │              │ │  Configs     │  │
│  │ Standard LRS │ │ Standard LRS │ │ Standard LRS │ │ Standard LRS │  │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘  │
│                                                        │                  │
│                                                        └─ Containers:     │
│                                                          • configurations │
│                                                          • templates      │
│                                                          • schemas        │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                    Monitoring & Observability Layer                       │
│  ┌───────────────────────────────┐  ┌───────────────────────────────┐  │
│  │  Log Analytics Workspace      │  │  Application Insights         │  │
│  │  • la-dev-cellenza-*-01      │  │  • appi-dev-cellenza-*-01    │  │
│  │  • 30 day retention          │  │  • Connected to Log Analytics │  │
│  │  • Kusto queries             │  │  • APM & Distributed Tracing  │  │
│  └───────────────────────────────┘  └───────────────────────────────┘  │
│                                                                           │
│  All services send diagnostic logs and metrics                           │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                         Security & Identity                               │
│  • All services use System-Assigned Managed Identities                   │
│  • RBAC Assignments:                                                      │
│    - Service Bus Data Sender/Receiver (Function, Logic Apps)            │
│    - Storage Blob Data Contributor (Function, Logic Apps → Platform)    │
│  • TLS 1.2 minimum on all services                                       │
│  • Public access enabled for demo (⚠️ disable for production)           │
└──────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Patterns

### Pattern 1: API to Service Bus
```
External Client → APIM Gateway → Logic App 01 → Service Bus (inbound queue)
```

### Pattern 2: Service Bus Processing
```
Service Bus (inbound queue) → Logic App 02 → Process → External System
```

### Pattern 3: Custom Connector
```
Logic App → Function App (custom connector) → External API → Return to Logic App
```

### Pattern 4: Configuration Retrieval
```
Logic App/Function → Platform Storage (configurations) → Read schema/template
```

## Networking

- **Public Access**: ✅ Enabled for all services (demo configuration)
- **Private Endpoints**: ❌ Not configured (add for production)
- **VNet Integration**: ❌ Not configured (add for production)
- **Firewall Rules**: ❌ None (configure for production)

## Security Model

### Authentication
- **Service-to-Service**: Managed Identity with RBAC
- **API Gateway**: Can add OAuth2, API keys, or JWT validation
- **Storage**: Managed Identity (no connection strings in code)
- **Service Bus**: Managed Identity (no connection strings in code)

### Authorization
- **Function App**:
  - Service Bus Data Sender/Receiver
  - Storage Blob Data Contributor
- **Logic Apps (both)**:
  - Service Bus Data Sender/Receiver
  - Storage Blob Data Contributor

## Cost Optimization

| Service | SKU | Monthly Cost (Est.) | Production Alternative |
|---------|-----|---------------------|------------------------|
| APIM | Developer | ~€42 | StandardV2 (~€550) |
| Service Bus | Standard | ~€10 | Premium (~€600) |
| Logic Apps (2x) | WS1 | ~€80/each | WS2/WS3 |
| Function App | Consumption | ~€0-10 | Premium (~€140) |
| Storage (4x) | Standard LRS | ~€5/each | GRS for HA |
| Log Analytics | PerGB2018 | ~€5-20 | Based on ingestion |
| App Insights | Pay-as-you-go | ~€5-15 | Based on telemetry |
| **Total** | | **~€250-280/month** | |

## Scaling Considerations

- **Function App**: Auto-scales with Consumption plan (0-200 instances)
- **Logic Apps**: Fixed capacity with WS1 (scale up to WS2/WS3)
- **Service Bus**: Standard supports up to 1,000 concurrent connections
- **APIM**: Developer limited to 1 unit (scale to StandardV2 for production)

## Disaster Recovery

- **RTO**: ~4 hours (manual re-deployment)
- **RPO**: Depends on Service Bus message retention (14 days)
- **Backup**: Terraform state in Azure Storage (enable versioning)
- **Multi-Region**: Not configured (add geo-replication for production)

## Compliance & Governance

- **Tags**: All resources tagged (project, environment, owner, cost_center)
- **Naming**: Follows CAF conventions
- **RBAC**: Least privilege with Managed Identities
- **Audit Logs**: Diagnostic settings to Log Analytics
- **Data Residency**: France Central region

## Future Enhancements

1. **Security**: Add Private Endpoints, disable public access
2. **Networking**: VNet integration, Application Gateway with WAF
3. **HA/DR**: Multi-region deployment, Traffic Manager
4. **Key Vault**: Store connection strings and secrets
5. **Monitoring**: Custom dashboards, alerting rules
6. **CI/CD**: GitHub Actions or Azure DevOps pipelines
7. **Testing**: Automated integration tests
8. **API Versioning**: APIM policies and version sets

## Resource Naming Reference

| Service | Name Pattern | Example |
|---------|--------------|---------|
| Resource Group | rg-{env}-{org}-{project}-{instance} | rg-dev-cellenza-mvpipaas-01 |
| Log Analytics | la-{env}-{org}-{project}-{instance} | la-dev-cellenza-mvpipaas-01 |
| App Insights | appi-{env}-{org}-{project}-{instance} | appi-dev-cellenza-mvpipaas-01 |
| Storage | st{purpose}{env}{org}{project}{instance} | stpldevcellenzamvpipaas01 |
| Service Bus | sb-{env}-{org}-{project}-{instance} | sb-dev-cellenza-mvpipaas-01 |
| Function App | func-{env}-{org}-{project}-{purpose}-{instance} | func-dev-cellenza-mvpipaas-helpers-01 |
| Logic App | loa-{env}-{org}-{project}-{purpose}-{instance} | loa-dev-cellenza-mvpipaas-workflow-01 |
| APIM | apim-{env}-{org}-{project}-{instance} | apim-dev-cellenza-mvpipaas-01 |
| App Service Plan | asp-{env}-{org}-{project}-{type}-{instance} | asp-dev-cellenza-mvpipaas-func-01 |

---

**Architecture Version**: 1.0.0  
**Last Updated**: 2025-11-06  
**Maintained By**: Cellenza Integration Team
