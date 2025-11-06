# Deployment Checklist

Use this checklist to ensure a successful deployment of the Azure iPaaS platform.

## Pre-Deployment

### Azure Subscription & Access
- [ ] Azure subscription ID confirmed
- [ ] Account has Owner or Contributor + User Access Administrator role
- [ ] Verified no naming conflicts in target region
- [ ] Checked Azure quotas (especially APIM, Service Bus)
- [ ] Verified subscription is active and not expired

### Tools & Prerequisites
- [ ] Terraform >= 1.5.0 installed (`terraform version`)
- [ ] Azure CLI installed (`az --version`)
- [ ] PowerShell 5.1+ installed (`$PSVersionTable`)
- [ ] Git installed (for version control)
- [ ] Text editor (VS Code, Notepad++, etc.)

### Configuration Files
- [ ] Copied `dev.tfvars.example` to `dev.tfvars`
- [ ] Updated `apim_publisher_email` with valid email
- [ ] Updated `resource_group_name` if needed
- [ ] Verified `location` is correct (francecentral)
- [ ] Set `ARM_SUBSCRIPTION_ID` environment variable

### Pre-Flight Checks
- [ ] Logged into Azure CLI (`az login`)
- [ ] Confirmed correct subscription (`az account show`)
- [ ] Resource group created or exists
- [ ] No conflicting resource names in region
- [ ] Reviewed cost estimate (~€250-280/month for dev)

## Deployment

### Terraform Initialization
- [ ] Changed to `env/dev` directory
- [ ] Ran `terraform init` successfully
- [ ] Verified providers downloaded to `.terraform/`
- [ ] Ran `terraform validate` with no errors
- [ ] Ran `terraform fmt -recursive` to format code

### Plan Review
- [ ] Ran `terraform plan -var-file=dev.tfvars -out=plan.tfplan`
- [ ] Reviewed plan shows ~35 resources to create
- [ ] Verified resource names follow naming convention
- [ ] Confirmed SKUs are correct (Developer, Standard, Consumption)
- [ ] No unexpected resources will be created/destroyed
- [ ] Saved plan output for review

### Apply Deployment
- [ ] Ran `terraform apply plan.tfplan`
- [ ] Monitoring deployment progress
- [ ] APIM deployment started (will take 30-45 minutes)
- [ ] Other resources deployed successfully
- [ ] No errors in Terraform output
- [ ] Applied completed successfully

## Post-Deployment Validation

### Resource Verification
- [ ] All resources visible in Azure Portal
- [ ] Resource group contains ~35 resources
- [ ] Tags applied correctly to all resources
- [ ] Resources in correct region (francecentral)
- [ ] Managed Identities created for all compute services

### Service-Specific Checks

#### Log Analytics & Monitoring
- [ ] Log Analytics workspace created
- [ ] Application Insights linked to Log Analytics
- [ ] Diagnostic settings enabled on all services
- [ ] Test query runs in Log Analytics

#### Storage Accounts
- [ ] 4 storage accounts created
- [ ] Platform storage has 3 containers (configurations, templates, schemas)
- [ ] All storage accounts use TLS 1.2
- [ ] Public access disabled for nested items

#### Service Bus
- [ ] Namespace created successfully
- [ ] "inbound" queue exists
- [ ] Queue settings correct (lock 5 min, TTL 14 days)
- [ ] Dead letter enabled
- [ ] Diagnostic logs flowing to Log Analytics

#### Function App
- [ ] Function App created
- [ ] Consumption plan (Y1) configured
- [ ] System-assigned managed identity enabled
- [ ] App Insights connection string configured
- [ ] Service Bus connection configured (managed identity)
- [ ] HTTP GET to function URL returns 200 or 401 (expected)

#### Logic Apps (x2)
- [ ] Both Logic Apps created
- [ ] Both have WS1 service plans
- [ ] Both have system-assigned managed identities
- [ ] Both connected to App Insights
- [ ] Both have Service Bus connection configured
- [ ] Workflow runtime v4 enabled

#### API Management
- [ ] APIM created successfully (30-45 min)
- [ ] Gateway URL accessible
- [ ] Developer portal URL accessible
- [ ] System-assigned managed identity enabled
- [ ] Diagnostic logs flowing to Log Analytics

### RBAC Verification
- [ ] Function App has Service Bus Data Sender role
- [ ] Function App has Service Bus Data Receiver role
- [ ] Function App has Storage Blob Data Contributor role (platform storage)
- [ ] Logic App 01 has Service Bus Data Sender role
- [ ] Logic App 01 has Service Bus Data Receiver role
- [ ] Logic App 01 has Storage Blob Data Contributor role
- [ ] Logic App 02 has Service Bus Data Sender role
- [ ] Logic App 02 has Service Bus Data Receiver role
- [ ] Logic App 02 has Storage Blob Data Contributor role

### Connectivity Tests
- [ ] Function App responds to HTTP request
- [ ] Logic App 01 portal accessible
- [ ] Logic App 02 portal accessible
- [ ] APIM gateway responds (status page)
- [ ] Service Bus queue can be queried
- [ ] Storage containers accessible
- [ ] Log Analytics queries return data

### Terraform State
- [ ] `terraform.tfstate` file exists locally (or in backend)
- [ ] State file contains all deployed resources
- [ ] Run `terraform plan` again shows no changes (idempotency check)
- [ ] State file backed up (if using local state)

## Outputs Verification
- [ ] Ran `terraform output` successfully
- [ ] All output values populated correctly
- [ ] Sensitive outputs marked as sensitive
- [ ] Documented output values for team

## Documentation
- [ ] Deployment date recorded
- [ ] Resource URLs documented
- [ ] RBAC assignments documented
- [ ] Any issues/workarounds documented
- [ ] Updated CHANGELOG.md if needed

## Security Review
- [ ] All services use managed identities
- [ ] No hardcoded connection strings
- [ ] No secrets in .tfvars or code
- [ ] RBAC follows least privilege
- [ ] TLS 1.2+ enforced
- [ ] Public access noted (⚠️ demo only)

## Cost Monitoring
- [ ] Enabled Azure Cost Management
- [ ] Set up cost alerts (optional)
- [ ] Verified cost tags applied
- [ ] Estimated monthly cost reviewed (~€250-280)

## Handoff
- [ ] Deployment completed notification sent
- [ ] Access credentials shared (if needed)
- [ ] Documentation links shared
- [ ] Support contacts provided
- [ ] Next steps communicated

## Production Readiness (If Applicable)
- [ ] Private endpoints configured
- [ ] Public access disabled
- [ ] Network security groups configured
- [ ] Key Vault integrated for secrets
- [ ] Multi-region deployment (if required)
- [ ] Backup and DR strategy documented
- [ ] Monitoring alerts configured
- [ ] CI/CD pipeline set up
- [ ] Load testing completed
- [ ] Security audit passed

## Rollback Plan
- [ ] Terraform state backup exists
- [ ] Rollback procedure documented
- [ ] Emergency contacts identified
- [ ] Tested rollback in lower environment

---

## Sign-Off

**Deployed By**: _______________________  
**Date**: _______________________  
**Environment**: [ ] Dev [ ] Prd  
**Deployment Status**: [ ] Success [ ] Failed [ ] Partial  
**Issues Encountered**: _______________________

**Approved By**: _______________________  
**Date**: _______________________  

---

## Notes

Use this space to document any deployment-specific notes, workarounds, or decisions:

_________________________________________________________________

_________________________________________________________________

_________________________________________________________________

_________________________________________________________________

---

**Checklist Version**: 1.0.0  
**Last Updated**: 2025-11-06
