`Filled specification for private iPaaS platform`

---

# AIS Landing Zone Specification (Filled)

Purpose: Provide required inputs to generate a secure, private-first Azure Integration Services (AIS) landing zone with Terraform.

Status: **COMPLETED** - Ready for Terraform generation

---

## Summary Checklist (completed)
- Project Name: `pipaas01`
- Organization Abbreviation: `clz`
- Azure Subscription ID: `(use ARM_SUBSCRIPTION_ID env var)`
- Primary Region: `francecentral`
- Terraform Backend: `create_new`
- VNet CIDR: `10.50.0.0/16`
- APIM Include: `yes` | SKU: `StandardV2` | Network Mode: `External (VNet Integrated)`
- Service networking: All services with Private Endpoints, public access disabled

---

## 1. Project Identification (REQUIRED)

Basic information:

- Project Name: `pipaas01`
- Organization Abbreviation: `clz`
- Project Description: `Private iPaaS landing zone with external APIM, Logic Apps (standard + isolated), shared Storage and Service Bus. All backend services secured via Private Endpoints.`
- Owner / Team: `Platform Team`
- Cost Center: `IT-Integration-01`

```yaml
project_name: pipaas01
organization: clz
description: "Private iPaaS landing zone with external APIM, Logic Apps (standard + isolated), shared Storage and Service Bus"
owner: Platform Team
cost_center: IT-Integration-01
```

---

## 2. Azure Configuration (REQUIRED)

Subscription and region details:

- Azure Subscription ID: `(use ARM_SUBSCRIPTION_ID environment variable - do not commit)`
- Primary Region: `francecentral`
- Secondary Region: `None` (single-region deployment)
- Terraform Backend: `create_new`

```yaml
backend: create_new
backend_storage_account: stopipaas01tfstate
backend_container: tfstate
backend_key: pipaas01.tfstate
```

---

## 3. Network Topology & Scale (REQUIRED)

Topology choice:

- Topology Model: `hub-and-spoke`

> **Rationale**: Hub-and-spoke is recommended for single-region deployments with controlled egress. Allows future expansion with additional spokes if needed.

Infrastructure integration:

- Deploy to Existing VNet?: `no`
- VNet CIDR: `10.50.0.0/16` (65,536 addresses - ample headroom for growth)

### Network Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         VNet: 10.50.0.0/16                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────────┐  │
│  │ snet-appgw       │    │ snet-apim        │    │ snet-logicapps       │  │
│  │ 10.50.1.0/24     │───▶│ 10.50.2.0/24     │───▶│ 10.50.3.0/24         │  │
│  │ (App Gateway)    │    │ (APIM External)  │    │ (LA Std Inbound/Out) │  │
│  └──────────────────┘    └──────────────────┘    └──────────────────────────┘
│                                                                             │
│  ┌──────────────────────┐    ┌──────────────────┐                          │
│  │ snet-logicapps-iso   │    │ snet-pe          │                          │
│  │ 10.50.4.0/24         │───▶│ 10.50.10.0/24    │                          │
│  │ (LA Std Isolated)    │    │ (Private Endpts) │                          │
│  │ + Explicit NSG rules │    └──────────────────┘                          │
│  └──────────────────────┘                                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Connectivity & Hybrid (REQUIRED)

On-prem / hybrid connectivity:

- Connectivity Methods: `none`

> **Note**: No hybrid connectivity required. If future ExpressRoute/VPN is needed, reserve `GatewaySubnet` (10.50.0.0/26).

DNS resolution:

- Strategy: `azure_private_dns`
- Custom DNS Servers: `N/A`
- On-Prem Forwarding Required?: `NO`

### Private DNS Zones Required

| Private DNS Zone | Purpose | VNet Link |
|------------------|---------|-----------|
| `privatelink.blob.core.windows.net` | Storage Blob PE | Yes |
| `privatelink.file.core.windows.net` | Storage File PE | Yes |
| `privatelink.queue.core.windows.net` | Storage Queue PE | Yes |
| `privatelink.table.core.windows.net` | Storage Table PE | Yes |
| `privatelink.vaultcore.azure.net` | Key Vault PE | Yes |
| `privatelink.azurewebsites.net` | Logic Apps PE (inbound) | Yes |

