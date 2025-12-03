# Azure AIS Landing Zone - Specification Template

> **Purpose:** This template provides all required information for designing and generating a secure, private-first Azure Integration Services (AIS) landing zone using Terraform.
> 
> **Instructions:** Fill out all sections marked with `[REQUIRED]`. Optional sections can be left blank or removed. The more detail you provide, the more accurate the generated landing zone will be.

---

## 1. Project Identification [REQUIRED]

### Basic Information

| Field | Value | Notes |
|-------|-------|-------|
| **Project Name** | `[REQUIRED]` | 3-8 lowercase alphanumeric characters (e.g., `ipaas3`, `salesint`) |
| **Organization Abbreviation** | `[REQUIRED]` | 3-6 lowercase letters (e.g., `clz` for Cellenza) |
| **Project Description** | `[REQUIRED]` | Brief description of the landing zone purpose |
| **Owner/Team** | `[REQUIRED]` | Team or individual responsible for this platform |
| **Cost Center** | `[OPTIONAL]` | Billing code or cost center |

**Example:**
```yaml
Project Name: ipaas3
Organization: clz
Description: Secure landing zone for enterprise integration
Owner: Platform Team
Cost Center: IT-Network-01
```

---

## 2. Azure Configuration [REQUIRED]

### Subscription & Location

| Field | Value | Notes |
|-------|-------|-------|
| **Azure Subscription ID** | `[REQUIRED]` | Full GUID or "use GitHub Actions secret" |
| **Primary Region** | `[REQUIRED]` | e.g., `francecentral`, `eastus` |
| **Secondary Region** | `[OPTIONAL]` | For failover (e.g., `westeurope`) or "None" |
| **Terraform Backend** | `[REQUIRED]` | Storage Account details or "Create New" |

---

## 3. Network Topology & Scale [REQUIRED]

### Topology Choice

Select the network topology model:

- [ ] **Hub-and-Spoke** (Recommended for 1-2 regions, granular control)
- [ ] **Virtual WAN** (Recommended for global scale, 3+ regions)

### Infrastructure Integration

| Field | Value | Notes |
|-------|-------|-------|
| **Deploy to Existing VNet?** | `[YES/NO]` | If NO, a new VNet will be created |
| **Existing Resource Group** | `[CONDITIONAL]` | Required if deploying to existing VNet |
| **Existing VNet Name** | `[CONDITIONAL]` | Required if deploying to existing VNet |

### Address Space (If Creating New)

| Field | Value | Notes |
|-------|-------|-------|
| **VNet CIDR** | `[REQUIRED]` | e.g., `10.10.0.0/16` |
| **Subnet Mask Size** | `[REQUIRED]` | e.g., `/24` (standard), `/26` (gateway) |

---

## 4. Connectivity & Hybrid [REQUIRED]

### On-Premises Connectivity

Select connectivity method:

- [ ] **ExpressRoute** (High bandwidth, SLA, private peering)
- [ ] **VPN Gateway** (Site-to-Site IPsec)
- [ ] **None** (Cloud-only)

### DNS Resolution

| Field | Value | Notes |
|-------|-------|-------|
| **Strategy** | `[REQUIRED]` | `Azure Private DNS` (Recommended) or `Custom DNS` |
| **Custom DNS Servers** | `[CONDITIONAL]` | List of IPs if using Custom DNS |
| **On-Prem Forwarding** | `[YES/NO]` | Is DNS forwarding to on-prem required? |

---

## 5. Service Privatization & Sizing [REQUIRED]

### API Management (APIM) Design

*Critical component for AIS. Please specify details carefully.*

| Field | Value | Options/Notes |
|-------|-------|---------------|
| **Include APIM?** | `[YES/NO]` | |
| **SKU** | `[REQUIRED]` | `Developer`, `Premium` (Required for VNet), `StandardV2` |
| **Network Mode** | `[REQUIRED]` | `Internal` (Private IP), `External` (Public IP), `None` |
| **External Access** | `[CONDITIONAL]` | `App Gateway`, `Front Door`, or `None` (if Internal mode) |

### Service Networking Matrix

*Define the networking posture for each service. "Private" implies Private Endpoints + VNet Integration where applicable.*

| Service | Required? | Count | SKU | Networking Mode | Public Access |
|---------|-----------|-------|-----|-----------------|---------------|
| **Logic Apps** | `[YES/NO]` | `_` | Standard | VNet Injection | Disabled |
| **Azure Functions** | `[YES/NO]` | `_` | Premium | VNet Injection | Disabled |
| **Service Bus** | `[YES/NO]` | `_` | Premium | Private Endpoint | Disabled |
| **Key Vault** | `[YES/NO]` | `_` | Premium | Private Endpoint | Disabled |
| **Storage (Blob)** | `[YES/NO]` | `_` | Standard | Private Endpoint | Disabled |
| **Storage (File)** | `[YES/NO]` | `_` | Standard | Private Endpoint | Disabled |
| **Event Grid** | `[YES/NO]` | `_` | Premium | Private Endpoint | Disabled |
| **Event Hubs** | `[YES/NO]` | `_` | Premium | Private Endpoint | Disabled |
| **Data Factory** | `[YES/NO]` | `_` | VNet IR | Managed PE | Disabled |

---

## 6. Subnet Planning [REQUIRED]

### Subnet Layout

*Review and adjust the proposed subnet layout. Ensure CIDRs do not overlap with on-prem.*

| Subnet Name | Proposed CIDR | Purpose |
|-------------|---------------|---------|
| `GatewaySubnet` | `/26` | VPN / ExpressRoute Gateway |
| `snet-apim` | `/24` | API Management (Dedicated) |
| `snet-logicapps` | `/24` | Logic Apps VNet Integration |
| `snet-functions` | `/23` | Azure Functions VNet Integration |
| `snet-pe` | `/24` | Private Endpoints (Shared) |
| `snet-appgw` | `/24` | Application Gateway (Optional) |

---

## 7. Security & Compliance [OPTIONAL]

### Network Security

| Feature | Enabled? | Notes |
|---------|----------|-------|
| **WAF (Web App Firewall)** | `[YES/NO]` | Via App Gateway or Front Door |
| **DDoS Protection** | `[YES/NO]` | `Standard` or `Basic` (Platform default) |
| **Traffic Inspection** | `[YES/NO]` | Route via Azure Firewall or NVA? |

### Identity

- [ ] **Enforce Managed Identities** (System Assigned where possible)

---

## 8. Operations & Reliability [OPTIONAL]

### Reliability Settings

| Field | Value | Notes |
|-------|-------|-------|
| **Availability Zones** | `[YES/NO]` | Enable Zone Redundancy where supported? |
| **Backup Strategy** | `[REQUIRED]` | e.g., `GRS` (Geo-Redundant) or `LRS` (Local) |

### Tagging Strategy

List required tags:
```yaml
Environment: <env>
CostCenter: <value>
Owner: <value>
ManagedBy: Terraform
```
