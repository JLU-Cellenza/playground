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

## Backend Configuration & Tfvars Files for CI/CD

**CRITICAL: GitHub Actions workflows require `backend.tfvars` and environment-specific `.tfvars` files to be committed to the repository.**

### Files That MUST Be Committed

Unlike traditional Terraform projects where tfvars files are gitignored, **CI/CD workflows need these files in version control** to function properly:

**Required files per environment:**
```
project-name/
├── env/dev/
│   ├── backend.tfvars      # ✅ COMMIT THIS - Backend configuration (no secrets)
│   ├── dev.tfvars          # ✅ COMMIT THIS - Environment variables (no secrets)
│   └── dev.tfvars.example  # ✅ COMMIT THIS - Template for local development
└── apim/                   # If APIM module exists
    ├── backend.tfvars      # ✅ COMMIT THIS - APIM backend configuration
    └── dev.tfvars          # ✅ COMMIT THIS - APIM environment variables
```

**Why these files must be committed:**
- GitHub Actions workflows run `terraform init -backend-config=backend.tfvars`
- Workflows run `terraform plan -var-file=dev.tfvars`
- Without these files in the repo, workflows fail with "file not found" errors
- These files contain **configuration, not secrets** — Azure credentials come from GitHub Secrets

### Backend Configuration Pattern

**`env/dev/backend.tfvars` example:**
```hcl
resource_group_name  = "rg-common-iac-01"
storage_account_name = "stocommoniac01"
container_name       = "terraform"
key                  = "project-name-dev.tfstate"
```

**`apim/backend.tfvars` example (if APIM exists):**
```hcl
resource_group_name  = "rg-common-iac-01"
storage_account_name = "stocommoniac01"
container_name       = "terraform"
key                  = "project-name-dev-apim.tfstate"  # Different state file
```

**Key principles:**
- ✅ **DO commit:** Resource group name, storage account name, container name, state file key
- ❌ **DO NOT commit:** Access keys, SAS tokens, service principal credentials (use GitHub Secrets)
- ✅ **DO use:** Same storage account for all projects, different state file keys per project/environment
- ✅ **DO separate:** APIM state file from main platform state file (different keys)

### Environment Variables Pattern

**`env/dev/dev.tfvars` example:**
```hcl
# Azure region
location = "francecentral"

# Naming components (no secrets)
environment  = "dev"
organization = "clz"
project      = "ipaas3"

# Tagging (no secrets)
cost_center = "demo"
owner       = "cellenza"

# Service configuration (no secrets)
log_retention_days = 30
apim_sku_name      = "Developer_1"  # Or "StandardV2_1" for prod
```

**`apim/dev.tfvars` example (if APIM exists):**
```hcl
# Reference to existing resources created by main platform
resource_group_name           = "rg-dev-clz-ipaas3-01"
log_analytics_workspace_name  = "la-dev-clz-ipaas3-01"

# APIM-specific configuration
location             = "francecentral"
environment          = "dev"
organization         = "clz"
project              = "ipaas3"
apim_publisher_name  = "Cellenza"
apim_publisher_email = "contact@cellenza.com"
apim_sku_name        = "Developer_1"  # Or "StandardV2_1" for prod

# Tagging
cost_center = "demo"
owner       = "cellenza"
```

### What NOT to Commit (Security)

**Never commit these to version control:**
- ❌ Storage account access keys or SAS tokens
- ❌ Service principal client secrets
- ❌ Azure subscription IDs (use `ARM_SUBSCRIPTION_ID` environment variable)
- ❌ Terraform state files (`*.tfstate`, `*.tfstate.backup`)
- ❌ `.terraform/` directory (downloaded providers/modules)
- ❌ Any files containing passwords, API keys, certificates, or connection strings