> **Note**: Service Bus uses Service Endpoints (not Private Endpoints), so no privatelink DNS zone is required for it.

---

## 5. Service Privatization & Sizing (REQUIRED)

### APIM Configuration (critical):

- Include APIM?: `yes`
- APIM SKU: `StandardV2` (supports VNet integration, cost-effective)
- APIM Network Mode: `External` (VNet Integrated)
- External Access: `Application Gateway` (WAF v2 for inbound traffic)

> **Architecture**: 
> - Internet → Application Gateway (WAF) → APIM (External VNet mode)
> - APIM uses VNet integration for **outbound** calls to backend Logic Apps
> - APIM remains publicly accessible via App Gateway public IP
> - Backend services accessed via Private Endpoints (Storage, Key Vault) or Service Endpoints (Service Bus)

### Service Networking Matrix

| Service | Required? | Count | SKU/Plan | Networking Mode | Public Access | Notes |
|---------|-----------|-------|----------|-----------------|---------------|-------|
| **Logic Apps (Standard)** | `yes` | `2` | `WS1` | `VNet Injection` | `disabled` | Inbound + Outbound workflows |
| **Logic Apps (Isolated)** | `yes` | `1` | `WS1` | `VNet Injection` | `disabled` | Critical workflows - dedicated subnet with explicit NSG |
| **Service Bus** | `yes` | `1` | `Standard` | `Service Endpoint + Firewall` | `subnet-restricted` | Public access limited to Logic Apps subnets only |
| **Storage (Blob/File/Queue/Table)** | `yes` | `1` | `Standard_LRS` | `Private Endpoint` | `disabled` | Shared storage for all Logic Apps |
| **Key Vault** | `yes` | `1` | `Standard` | `Private Endpoint` | `disabled` | Secrets management |
| **Application Gateway** | `yes` | `1` | `WAF_v2` | `VNet Injection` | `enabled` | Inbound gateway with WAF |
| Azure Functions | `no` | - | - | - | - | Not required |
| Event Grid | `no` | - | - | - | - | Not required |
| Event Hubs | `no` | - | - | - | - | Not required |
| Data Factory | `no` | - | - | - | - | Not required |

### Service Bus Firewall Configuration

**Network Access**: Service Bus Standard SKU uses **Service Endpoints + Firewall rules** instead of Private Endpoints.

| Setting | Value | Notes |
|---------|-------|-------|
| Public network access | `Enabled from selected networks` | Not fully disabled |
| Allow trusted Microsoft services | `Yes` | Required for Azure platform services |
| Default action | `Deny` | Block all by default |
| Virtual network rules | `snet-logicapps`, `snet-logicapps-iso` | Only Logic Apps subnets allowed |

> **Security Trade-off**: Service Bus Standard with Service Endpoints uses the public endpoint with IP/subnet filtering. Traffic flows over Microsoft backbone but the endpoint is technically public. For fully private connectivity, Premium SKU with Private Endpoints is required.

### SKU Justification

| Service | SKU | Justification |
|---------|-----|---------------|
| APIM | StandardV2 | Supports VNet integration for outbound; cost-effective alternative to Premium |
| Service Bus | Standard | Cost-effective; use Service Endpoints + firewall rules to restrict access to specific subnets |
| Logic Apps | Standard (WS1) | Supports VNet integration; Consumption SKU does NOT support VNet |
| Storage | Standard_LRS | Sufficient for Logic Apps state; upgrade to GRS for DR |
| App Gateway | WAF_v2 | WAF protection + zone redundancy capability |

> **Cost Optimization Note**: 
> - APIM StandardV2 is significantly cheaper than Premium while still supporting VNet integration
> - Service Bus Standard with Service Endpoints is cheaper than Premium with Private Endpoints
> - Trade-off: Service Bus will use Service Endpoints (public IP with subnet filtering) instead of Private Endpoints

