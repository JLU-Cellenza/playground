# AIS Landing Zone Specification (Fillable)

Purpose: Provide required inputs to generate a secure, private-first Azure Integration Services (AIS) landing zone with Terraform.

Instructions:
- Replace every placeholder wrapped in <...>.
- Fields marked REQUIRED must be completed before generation.
- Conditional fields include a hint when required.
- Keep names lowercase, avoid spaces, and follow examples where provided.

---

## Summary Checklist (required fields to fill)
- Project Name: `<REQUIRED>`
- Organization Abbreviation: `<REQUIRED>`
- Azure Subscription ID: `<REQUIRED>`
- Primary Region: `<REQUIRED>`
- Terraform Backend: `<REQUIRED>`
- VNet CIDR (if creating new): `<REQUIRED/CONDITIONAL>`
- APIM Include? and SKU/Network Mode: `<REQUIRED/CONDITIONAL>`
- Service networking rows marked YES/NO: `<REQUIRED>`

---

## 1. Project Identification (REQUIRED)

Basic information (fill each):

- Project Name: `<REQUIRED> (3-8 lowercase alphanumeric, e.g., ipaas3)`
- Organization Abbreviation: `<REQUIRED> (3-6 lowercase letters, e.g., clz)`
- Project Description: `<REQUIRED> (brief summary of landing zone purpose)`
- Owner / Team: `<REQUIRED> (team or person responsible)`
- Cost Center: `<OPTIONAL>`

Example YAML block (fill accordingly):

```yaml
project_name: <REQUIRED: ipaas3>
organization: <REQUIRED: clz>
description: <REQUIRED: Secure AIS landing zone for payments>
owner: <REQUIRED: Platform Team>
cost_center: <OPTIONAL: IT-Network-01>
```

---

## 2. Azure Configuration (REQUIRED)

Subscription and region details:

- Azure Subscription ID: `<REQUIRED> (GUID or use secret reference)`
- Primary Region: `<REQUIRED> (e.g., francecentral, eastus)`
- Secondary Region: `<OPTIONAL> (e.g., westeurope or None)`
- Terraform Backend: `<REQUIRED>`
  - If using existing backend, provide Storage Account name, Container name, and Key (e.g., `tfstate`, `container`, `landingzone.tfstate`).
  - If you want Terraform to create backend resources, write `create_new` and list desired names below.

Example Backend:

```yaml
backend: <REQUIRED: use_secret | create_new>
backend_storage_account: <if create_new: name>
backend_container: <if create_new: name>
backend_key: <if create_new: landingzone.tfstate>
```

---

## 3. Network Topology & Scale (REQUIRED)

Topology choice (pick one):

- Topology Model: `<REQUIRED: hub-and-spoke | virtual-wan>`

Infrastructure integration:

- Deploy to Existing VNet?: `<REQUIRED: yes | no>`
- If `yes` fill the following:
  - Existing Resource Group: `<REQUIRED if yes>`
  - Existing VNet Name: `<REQUIRED if yes>`

If deploying a new VNet, provide addressing:

- VNet CIDR: `<REQUIRED if creating new> (e.g., 10.10.0.0/16)`
- Subnet mask default sizes: provide target sizes for each subnet below (or accept defaults).

---

## 4. Connectivity & Hybrid (REQUIRED)

On-prem / hybrid connectivity (select one or more):

- Connectivity Methods: `<select: expressroute | vpn_gateway | none>`

DNS resolution:

- Strategy: `<REQUIRED: azure_private_dns | custom_dns>`
- Custom DNS Servers: `<CONDITIONAL: comma-separated IPs>`
- On-Prem Forwarding Required?: `<YES | NO>`

---

## 5. Service Privatization & Sizing (REQUIRED)

APIM (critical):

- Include APIM?: `<REQUIRED: yes | no>`
- If yes, APIM SKU: `<REQUIRED if yes: Developer | Premium | StandardV2>`
- If yes, APIM Network Mode: `<REQUIRED if yes: Internal | External | None>`
- External Access (if Internal and you need external): `<App Gateway | Front Door | None>`