**Use GitHub Secrets for:**
- `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
- `TF_BACKEND_STORAGE_ACCOUNT`, `TF_BACKEND_CONTAINER`, `TF_BACKEND_KEY` (if not using backend.tfvars)
- Any application-specific secrets that need to be stored in Key Vault

### `.gitignore` Configuration

**Recommended `.gitignore` for AIS platform projects:**
```gitignore
# Terraform state files (NEVER commit)
*.tfstate
*.tfstate.*
*.tfstate.backup

# Terraform directories (NEVER commit)
.terraform/
.terraform.lock.hcl

# Crash log files
crash.log
crash.*.log

# Override files (local development)
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Local environment files (NEVER commit)
.env
.env.local

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# NOTE: Do NOT ignore backend.tfvars or <env>.tfvars files
# They are needed for CI/CD workflows and contain no secrets
```

### Migration Strategy (Existing Projects)

If you have an existing project where tfvars files were gitignored:

1. **Review files for secrets:** Ensure `backend.tfvars` and `dev.tfvars` contain NO secrets
2. **Force-add files:** `git add -f env/dev/backend.tfvars env/dev/dev.tfvars`
3. **Commit:** `git commit -m "feat: Add backend and tfvars files for CI/CD workflows"`
4. **Verify:** Check that files appear in GitHub repository
5. **Test workflow:** Trigger CI workflow to confirm it can now access the files

### Troubleshooting CI/CD Failures

**Error: "backend.tfvars: no such file or directory"**
- **Cause:** File not committed to repository
- **Fix:** `git add -f env/dev/backend.tfvars` then commit and push

**Error: "dev.tfvars: no such file or directory"**
- **Cause:** File not committed to repository
- **Fix:** `git add -f env/dev/dev.tfvars` then commit and push

**Error: "Error loading backend config: access denied"**
- **Cause:** GitHub Secrets missing or incorrect (AZURE_CLIENT_ID, etc.)
- **Fix:** Verify GitHub Secrets are configured correctly in repository settings

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

### Terraform Service Principal RBAC for Key Vault

**CRITICAL:** When Terraform manages Key Vault secrets, the **Terraform service principal (GitHub Actions, local automation, or CI/CD runner)** must have explicit RBAC permission to write secrets. Failure to assign this role results in HTTP 403 "Forbidden" errors during `terraform apply`.

**Problem Scenario:**
```
Error: checking for presence of existing Secret "my-secret"
(Key Vault "https://my-kv.vault.azure.net/"):
StatusCode=403 Code="Forbidden"
Message="Caller is not authorized to perform action on resource.
Action: 'Microsoft.KeyVault/vaults/secrets/getSecret/action'"
Caller: appid=***;oid=8debc977-96ec-4cf6-880f-6f28975af211
Assignment: (not found)
```

**Root Cause:** The Terraform automation principal has no role assignment on the Key Vault, even if deployed applications (Logic Apps, Functions) have roles assigned.

**Solution: Auto-Assign RBAC via Terraform**

Add this to `env/<env>/main.tf` **BEFORE** creating any secrets:

```hcl
# Fetch current Terraform service principal context
data "azurerm_client_config" "current" {}

# Grant Terraform service principal "Key Vault Secrets Officer" role
# This allows Terraform to create, read, update, delete secrets during deployment
resource "azurerm_role_assignment" "terraform_keyvault_secrets_officer" {
  scope                = module.keyvault.vault_id  # or azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id  # Auto-detects current principal
}