---

## 6. Subnet Planning (REQUIRED)

### Subnet Layout

| Subnet Name | CIDR | Size | Purpose | Delegation | NSG | Service Endpoints |
|-------------|------|------|---------|------------|-----|-------------------|
| `snet-appgw` | `10.50.1.0/24` | /24 (251 usable) | Application Gateway WAF v2 | None | `nsg-appgw` | None |
| `snet-apim` | `10.50.2.0/24` | /24 (251 usable) | API Management (External VNet) | None | `nsg-apim` | None |
| `snet-logicapps` | `10.50.3.0/24` | /24 (251 usable) | Logic Apps Standard (Inbound + Outbound) | `Microsoft.Web/serverFarms` | `nsg-logicapps` | `Microsoft.ServiceBus` |
| `snet-logicapps-iso` | `10.50.4.0/24` | /24 (251 usable) | Logic Apps Standard (Isolated/Critical) | `Microsoft.Web/serverFarms` | `nsg-logicapps-iso` | `Microsoft.ServiceBus` |
| `snet-pe` | `10.50.10.0/24` | /24 (251 usable) | Private Endpoints (shared) | None | `nsg-pe` | None |

> **Reserved for future use**: 
> - `10.50.0.0/26` - GatewaySubnet (if VPN/ExpressRoute needed)
> - `10.50.5.0/24` to `10.50.9.0/24` - Future expansion

### NSG Rules Summary

#### `nsg-appgw` (Application Gateway)
| Priority | Direction | Source | Destination | Port | Action | Purpose |
|----------|-----------|--------|-------------|------|--------|---------|
| 100 | Inbound | Internet | snet-appgw | 443 | Allow | HTTPS ingress |
| 110 | Inbound | Internet | snet-appgw | 80 | Allow | HTTP ingress (redirect to HTTPS) |
| 120 | Inbound | GatewayManager | snet-appgw | 65200-65535 | Allow | App Gateway health probes |
| 4096 | Inbound | * | * | * | Deny | Default deny |

#### `nsg-apim` (API Management)
| Priority | Direction | Source | Destination | Port | Action | Purpose |
|----------|-----------|--------|-------------|------|--------|---------|
| 100 | Inbound | snet-appgw | snet-apim | 443 | Allow | From App Gateway |
| 110 | Inbound | ApiManagement | snet-apim | 3443 | Allow | Management endpoint |
| 120 | Inbound | AzureLoadBalancer | snet-apim | 6390 | Allow | Azure LB health |
| 200 | Outbound | snet-apim | Storage | 443 | Allow | Azure Storage dependency |
| 210 | Outbound | snet-apim | SQL | 1433 | Allow | Azure SQL dependency |
| 220 | Outbound | snet-apim | AzureKeyVault | 443 | Allow | Key Vault dependency |
| 230 | Outbound | snet-apim | AzureMonitor | 443,1886 | Allow | Monitoring |
| 240 | Outbound | snet-apim | snet-pe | 443 | Allow | Backend services via PE |
| 250 | Outbound | snet-apim | snet-logicapps | 443 | Allow | Logic Apps backends |
| 260 | Outbound | snet-apim | snet-logicapps-iso | 443 | Allow | Isolated Logic Apps backends |
| 4096 | Inbound | * | * | * | Deny | Default deny |

#### `nsg-logicapps` (Standard Logic Apps)
| Priority | Direction | Source | Destination | Port | Action | Purpose |
|----------|-----------|--------|-------------|------|--------|---------|
| 100 | Inbound | snet-apim | snet-logicapps | 443 | Allow | From APIM |
| 110 | Inbound | AzureLoadBalancer | snet-logicapps | * | Allow | Health probes |
| 200 | Outbound | snet-logicapps | snet-pe | 443 | Allow | Storage PE |
| 210 | Outbound | snet-logicapps | ServiceBus | 443,5671-5672 | Allow | Service Bus via Service Endpoint |
| 220 | Outbound | snet-logicapps | AzureMonitor | 443 | Allow | App Insights/Log Analytics |
| 230 | Outbound | snet-logicapps | AzureActiveDirectory | 443 | Allow | Managed Identity auth |
| 240 | Outbound | snet-logicapps | AzureCloud | 443 | Allow | Azure service endpoints |
| 4096 | Inbound | * | * | * | Deny | Default deny |

