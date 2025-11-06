---
description: 'Agent instructions for generating an Azure Integration Services platform (AIS) using Terraform.'
applyTo: '**/*.tf, **/terraform.tfvars, **/build-ais-platform/**'
---

# Agent Instructions — Build Azure Integration Services (AIS) Platform with Terraform

## Overview & Scope

**Extends:** [terraform.instructions.md](terraform.instructions.md) (general conventions) + [terraform-azure.instructions.md](terraform-azure.instructions.md) (Azure best practices)

**Platform:** Azure Integration Services (AIS) with flexible service composition. Supports any Azure resource via `azurerm_*` provider, including:
- **Core AIS (7):** Logic Apps, APIM, Service Bus, Functions, Key Vault, Log Analytics, App Insights
- **Extended:** Storage, SQL/Cosmos DB, Event Hubs/Grid, App Service, AKS, Application Gateway, Private Endpoints

**Core Requirements:**
- Modular, idempotent Terraform (one module per service; remote state with locking per environment)
- Never commit secrets/credentials/tfstate; require human approval for prod changes
- Follow Azure Well-Architected Framework; all services as reusable, composable modules

**Anti-Patterns (inherited from parent instructions):**
- ❌ Hardcode values, use `local-exec`, complex conditionals, `terraform import` as regular workflow
- ❌ Store secrets in TF files/state; overly permissive RBAC; disable security features; output sensitive data without `sensitive = true`
- ❌ Apply to prod without testing; manual changes to TF-managed resources; run TF from local machines for prod; write to state/`.terraform/` (read-only only)

## Pre-Flight & Module Generation

**Pre-flight checks (before code generation):**
1. Validate Azure auth (`az login`, correct subscription)
2. Identify all required services (list every resource needed)
3. Scan naming collisions (`az resource list --resource-group <RG>`)
4. Verify RG exists (create with approval if missing)
5. Validate service availability in target region(s) + sufficient quotas
6. Document service dependencies (e.g., Functions → Storage)