# Dependency: All secrets depend on this role assignment
resource "azurerm_key_vault_secret" "example" {
  depends_on = [azurerm_role_assignment.terraform_keyvault_secrets_officer]
  
  name         = "my-secret"
  value        = "secret-value"
  key_vault_id = module.keyvault.vault_id
}
```

**Why This Works:**
1. `data.azurerm_client_config.current.object_id` automatically resolves to the **identity running Terraform** (GitHub Actions service principal, local user, local service account, etc.)
2. `azurerm_role_assignment` grants that principal the "Key Vault Secrets Officer" role on the Key Vault
3. `depends_on` ensures the role assignment is created **before** secrets are written
4. Role propagation typically takes 30–60 seconds; Azure eventually grants access

**RBAC Role Assignments Required:**

| Principal | Role | Scope | Purpose |
|-----------|------|-------|---------|
| **Terraform Service Principal** | `Key Vault Secrets Officer` | Key Vault | Create/update/delete secrets during `terraform apply` |
| **Application MI (Logic App)** | `Key Vault Secrets User` | Key Vault | Read secrets at runtime |
| **Application MI (Functions)** | `Key Vault Secrets User` | Key Vault | Read secrets at runtime |

**Complete Example (env/dev/main.tf):**

```hcl
module "keyvault" {
  source = "../../modules/keyvault"
  name   = local.keyvault_name
  # ... other variables
}

data "azurerm_client_config" "current" {}

# ✅ Terraform: Can create/manage secrets
resource "azurerm_role_assignment" "terraform_keyvault_secrets_officer" {
  scope                = module.keyvault.vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ✅ Logic App: Can read secrets at runtime
resource "azurerm_role_assignment" "logicapp_keyvault_secrets_user" {
  scope                = module.keyvault.vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.logicapp.identity_principal_id
}

# ✅ Secrets: Depend on Terraform's role assignment
resource "azurerm_key_vault_secret" "servicebus_connection" {
  depends_on = [azurerm_role_assignment.terraform_keyvault_secrets_officer]
  
  name         = "servicebus-connection-string"
  value        = module.servicebus.primary_connection_string
  key_vault_id = module.keyvault.vault_id
}
```

**GitHub Actions Workflow Setup:**

Ensure the GitHub Actions runner has the correct Azure credentials via `AZURE_CREDENTIALS` secret:

```yaml
- name: Azure Login
  uses: azure/login@v2
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}
  env:
    ARM_SUBSCRIPTION_ID: 3314da4a-7f83-4380-9d92-7b96c6fa78c6
    ARM_CLIENT_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).clientId }}
    ARM_CLIENT_SECRET: ${{ fromJson(secrets.AZURE_CREDENTIALS).clientSecret }}
    ARM_TENANT_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).tenantId }}
```

The service principal referenced in `AZURE_CREDENTIALS` will automatically receive the role assignment via Terraform.

**Local Deployment (Developer Machine):**

If running Terraform locally, ensure your Azure CLI login identity has sufficient permissions:

```bash
# Login as the service principal or user running Terraform
az login --service-principal \
  -u $ARM_CLIENT_ID \
  -p $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID

# Verify you have "Contributor" role on the subscription
az role assignment list --assignee "$(az ad signed-in-user show --query id -o tsv)" \
  --scope "/subscriptions/$ARM_SUBSCRIPTION_ID"

# The role assignment resource in Terraform will grant yourself "Key Vault Secrets Officer"
terraform apply
```

**Troubleshooting:**

| Error | Cause | Solution |
|-------|-------|----------|
| `StatusCode=403 Forbidden` | Terraform principal has no Key Vault role | Add `azurerm_role_assignment` with `terraform_keyvault_secrets_officer` |
| `Principal does not exist` | Service principal OID is incorrect or expired | Verify `data.azurerm_client_config.current.object_id` resolves correctly |
| `Role propagation delay` | RBAC assignment exists but hasn't propagated | Wait 60–120 seconds and re-run `terraform apply` |
| `AzureRequestFailed: 401 Unauthorized` | Azure credentials expired or invalid | Re-run `az login` or refresh GitHub Actions credentials |

**Security Best Practice:** After secrets are created, consider removing the Terraform service principal's "Key Vault Secrets Officer" role and replacing it with time-limited access via temporary credentials or OIDC federation. This limits the attack surface if credentials are compromised.

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
│   ├── backend.tfvars (✅ COMMITTED - no secrets)
│   ├── {dev,prod}.tfvars (✅ COMMITTED - no secrets)
│   ├── {dev,prod}.tfvars.example
│   └── RUNBOOK.md
├── apim/ (if APIM module exists)
│   ├── main.tf + variables.tf + outputs.tf + terraform.tf
│   ├── backend.tfvars (✅ COMMITTED - separate state file key)
│   └── {dev,prod}.tfvars (✅ COMMITTED - references existing resources)
├── .gitignore (excludes *.tfstate, .terraform/, but NOT backend.tfvars or <env>.tfvars)
├── backend.tf + provider.tf + versions.tf + README.md + CHANGELOG.md
```