#### `nsg-logicapps-iso` (Isolated Logic Apps - EXPLICIT RULES)
| Priority | Direction | Source | Destination | Port | Action | Purpose |
|----------|-----------|--------|-------------|------|--------|---------|
| 100 | Inbound | snet-apim | snet-logicapps-iso | 443 | Allow | From APIM only |
| 110 | Inbound | AzureLoadBalancer | snet-logicapps-iso | * | Allow | Health probes |
| 200 | Outbound | snet-logicapps-iso | snet-pe | 443 | Allow | Storage PE only |
| 210 | Outbound | snet-logicapps-iso | ServiceBus | 443,5671-5672 | Allow | Service Bus via Service Endpoint |
| 220 | Outbound | snet-logicapps-iso | AzureMonitor | 443 | Allow | Monitoring |
| 230 | Outbound | snet-logicapps-iso | AzureActiveDirectory | 443 | Allow | Managed Identity |
| 4000 | Outbound | snet-logicapps-iso | Internet | * | Deny | **Block all internet egress** |
| 4096 | Inbound | * | * | * | Deny | Default deny |

> **Critical Isolation Note**: The isolated Logic Apps subnet (`snet-logicapps-iso`) has explicit deny rules for internet egress. All communication must go through Private Endpoints, Service Endpoints, or explicitly allowed service tags.

#### `nsg-pe` (Private Endpoints)
| Priority | Direction | Source | Destination | Port | Action | Purpose |
|----------|-----------|--------|-------------|------|--------|---------|
| 100 | Inbound | snet-apim | snet-pe | 443 | Allow | From APIM |
| 110 | Inbound | snet-logicapps | snet-pe | 443 | Allow | From Logic Apps (Storage) |
| 120 | Inbound | snet-logicapps-iso | snet-pe | 443 | Allow | From Isolated Logic Apps (Storage) |
| 4096 | Inbound | * | * | * | Deny | Default deny |

> **Note**: Service Bus uses Service Endpoints with firewall rules, not Private Endpoints. Only Storage and Key Vault use PEs.

### UDR (User-Defined Routes)

| Route Table | Subnet | Route Name | Prefix | Next Hop |
|-------------|--------|------------|--------|----------|
| `rt-apim` | snet-apim | `ApiManagement` | ApiManagement | Internet |
| `rt-apim` | snet-apim | `default` | 0.0.0.0/0 | Internet |

> **Note**: UDRs ensure APIM management traffic returns correctly. If Azure Firewall is added later, update next-hop accordingly.

---

## 7. Security & Compliance (RECOMMENDED / OPTIONAL)

Network security:

- WAF Enabled?: `yes` (Application Gateway WAF v2)
- DDoS Protection?: `no` (can enable Standard for production if required)
- Traffic Inspection: `no` (no Azure Firewall initially - can add later)

Identity:

- Enforce Managed Identities?: `yes` (system-assigned for all services)
- Azure AD Tenant ID: `(use ARM_TENANT_ID environment variable)`

### Managed Identity & RBAC Matrix

| Service | Identity Type | Target Resource | Role | Scope |
|---------|---------------|-----------------|------|-------|
| Logic Apps (Standard) | System-assigned | Storage Account | `Storage Blob Data Contributor` | Storage Account |
| Logic Apps (Standard) | System-assigned | Storage Account | `Storage Queue Data Contributor` | Storage Account |
| Logic Apps (Standard) | System-assigned | Service Bus | `Azure Service Bus Data Sender` | Service Bus Namespace |
| Logic Apps (Standard) | System-assigned | Service Bus | `Azure Service Bus Data Receiver` | Service Bus Namespace |
| Logic Apps (Isolated) | System-assigned | Storage Account | `Storage Blob Data Contributor` | Storage Account |
| Logic Apps (Isolated) | System-assigned | Service Bus | `Azure Service Bus Data Sender` | Service Bus Namespace |
| Logic Apps (Isolated) | System-assigned | Service Bus | `Azure Service Bus Data Receiver` | Service Bus Namespace |
| Logic Apps (all) | System-assigned | Key Vault | `Key Vault Secrets User` | Key Vault |
| APIM | System-assigned | Key Vault | `Key Vault Secrets User` | Key Vault |
| APIM | System-assigned | Logic Apps | `Website Contributor` | Logic Apps |