**Module generation workflow:**
1. **Check [AVM registry](https://azure.github.io/Azure-Verified-Modules/)** first — use existing AVM or build "in style of" AVM (TFNFR standards)
2. **Identify required services** — list all Azure services needed (core AIS 7, data layer, messaging, compute, networking, etc.)
3. **Generate modules:** One module per service/resource cluster
   - Structure: `main.tf`, `variables.tf` (with `type`/`description`), `outputs.tf`, `README.md`
   - Parameterize all inputs (no hardcoded values)
   - Follow consistent naming: `modules/<service-name>/` (e.g., `modules/servicebus/`, `modules/storage/`, `modules/sqldb/`)
4. **Environment overlays:** `env/<env>/` instantiate all modules with env-specific variables
5. **Cross-service wiring:** Expose outputs (e.g., Storage account keys as `sensitive`, Database connection strings, queue/topic IDs)
   - Document all inter-service dependencies in module READMEs
   - Use explicit `depends_on` only when implicit ordering is insufficient
6. **Runbook:** `env/<env>/RUNBOOK.md` with Terraform commands, secret retrieval, rollback steps

## Deployment Workflow

**Local (Agent):** `terraform init` → `terraform fmt -recursive` → `terraform validate` → `terraform plan -out plan.tfplan -var-file=env/dev/dev.tfvars` (review for naming/security/cost)

**CI/CD (Automated):** fmt --check + validate + terraform-compliance/tflint → generate plan artifact → publish plan in PR → approval gate (1 for non-prod, 2 for prod)

**Production (Human):** Approve plan → `terraform apply "plan.tfplan"` → validate (resources exist, connectivity works, logs flow) → rollback if needed (`terraform destroy` or revert commit)

## Naming, Tagging & Resource Strategy

Naming template:

   <svc>-<env>-<org>-<project>-<purpose>-<instance>

Rules (short):
- lowercase letters/numbers only; use hyphens as separators
- svc: 2–4 char service abbrev (e.g., `loa`=Logic App, `svb`=Service Bus, `apim`, `fn`, `kv`, `la`)
- env: `dev`, `test`, `stg`, `prod`
- org: short org token (e.g., `cellenza`)
- project: short project key (no spaces)
- purpose: optional short descriptor (e.g., `messagebox`, `critical`)
- instance: two-digit ordinal, zero-padded (01, 02)
- respect Azure name length limits per resource (recommend ≤63; some services require shorter)

Examples:
- `loa-dev-cellenza-demoProject-critical-01`
- `svb-dev-cellenza-demoProject-messagebox-01`
- `apim-dev-cellenza-demoProject-01`

Tags (mandatory): `project`, `environment`, `owner`, `cost_center`, `created_by` (add org-specific tags as needed).

Resource group guidance: use one RG per environment (e.g., `rg-<org>-<env>-ais`); confirm RG exists before running Terraform. Do not hardcode RG names in modules.

Parameterization: provide `location` and `resource_group_name` via variables; set `ARM_SUBSCRIPTION_ID` as an environment variable (do not hardcode in provider or tfvars).

## Security & Secrets

**Principles:** No secrets in code/tfvars/state; use Key Vault for app secrets; Managed Identities (MI) for all service access (no service principals); least-privilege RBAC; ephemeral secrets (v1.11+) when supported.

**Injection pattern:** TF creates Key Vault (RBAC-based) + MIs with roles (e.g., "Key Vault Secrets User") → app retrieves secrets at runtime via MI → app settings reference Key Vault (`@Microsoft.KeyVault(SecretUri=...)`)

**Outputs:** Mark sensitive outputs `sensitive = true` (TFNFR22); don't output secrets for humans (use Portal/CLI).

**Logging:** Diagnostic settings → Log Analytics (90+ day retention); Azure Monitor alerts for security events; RBAC-restricted log access.

## Terraform Code Standards

**Module structure:** One module per service (`apim`, `logicapp`, `servicebus`, `function_app`, `key_vault`, `log_analytics`, `app_insights`). Files: `main.tf`, `variables.tf` (with `type`/`description` per TFNFR17/18), `outputs.tf`, `README.md`. No hardcoded values; no circular deps; never `depends_on` module outputs.

**Code organization:** `locals.tf` for computed values; pin providers in `versions.tf`; `terraform fmt` (CI enforced); `snake_case` names (TFNFR4/16); place `depends_on` first, `for_each`/`count` next, `lifecycle` last.

**Iteration:** `count` for 0-1 resources; `for_each` (prefer maps) for multiple. Data sources OK in root modules, avoid in reusable modules.

**Idempotency:** Multiple applies = same result; deterministic naming (no random IDs); test: plan → apply → plan (verify no changes).

**Variables/Outputs:** Explicit `type`/`description` (TFNFR17/18); mark sensitive (TFNFR22/23); dynamic blocks for optional nested objects (TFNFR12); only expose needed outputs.

**Repository structure:**
```
ais-platform-terraform/
├── modules/{apim,logicapp,servicebus,function_app,key_vault,log_analytics,app_insights}/
│   └── {main,variables,outputs}.tf + README.md
├── env/{dev,prod}/
│   ├── main.tf + variables.tf + outputs.tf
│   ├── {dev,prod}.tfvars.example
│   └── RUNBOOK.md
├── backend.tf + provider.tf + versions.tf + .gitignore + README.md + CHANGELOG.md
```

## Service-Specific Implementation Rules

**Universal Module Pattern:** All services follow this structure:
- `main.tf`, `variables.tf` (with `type`/`description`), `outputs.tf`, `README.md`
- Parameterize all inputs; never hardcode
- Mark sensitive outputs (connection strings, keys) as `sensitive = true`
- Use Managed Identities for all cross-service access (RBAC-based)
- Store secrets in Key Vault; apps retrieve via MI

**Service Reference Table:**

| Service | Purpose | Key Variables | Key Outputs | Cross-Service Integration |
|---------|---------|---------------|-------------|---------------------------|
| **Service Bus** | Async messaging hub | `sku` (Standard/Premium), `central_queue_name`, `max_delivery_count`, `lock_duration` | `namespace_id`, `primary_connection_string` (*sensitive*) | Functions/Logic Apps need "Service Bus Data Sender" role |
| **APIM** | API gateway, rate limiting | `sku`, `publisher_name`, `publisher_email` | `gateway_url`, `developer_portal_url` | Connects to backend services; diagnostic logs → Log Analytics |
| **Logic Apps** | Workflow orchestration | `enabled`, `integration_account_id` | `workflow_id`, `workflow_url` | Use Managed Identity for connectors; trigger from Service Bus/Event Hubs |
| **Functions** | Serverless compute | `plan_sku` (Consumption/Premium), `storage_account_tier` | `identity_principal_id`, `function_app_name` | Requires Storage Account; RBAC roles for Service Bus/Storage |
| **Key Vault** | Secrets management | `soft_delete`, `purge_protection`, `sku` | `vault_uri` | All services read secrets via MI; connection strings stored here |
| **Log Analytics** | Centralized logging | `retention_in_days`, `sku` | `workspace_id`, `workspace_customer_id` | Diagnostic settings from all services |
| **App Insights** | APM monitoring | `retention_in_days` | `instrumentation_key` | Linked to Log Analytics; auto-instruments Functions/Logic Apps |
| **Storage** | Blob/file/queue/table | `tier`, `replication_type` (LRS/GRS), `access_tier` (Hot/Cool), `containers` | `connection_string` (*sensitive*), `primary_blob_endpoint` | Functions require Storage; RBAC: Storage Blob Data Contributor |
| **SQL Database** | Relational OLTP | `sku` (S0/S1/P1), `backup_retention_days`, `threat_detection` | `server_fqdn`, `connection_string` (*sensitive*) | Store connection in Key Vault; enable auditing → Log Analytics |
| **Cosmos DB** | NoSQL multi-region | `api` (SQL/MongoDB), `consistency_level`, `geo_locations`, `backup_type` | `endpoint`, `connection_string` (*sensitive*) | Use MI if supported; store connection in Key Vault |
| **Event Hubs** | Streaming ingestion | `sku`, `partition_count`, `retention`, `capture_enabled` | `connection_string` (*sensitive*) | Functions/Logic Apps trigger from Event Hubs; Stream Analytics reads |
| **App Gateway** | Layer 7 LB, WAF | `tier`, `backend_pool_fqdns`, `enable_waf`, `certificate_path` | `frontend_ip`, `gateway_url` | Routes to App Service/Functions; SSL cert from Key Vault |

**SKU Defaults:** Standard/Consumption for dev; Premium for prod (where applicable). Retention: 30 days (dev), 90 days (prod).

**Use Case Decision Matrix:**

| Use Case | Services | Rationale |
|----------|----------|-----------|
| Integration platform w/ APIs | AIS 7 (APIM, Logic Apps, Service Bus, Functions, Key Vault, Log Analytics, App Insights) | Orchestrate workflows, expose APIs, async messaging |
| Add data layer | AIS 7 + Storage + SQL/Cosmos DB | Persistent data, analytics, OLTP/OLAP |
| Event streaming | Event Hubs + Stream Analytics + Storage + Log Analytics | Real-time ingestion, aggregations |
| Secure hybrid | App Gateway + Private Endpoints + Key Vault + MIs | WAF protection, TLS termination |
| Multi-tenancy | AIS 7 + Cosmos DB (multi-partition) + APIM (rate limiting) | Isolated data, API versioning |

**Adding New Services:** Follow universal module pattern → parameterize → expose outputs → document dependencies → update `env/<env>/main.tf` → add RBAC → update `RUNBOOK.md`

## CI/CD, Validation & Testing

### Pre-Commit Checks (Local, Before PR)
- [ ] **Run `terraform fmt -recursive`** — fail if formatting is wrong (per [terraform.instructions.md](terraform.instructions.md) § Style and Formatting)
- [ ] **Run `terraform validate`** — syntax and consistency check
- [ ] **Run `terraform plan`** and review the plan output for unexpected changes
- [ ] **Run `tflint`** to check for style violations and best practices (per [terraform.instructions.md](terraform.instructions.md))
- [ ] **Scan for secrets** using `truffleHog` or `detect-secrets` CLI
- [ ] **Check for anti-patterns** — no hardcoded values, no `local-exec` provisioners, no service principals (per [terraform-azure.instructions.md](terraform-azure.instructions.md) § Anti-Patterns to Avoid)
- [ ] **Update `CHANGELOG.md`** with a summary of changes and PR reference
- [ ] **Test idempotency** — run plan twice and confirm both produce same result

### CI Pipeline Checks (GitHub Actions / Azure DevOps)
Per [terraform.instructions.md](terraform.instructions.md) and [terraform-azure.instructions.md](terraform-azure.instructions.md):

1. **Format check:** `terraform fmt --check -recursive` (fail if formatting needed)
2. **Validation:** `terraform validate` (syntax check)
3. **Security scan:** `tfsec` or `checkov` (flag insecure practices)
4. **Compliance check:** `terraform-compliance` (enforce naming, tagging, resource types)
5. **Artifact generation:** Run `terraform plan -out plan.tfplan` (use `ARM_SUBSCRIPTION_ID` env var, not in code per [terraform-azure.instructions.md](terraform-azure.instructions.md))
6. **Plan comment:** Post plan output in PR for human review
7. **Approval gate:** Block merge until 1 (non-prod) or 2 (prod) approvals received
8. **Documentation check:** Verify README.md and RUNBOOK.md exist and are updated

### Manual Review Checklist (Human Reviewer)
Per [terraform-azure.instructions.md](terraform-azure.instructions.md) § Validation:

- [ ] **Ask before plan:** Verify the requester has explicitly asked for this plan
- [ ] **Naming:** All resources follow `<project>-<env>-<service>-<purpose>` pattern with CAF abbreviations
- [ ] **Tagging:** All resources have required tags (`project`, `environment`, `owner`, `cost_center`, `created_by`)
- [ ] **Security:** No hardcoded secrets, API keys, or connection strings; all use Key Vault or MI; no overly permissive RBAC
- [ ] **Costs:** No unexpected expensive resources; SKUs are appropriate per environment (Consumption for dev, Premium for prod where needed)
- [ ] **Dependencies:** Cross-service dependencies are correctly wired (e.g., Function App MI has RBAC role to access Service Bus); no circular dependencies; `depends_on` used only when necessary
- [ ] **Idempotency:** Code is idempotent (re-running apply makes no destructive changes)
- [ ] **State management:** Remote backend is configured; state locking enabled; no state file in repo
- [ ] **Anti-patterns:** No hardcoded values, no `local-exec` provisioners, no service principals (per [terraform-azure.instructions.md](terraform-azure.instructions.md))
- [ ] **Existing resources:** If deploying to existing hub-and-spoke network, validate VNet/subnet references are correct (per [terraform-azure.instructions.md](terraform-azure.instructions.md) § Networking Considerations)

### Testing & Validation Post-Apply
Per [terraform-azure.instructions.md](terraform-azure.instructions.md) § Validation:

1. **Resource creation:** Verify all resources exist in Azure Portal or CLI
2. **Identity & RBAC:** Confirm Managed Identities have correct RBAC roles (check via Azure Portal or `az role assignment list`)
3. **Connectivity:** Test Service Bus queue receives/processes messages
4. **Monitoring:** Confirm logs flow to Log Analytics; Application Insights captures traces
5. **Rollback test (non-prod only):** Destroy and re-apply to validate idempotency

### Failure Modes & Recovery

| Failure Mode | Detection | Recovery |
|--------------|-----------|----------|
| **Naming collision** | `terraform plan` fails with "name already exists" | Query existing resources; update naming strategy; increment counter or suffix |
| **Secrets in tfstate** | `detect-secrets` or manual scan finds plaintext | Rotate secret in Azure; destroy/re-apply with correct Key Vault config; never commit tfstate |
| **Missing RBAC role** | Function App cannot reach Service Bus (runtime error) | Add missing role assignment; re-run `terraform apply` |
| **State lock conflict** | `terraform apply` times out waiting for lock | Check for stuck agent/pipeline; release lock via Azure CLI; retry |
| **Provider version mismatch** | `terraform init` fails | Update `.terraform.lock.hcl` or lock file; run `terraform init`; pin versions in `versions.tf` |
| **Subscription ID wrong** | `terraform plan` fails with auth error | Confirm `ARM_SUBSCRIPTION_ID` env var is set; never hardcode in provider.tf (per [terraform-azure.instructions.md](terraform-azure.instructions.md)) |
| **Existing RG not found** | `terraform plan` fails to reference existing RG | Create RG manually or via separate Terraform; confirm name and subscription |

## Deliverables Checklist

Per work item / PR, deliver:
- [ ] **Service inventory** — list of all services being deployed
- [ ] **Modules** — each service in `modules/<service-name>/` with `main.tf`, `variables.tf`, `outputs.tf`, `README.md`
- [ ] **Environment overlay** — `env/<env>/main.tf` instantiates modules with env-specific vars
- [ ] **Example tfvars** — `env/<env>/<env>.tfvars.example` (no secrets)
- [ ] **Runbook** — `env/<env>/RUNBOOK.md` with TF commands, secret retrieval, RBAC, rollback steps
- [ ] **Documentation** — Module READMEs with purpose, inputs, outputs, dependencies, examples
- [ ] **Cross-service wiring** — All dependencies documented (e.g., Function App → Storage)
- [ ] **RBAC assignments** — All MI role assignments in Terraform (not manual)
- [ ] **Changelog** — `CHANGELOG.md` entry with services added, changes, PR reference

## Decision Matrix: When to Choose What

| Scenario | Decision | Rationale | Reference |
|----------|----------|-----------|-----------|
| **Use Azure Verified Modules (AVM)?** | Yes, if available. If not, build module "in the style of" AVM (follow TFNFR naming/structure). | AVMs align to Well-Architected Framework, reduce maintenance, supported by Microsoft. | [terraform-azure.instructions.md](terraform-azure.instructions.md) § Use Azure Verified Modules (AVM) |
| **Terraform resources vs. ARM templates for Logic Apps?** | Use native Terraform for simple workflows (< 5 actions); use ARM templates for complex B2B workflows. | Terraform is simpler to version control; ARM templates offer fine-grained control. | Platform-specific |
| **Consumption vs. Premium Function Plan?** | Consumption for dev/test; Premium for prod (higher throughput, guaranteed scale). | Cost-optimize non-prod; ensure perf/reliability in prod. | [terraform-azure.instructions.md](terraform-azure.instructions.md) § Cost Management |
| **Service Bus SKU?** | Standard for dev/test; Premium for prod with compliance or high throughput needs. | Standard is cheaper and sufficient for integration testing. | [terraform-azure.instructions.md](terraform-azure.instructions.md) § Cost Management |
| **Soft-delete & purge protection in Key Vault?** | Always true for prod; set via variable for dev (default: false). | Prevent accidental data loss in prod; allow cleanup in dev. | [terraform-azure.instructions.md](terraform-azure.instructions.md) § Security and Compliance |
| **RBAC vs. Access Policies in Key Vault?** | Prefer RBAC (modern, Azure-wide). Use access policies only if org policy mandates it. | RBAC is simpler, more auditable, aligns to Azure best practices. | [terraform-azure.instructions.md](terraform-azure.instructions.md) § Security and Compliance |
| **Log retention?** | 30 days for dev/test; 90+ days for prod (configurable per org policy). | Comply with compliance reqs; minimize costs in non-prod. | [terraform-azure.instructions.md](terraform-azure.instructions.md) § Cost Management |
| **Use `count` or `for_each`?** | `count` for 0-1 resources; `for_each` for multiple. Prefer maps for stable addresses. | `for_each` with maps avoids address drift when items change order. | [terraform.instructions.md](terraform.instructions.md) § Iteration |
| **Hardcode vs. parameterize?** | Always parameterize. Never hardcode values that vary by environment or deployment. | Enables code reuse, prevents mistakes, supports multiple environments. | [terraform.instructions.md](terraform.instructions.md) § Maintainability |
| **Use data sources in modules?** | No. Avoid data sources in reusable modules; use explicit parameters instead. | Data sources introduce implicit state dependencies and slow plan/apply. | [terraform.instructions.md](terraform.instructions.md) § Maintainability |
| **Use `depends_on`?** | Only when necessary to resolve implicit dependencies. Never depend on module outputs. | Reduces coupling; implicit dependencies via resource references are preferred. | [terraform.instructions.md](terraform.instructions.md) § Follow recommended Terraform practices |

## Ambiguity & Decision Requests

**Pause and ask for clarification if missing:**
1. **Project name** — used in resource naming (e.g., "integ", "ais", "fabrikam")
2. **Cost center / billing code** — for tagging and cost allocation
3. **Environment + SKUs** — which envs (dev/test/prod)? SKU per env?
4. **Service inventory** — explicit list of all Azure services needed (e.g., "AIS 7 + Storage + SQL + Event Hubs")
5. **Data requirements** — for data services: volume, OLTP/OLAP, failover needs
6. **Compliance** — log retention, encryption, data residency, regulatory standards (HIPAA, SOC 2)
7. **Existing infrastructure** — hub-and-spoke VNet? Existing RG/Key Vault?
8. **DR/HA requirements** — multi-region? RTO/RPO? Premium SKU needs?

When uncertain, create **OPTIONS.md** listing 2–3 choices with pros/cons; ask for human approval before coding.

## Rollback & Disaster Recovery

### Planned Rollback (Correct Mistakes)
1. Revert the commit: `git revert <commit-hash>`
2. Get new plan: `terraform plan -out plan.tfplan`
3. Review and approve the new plan
4. Apply: `terraform apply "plan.tfplan"`

### State Corruption (Emergency)
1. **Backup current state:** `az storage blob download --container-name tfstate --name <env>.tfstate --file backup.tfstate`
2. **Identify missing/incorrect resources:** Compare Azure resources to tfstate using `terraform state list` and `terraform state show`
3. **Repair state:** Remove bad resource: `terraform state rm azurerm_resource.bad_resource`
4. **Re-import or re-create:** Re-import or edit the resource via Terraform
5. **Contact infra owner** if state cannot be recovered

### Disaster (Complete Infrastructure Failure)
1. Confirm backups of state file exist (stored in Azure Storage with versioning enabled)
2. Restore state from backup: `az storage blob download --version-id <backup-version>`
3. Deploy from restored state: `terraform apply`

## Operator Etiquette & Behavioral Guardrails

1. **Small commits** — one service module per PR; avoid mega-commits
2. **Document decisions** — add comments in `main.tf` for non-default SKUs or custom service mix
3. **Ask before assuming** — if uncertain, create OPTIONS.md; ask for guidance
4. **Confirm services early** — list all services upfront; confirm with stakeholders before coding
5. **Never apply to prod unilaterally** — always require human approval
6. **Write defensively** — anticipate wrong inputs; add pre-flight checks
7. **Communicate clearly** — PR descriptions explain what was created/changed/destroyed
8. **Test idempotency** — verify plan → apply → plan produces no changes
9. **Clean up** — destroy test resources; no artifacts left behind
10. **Document architecture** — provide diagram showing service relationships and data flow

---

## References & Hierarchy

This document is **platform-specific** guidance and **inherits from** (and must be read alongside) these foundational instruction files:

1. **[terraform.instructions.md](terraform.instructions.md)** — Core Terraform conventions apply to all platforms.
   - Used for: Module design, code style, security, testing, maintainability, documentation.
   - Deviations: This file is cloud-agnostic (includes AWS references); apply Azure equivalents as needed.

2. **[terraform-azure.instructions.md](terraform-azure.instructions.md)** — Azure-specific Terraform best practices.
   - Used for: AVM usage, Azure resource naming (CAF), RBAC, Key Vault, Managed Identities, state management, validation.
   - Deviations: None; this document extends those guidelines with platform-specific patterns.

### When in Doubt
- Check **terraform-azure.instructions.md** first for Azure-specific guidance.
- Check **terraform.instructions.md** for general Terraform principles.
- Check **build-ais-platform.instructions.md** for AIS architecture and service-specific configuration.

### Conflict Resolution
If guidance conflicts across files:
1. **Security directives override all** (e.g., never hardcode secrets, even if a pattern suggests it).
2. **Azure-specific guidance (terraform-azure.instructions.md) overrides general guidance** (e.g., use ARM_SUBSCRIPTION_ID env var, not service principal in code).
3. **Platform-specific guidance (build-ais-platform.instructions.md) overrides general guidance** (e.g., seven services, central message box pattern).

---

End of instructions.