## Service-Specific Implementation Rules

**CRITICAL: Azure Provider Version**
- **MUST use Azure provider `~> 4.0`** for Logic Apps Standard compatibility
- Provider v4.x is required for `azurerm_logic_app_standard` with proper monitoring integration
- Pin version in all `terraform.tf` or `versions.tf` files: `version = "~> 4.0"`

**CRITICAL: APIM Separation**
- **APIM must ALWAYS be deployed in a separate Terraform configuration** (`apim/` folder)
- Main platform (`env/dev/`) includes all services EXCEPT APIM
- APIM deployment uses data sources to reference existing RG and Log Analytics
- Use same backend storage account but different state file keys (e.g., `project-dev.tfstate` vs `project-dev-apim.tfstate`)
- Create dedicated GitHub workflows: `terraform-apim-deploy.yml` and `terraform-apim-destroy.yml`
- Rationale: Azure provider bug causes 401 errors when reading APIM delegation validation keys immediately after creation due to managed identity propagation delays (15-30 minutes)

**APIM Deployment Structure:**
```
project/
├── env/dev/
│   ├── main.tf          # All services EXCEPT APIM
│   ├── backend.tfvars   # key = "project-dev.tfstate"
│   └── ...
├── apim/
│   ├── main.tf          # Data sources + APIM module only
│   ├── terraform.tf     # Provider config (separate from main platform)
│   ├── backend.tfvars   # SAME storage account, key = "project-dev-apim.tfstate"
│   ├── dev.tfvars       # References existing RG and Log Analytics names
│   └── README.md        # Deployment order, troubleshooting
└── .github/workflows/
    ├── terraform-apim-deploy.yml    # Manual trigger, 25-30 min warning
    └── terraform-apim-destroy.yml   # Manual trigger, DESTROY-APIM confirmation
```

**APIM main.tf Pattern:**
```hcl
# Data sources for existing resources (created by main platform)
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

data "azurerm_log_analytics_workspace" "this" {
  name                = var.log_analytics_workspace_name
  resource_group_name = var.resource_group_name
}

# APIM module
module "apim" {
  source = "../modules/apim"

  apim_name                  = var.apim_name
  location                   = data.azurerm_resource_group.this.location
  resource_group_name        = data.azurerm_resource_group.this.name
  publisher_name             = var.apim_publisher_name
  publisher_email            = var.apim_publisher_email
  sku_name                   = var.apim_sku
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.this.id

  tags = var.tags
}
```

**Deployment Order:**
1. Deploy main platform first → creates RG, Log Analytics, all services except APIM (5-10 minutes)
2. Deploy APIM separately → uses data sources to reference existing resources (25-30 minutes)

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
| **Logic Apps** | Workflow orchestration | `sku_name` (WS1/WS2/WS3), `storage_account_name`, `storage_account_access_key`, `version = "~4"` | `workflow_id`, `identity_principal_id`, `default_hostname` | **CRITICAL:** Use provider v4.x; set `version = "~4"`; do NOT set `AzureWebJobsStorage` in app_settings (auto-configured); configure App Insights via `app_settings`; use System Assigned MI |
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

## Logic Apps Standard - Critical Implementation Details

**Provider Version Requirement:**
```hcl
# terraform.tf or versions.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"  # REQUIRED for Logic Apps Standard
    }
  }
}
```