> **Note**: Use system-assigned managed identities for all services. No service principal credentials stored in code.

### Compliance Notes

- All data at rest encrypted with Microsoft-managed keys (CMK available via Key Vault if required)
- TLS 1.2 minimum enforced on all services
- Public network access disabled on all PaaS services except Application Gateway frontend

---

## 8. Operations & Reliability (OPTIONAL but recommended)

- Availability Zones?: `yes` (for App Gateway and APIM in francecentral)
- Backup Strategy: `LRS` (upgrade to GRS/ZRS for production)

### Observability Stack

| Component | Resource | Purpose |
|-----------|----------|---------|
| Log Analytics Workspace | `la-pipaas01` | Central log aggregation |
| Application Insights | `appi-pipaas01` | Logic Apps performance monitoring |
| NSG Flow Logs | All NSGs | Network traffic analysis |
| Diagnostic Settings | All services | Platform logs to Log Analytics |

Tagging strategy:

```yaml
tags:
  Environment: dev
  CostCenter: IT-Integration-01
  Owner: Platform Team
  Project: pipaas01
  ManagedBy: Terraform
  Classification: Internal
```

---

## 9. Outputs & Additional Notes

### Naming Convention

Pattern: `{resource_prefix}-{environment}-{organization}-{project}-{instance}`

| Resource | Example Name |
|----------|--------------|
| Resource Group | `rg-dev-clz-pipaas01-01` |
| VNet | `vnet-dev-clz-pipaas01-01` |
| Application Gateway | `agw-dev-clz-pipaas01-01` |
| API Management | `apim-dev-clz-pipaas01-01` |
| Logic App (Inbound) | `la-dev-clz-pipaas01-inbound-01` |
| Logic App (Outbound) | `la-dev-clz-pipaas01-outbound-01` |
| Logic App (Isolated) | `la-dev-clz-pipaas01-critical-01` |
| Service Bus | `sb-dev-clz-pipaas01-01` |
| Storage Account | `stodevclzpipaas0101` |
| Key Vault | `kv-dev-clz-pipaas01-01` |
| Log Analytics | `la-dev-clz-pipaas01-01` |

### Reserved CIDRs / IP Ranges

- VNet: `10.50.0.0/16`
- Avoid: `10.0.0.0/8` commonly used by on-prem - chosen `10.50.x.x` to minimize overlap risk

### Service Principal / Approvers

- Terraform CI/CD: Use GitHub Actions with OIDC federation (recommended) or Service Principal
- Approvers: Platform Team Lead, Cloud Architect
- Contact: platform-team@organization.com

---

## Architecture Summary Diagram

