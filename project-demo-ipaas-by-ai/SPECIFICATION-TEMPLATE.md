# Terraform Specification Template

Use this template to request infrastructure changes with all required context upfront.

## Administrative
- **request_id**: <short-id>
- **requester**: <name/email>
- **date**: <YYYY-MM-DD>
- **priority**: quick-prototype | dev-ready | prod-ready

## Project Identity
- **organization**: <token> (e.g., `cellenza`)
- **project**: <key> (e.g., `mvp-ipaas`)
- **environments**: <list> (e.g., `dev, prd`)
- **region**: <Azure region> (e.g., `francecentral`)

## Azure Account
- **subscription_id**: <ARM_SUBSCRIPTION_ID> or placeholder
- **resource_group**: <name> or allow creation
- **backend**: azurerm | local (provide details or use placeholders)

## Environment Config (per environment)

| Service | Dev | Prd |
|---------|-----|-----|
| APIM | Developer_1 | StandardV2_1 |
| Logic App | WS1 | WS2 |
| Function | Consumption (Y1) | Premium |
| Service Bus | Standard | Premium |
| Storage | Standard LRS | Standard GRS |
| Log Retention | 30 days | 90 days |

## Services Required

| Service | Enabled | Count | Config |
|---------|---------|-------|--------|
| Logic App | yes | 2 | sku: WS1, runtime: node |
| Service Bus | yes | 1 | sku: Standard, queues: [inbound] |
| APIM | yes | 1 | sku: Developer_1, publisher_email: required |
| Function App | yes | 1 | plan: Consumption, runtime: dotnet |
| Storage (function) | yes | 1 | tier: Standard, replication: LRS |
| Storage (logicapp1) | yes | 1 | tier: Standard, replication: LRS |
| Storage (logicapp2) | yes | 1 | tier: Standard, replication: LRS |
| Storage (platform) | yes | 1 | tier: Standard, containers: [configs, templates, schemas] |
| Log Analytics | yes | 1 | retention_days: 30 |
| App Insights | yes | 1 | retention_days: 30 |
| Key Vault | no | — | recommended for prod |

**To override**: modify count, enabled flag, or config values above

## Networking
- **public_access**: true | false (demo vs. prod)
- **private_endpoints**: list of services or none
- **vnet**: use_existing | create_new | none

## Identity & RBAC
List expected role assignments:
- **principal**: <service>
- **target**: <service>
- **role**: <role name>

Example:
```
- principal: function_app → target: servicebus → role: "Azure Service Bus Data Sender"
- principal: function_app → target: storage_platform → role: "Storage Blob Data Contributor"
```

## Secrets
- **key_vault**: create now | use existing | none
- **sensitive_outputs**: mark all secrets as sensitive = true
- **storage_method**: Key Vault | .tfvars.example (dev only)

## Naming & Constraints
- **template**: `<svc>-<env>-<org>-<project>-<purpose>-<instance>` (override if needed)
- **storage_prefix**: stfn, stla, stpl (for name uniqueness)
- **max_name_length**: 24 (storage), 50 (most others)

## Compliance & Monitoring
- **diagnostic_settings**: yes (default)
- **alert_rules**: list top-level alerts or none
- **app_insights_sampling**: rate or default

## Cost
- **monthly_budget**: <€ amount> (optional)
- **force_cost_optimization**: yes | no

## CI/CD (Optional)
- **pipeline**: GitHub Actions | Azure DevOps | none
- **prechecks**: terraform fmt, validate, tflint, tfsec
- **approval_gates**: number_of_approvers (1 or 2)

## Deliverables Checklist (what you will get)
- ✓ modules/ per service (main.tf, variables.tf, outputs.tf, README.md)
- ✓ env/<env>/ (main.tf, variables.tf, locals.tf, outputs.tf, RUNBOOK.md, tfvars.example)
- ✓ ARCHITECTURE.md, CHANGELOG.md, QUICKSTART.md
- ✓ RBAC & diagnostic settings wired
- ✓ All secrets marked sensitive = true
- ✓ terraform validate & fmt pass

## Minimum to Start
- [ ] subscription_id or placeholder
- [ ] resource_group_name or allow creation
- [ ] apim_publisher_email (valid email)
- [ ] environments (dev, prd, etc.)
- [ ] public_access confirmation (demo vs. prod)

## Optional Add-Ons
- [ ] Key Vault module + secret wiring
- [ ] Private Endpoints for Storage/Service Bus
- [ ] Convert role assignments to for_each (reduce duplication)
- [ ] GitHub Actions CI/CD skeleton
- [ ] tflint/tfsec config

---

## Quick Example (YAML format)

```yaml
request_id: ipa-20251106-01
requester: alice@cellenza.com
date: 2025-11-06
priority: dev-ready

project:
  organization: cellenza
  project: mvp-ipaas
  environments: [dev, prd]
  region: francecentral

azure:
  subscription_id: "PLACEHOLDER"
  resource_group: rg-dev-cellenza-mvpipaas-01
  backend: azurerm (provide config or use CLI)

services:
  logic_apps: 2 instances (WS1)
  service_bus: Standard, queue "inbound"
  apim: Developer_1, publisher_email: admin@cellenza.com
  function_app: Consumption, dotnet
  storage: platform (configs, templates, schemas)
  monitoring: Log Analytics + App Insights

networking:
  public_access: true (demo)

rbac:
  - function_app → servicebus (Sender/Receiver)
  - function_app → storage_platform (Blob Contributor)
  - logicapp_01, logicapp_02 → same as function_app

secrets:
  key_vault: false (for now)

cost:
  budget: €300/month
```

---

**Template Version**: 1.0.0  
**Last Updated**: 2025-11-06