**Resource Configuration:**
```hcl
resource "azurerm_logic_app_standard" "this" {
  name                       = var.logic_app_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = azurerm_service_plan.this.id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  version                    = "~4"  # Runtime version
  https_only                 = false

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"               = "node"
    "WEBSITE_NODE_DEFAULT_VERSION"           = "~18"
    # Monitoring (App Insights)
    "APPINSIGHTS_INSTRUMENTATIONKEY"         = var.app_insights_instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"  = var.app_insights_connection_string
    # Service Bus (for managed identity authentication)
    "SERVICEBUS_NAMESPACE_FQDN"              = var.servicebus_namespace_fqdn
    # DO NOT SET AzureWebJobsStorage - automatically configured via storage_account_name/access_key
  }

  identity {
    type = "SystemAssigned"  # Required for RBAC-based access to Service Bus, Storage, etc.
  }

  tags = var.tags
}
```

**Key Configuration Rules:**
1. **Never set `AzureWebJobsStorage` in `app_settings`** — automatically configured when `storage_account_name` and `storage_account_access_key` are provided
2. **Always use `version = "~4"`** — specifies Logic Apps runtime version
3. **Enable System Assigned Managed Identity** — required for RBAC-based access to Service Bus, Storage, Key Vault
4. **App Insights integration** — use both `APPINSIGHTS_INSTRUMENTATIONKEY` and `APPLICATIONINSIGHTS_CONNECTION_STRING` for full monitoring
5. **Service Bus FQDN** — use `SERVICEBUS_NAMESPACE_FQDN` for managed identity authentication (not connection strings)

**Common Mistakes to Avoid:**
- ❌ Setting `AzureWebJobsStorage` manually → causes deployment conflicts
- ❌ Using provider v3.x → missing Logic Apps Standard features and monitoring integration
- ❌ Hardcoding connection strings → use managed identities with RBAC instead
- ❌ Missing App Insights configuration → no monitoring/telemetry
- ❌ Not configuring diagnostic settings → logs not sent to Log Analytics

**RBAC Assignments Required:**
```hcl
# Service Bus access
resource "azurerm_role_assignment" "logicapp_servicebus_sender" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = module.logicapp.identity_principal_id
}

resource "azurerm_role_assignment" "logicapp_servicebus_receiver" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = module.logicapp.identity_principal_id
}

# Storage access (for platform storage, not Logic App storage)
resource "azurerm_role_assignment" "logicapp_storage_blob_contributor" {
  scope                = module.storage_platform.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.logicapp.identity_principal_id
}
```

**Diagnostic Settings:**
```hcl
resource "azurerm_monitor_diagnostic_setting" "logicapp" {
  name                       = "diag-${var.logic_app_name}"
  target_resource_id         = azurerm_logic_app_standard.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "WorkflowRuntime"
  }

  metric {
    category = "AllMetrics"
  }
}
```

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
- [ ] **Backend configuration** — `env/<env>/backend.tfvars` committed to repo (no secrets)
- [ ] **Environment variables** — `env/<env>/<env>.tfvars` committed to repo (no secrets)
- [ ] **Example tfvars** — `env/<env>/<env>.tfvars.example` for local development reference
- [ ] **APIM backend/tfvars** — `apim/backend.tfvars` and `apim/<env>.tfvars` if APIM module exists
- [ ] **Runbook** — `env/<env>/RUNBOOK.md` with TF commands, secret retrieval, RBAC, rollback steps
- [ ] **Documentation** — Module READMEs with purpose, inputs, outputs, dependencies, examples
- [ ] **Cross-service wiring** — All dependencies documented (e.g., Function App → Storage)
- [ ] **RBAC assignments** — All MI role assignments in Terraform (not manual)
- [ ] **Changelog** — `CHANGELOG.md` entry with services added, changes, PR reference
- [ ] **.gitignore** — Configured to ignore state files but NOT backend.tfvars or <env>.tfvars

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