```
                                    ┌─────────────────────────────────────┐
                                    │           INTERNET                  │
                                    └──────────────┬──────────────────────┘
                                                   │
                                                   │ HTTPS (443)
                                                   ▼
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    VNet: 10.50.0.0/16                                        │
│  ┌───────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                            snet-appgw: 10.50.1.0/24                                   │   │
│  │   ┌─────────────────────────────────────────────────────────────────────────────┐     │   │
│  │   │                    Application Gateway (WAF v2)                             │     │   │
│  │   │                    - TLS termination                                        │     │   │
│  │   │                    - WAF protection                                         │     │   │
│  │   │                    - Public IP: agw-pip                                     │     │   │
│  │   └─────────────────────────────────────────────────────────────────────────────┘     │   │
│  └───────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                   │                                          │
│                                                   │ Internal (443)                           │
│                                                   ▼                                          │
│  ┌───────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                            snet-apim: 10.50.2.0/24                                    │   │
│  │   ┌─────────────────────────────────────────────────────────────────────────────┐     │   │
│  │   │                    API Management (Premium - External VNet)                 │     │   │
│  │   │                    - VNet integrated for outbound                           │     │   │
│  │   │                    - Managed Identity enabled                               │     │   │
│  │   └─────────────────────────────────────────────────────────────────────────────┘     │   │
│  └───────────────────────────────────────────────────────────────────────────────────────┘   │
│                          │                                   │                               │
│           ┌──────────────┘                                   └──────────────┐                │
│           │                                                                 │                │
│           ▼                                                                 ▼                │
│  ┌────────────────────────────────────┐              ┌────────────────────────────────────┐  │
│  │   snet-logicapps: 10.50.3.0/24     │              │  snet-logicapps-iso: 10.50.4.0/24  │  │
│  │   ┌────────────────────────────┐   │              │  ┌────────────────────────────┐    │  │
│  │   │ Logic App (Inbound)        │   │              │  │ Logic App (Critical)       │    │  │
│  │   │ - Inbound workflows        │   │              │  │ - Isolated workflows       │    │  │
│  │   └────────────────────────────┘   │              │  │ - Explicit NSG rules       │    │  │
│  │   ┌────────────────────────────┐   │              │  │ - No internet egress       │    │  │
│  │   │ Logic App (Outbound)       │   │              │  └────────────────────────────┘    │  │
│  │   │ - Outbound workflows       │   │              │  ⚠️  RESTRICTED NETWORK ACCESS    │  │
│  │   └────────────────────────────┘   │              └────────────────────────────────────┘  │
│  └────────────────────────────────────┘                              │                       │
│                          │                                           │                       │
│                          └───────────────────┬───────────────────────┘                       │
│                                              │                                               │
│                           Private Endpoints  │  Service Endpoints                            │
│                                              │  (Service Bus)                                │
│                                              ▼                                               │
│  ┌───────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                            snet-pe: 10.50.10.0/24                                     │   │
│  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     ┌─────────────────┐        │   │
│  │   │ Storage PE   │  │ Key Vault PE │  │ Logic Apps   │     │ Service Bus     │        │   │
│  │   │ (blob,file,  │  │              │  │ PE (inbound) │     │ (via Svc Endpt) │        │   │
│  │   │ queue,table) │  │              │  │              │     │ Subnet-filtered │        │   │
│  │   └──────────────┘  └──────────────┘  └──────────────┘     └─────────────────┘        │   │
│  └───────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                         Private DNS Zones (VNet-linked)                               │   │
│  │   privatelink.blob.core.windows.net  │  privatelink.vaultcore.azure.net              │   │
│  │   privatelink.file.core.windows.net  │  privatelink.azurewebsites.net                │   │
│  │   privatelink.queue.core.windows.net │                                               │   │
│  │   privatelink.table.core.windows.net │  (No DNS zone needed for Service Bus)         │   │
│  └───────────────────────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Validation Checklist

- [x] VNet CIDR (10.50.0.0/16) provides sufficient address space
- [x] Subnets do not overlap
- [x] APIM StandardV2 SKU selected (supports VNet integration, cost-effective)
- [x] Service Bus Standard SKU with Service Endpoints + firewall rules (subnet-restricted access)
- [x] Logic Apps Standard SKU selected (not Consumption)
- [x] Isolated Logic Apps have explicit NSG rules blocking internet egress
- [x] Storage and Key Vault have Private Endpoints
- [x] Service Endpoints enabled on Logic Apps subnets for Service Bus
- [x] Private DNS zones defined for PE-enabled services (Storage, Key Vault, Logic Apps)
- [x] Managed Identities configured for all service-to-service communication
- [x] WAF enabled via Application Gateway
- [x] No secrets or credentials in specification (use environment variables)

---

**Specification Complete** - Ready for Terraform code generation