Service networking matrix: copy this block and fill for each service. Use `yes/no` for Required and a numeric Count.

| Service | Required? (yes/no) | Count | SKU/Plan | Networking Mode | Public Access (enabled/disabled) |
|---------|--------------------|-------|----------|-----------------|---------------------------------|
| Logic Apps | `<yes/no>` | `<count>` | `<Standard>` | `<VNet Injection / Public>` | `<disabled|enabled>` |
| Azure Functions | `<yes/no>` | `<count>` | `<Consumption|Premium>` | `<VNet Injection / Public>` | `<disabled|enabled>` |
| Service Bus | `<yes/no>` | `<count>` | `<Standard|Premium>` | `<Private Endpoint>` | `<disabled>` |
| Key Vault | `<yes/no>` | `<count>` | `<Standard|Premium>` | `<Private Endpoint>` | `<disabled>` |
| Storage (Blob) | `<yes/no>` | `<count>` | `<Standard|Premium>` | `<Private Endpoint>` | `<disabled>` |
| Storage (File) | `<yes/no>` | `<count>` | `<Standard>` | `<Private Endpoint>` | `<disabled>` |
| Event Grid | `<yes/no>` | `<count>` | `<Standard>` | `<Private Endpoint>` | `<disabled>` |
| Event Hubs | `<yes/no>` | `<count>` | `<Standard|Premium>` | `<Private Endpoint>` | `<disabled>` |
| Data Factory | `<yes/no>` | `<count>` | `<VNet IR>` | `<Managed PE>` | `<disabled>` |

Notes:
- For APIM in VNet, `Premium` SKU is required for internal mode in many scenarios.
- Private Endpoint means the service will be accessible only via VNet private IPs.

---

## 6. Subnet Planning (REQUIRED)

Proposed subnet layout (ensure no overlap with on-prem):

| Subnet Name | Proposed CIDR | Purpose | Fill Value |
|-------------|---------------|---------|------------|
| GatewaySubnet | `/26` | VPN / ExpressRoute Gateway | `<fill CIDR>` |
| snet-apim | `/24` | API Management | `<fill CIDR>` |
| snet-logicapps | `/24` | Logic Apps VNet Integration | `<fill CIDR>` |
| snet-functions | `/23` | Azure Functions VNet Integration | `<fill CIDR>` |
| snet-pe | `/24` | Private Endpoints (shared) | `<fill CIDR>` |
| snet-appgw | `/24` | Application Gateway (optional) | `<fill CIDR or None>` |

If you change mask sizes, ensure the VNet CIDR supports them.

---

## 7. Security & Compliance (RECOMMENDED / OPTIONAL)

Network security:

- WAF Enabled?: `<yes/no>` (via App Gateway or Front Door)
- DDoS Protection?: `<yes/no>` (Standard recommended for protected public endpoints)
- Traffic Inspection: `<yes/no>` (route via Azure Firewall / NVA)

Identity:

- Enforce Managed Identities?: `<yes/no>` (system assigned where possible)
- Azure AD Tenant ID (if cross-tenant or required): `<OPTIONAL>`

Compliance notes: list any standards to meet (e.g., ISO27001, PCI-DSS)

---

## 8. Operations & Reliability (OPTIONAL but recommended)

- Availability Zones?: `<yes/no>`
- Backup Strategy (required value): `<REQUIRED: e.g., GRS | LRS>`

Tagging strategy (fill required tags):

```yaml
tags:
  Environment: <REQUIRED: dev|prd|test>
  CostCenter: <REQUIRED>
  Owner: <REQUIRED>
  ManagedBy: Terraform
```

---

## 9. Outputs & Additional Notes

- Any special naming policy or prefix to use: `<e.g., clz-ipaas3-> prefix>`
- Approvers / Provisioning contacts: `<list emails or teams>`
- Any known IP ranges to reserve or exclude: `<CIDR list>`

---

If you want, paste the completed YAML or JSON of the filled fields here and I can validate it for Terraform generation or run a quick consistency check (CIDR overlap, missing required fields).
