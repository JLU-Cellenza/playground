# Azure iPaaS Platform - MVP Demo

## Overview

This Terraform configuration deploys a complete Azure Integration Platform as a Service (iPaaS) solution for the Cellenza MVP demo.

### Architecture Components

- **2x Logic App Standard** - Workflow orchestration
- **1x Service Bus Namespace** - Central message box with "inbound" queue
- **1x API Management (Developer)** - API gateway
- **1x Function App (Consumption)** - Custom connectors and helpers
- **1x Storage Account** - Platform configuration storage
- **1x Log Analytics Workspace** - Centralized logging
- **1x Application Insights** - Application monitoring

All services are configured with public access for demo purposes and connected to centralized logging.

## Prerequisites

- Azure CLI installed and authenticated
- Terraform >= 1.5.0
- Azure subscription with appropriate permissions

## Quick Start

### 1. Set Azure Subscription

```powershell
# Set your Azure subscription ID as an environment variable
$env:ARM_SUBSCRIPTION_ID = "YOUR-SUBSCRIPTION-ID"
```

### 2. Initialize Terraform

```powershell
cd env/dev
terraform init
```

### 3. Create tfvars file

```powershell
# Copy the example and fill in your values
cp dev.tfvars.example dev.tfvars
# Edit dev.tfvars with your subscription details
```

### 4. Plan and Apply

```powershell
terraform plan -var-file=dev.tfvars -out=plan.tfplan
terraform apply plan.tfplan
```

## Project Structure

```
project-demo-ipaas-by-ai/
 modules/              # Reusable Terraform modules
    apim/            # API Management
    app_insights/    # Application Insights
    function_app/    # Azure Functions
    log_analytics/   # Log Analytics Workspace
    logicapp/        # Logic Apps Standard
    servicebus/      # Service Bus
    storage/         # Storage Account
 env/                 # Environment-specific configurations
    dev/            # Development environment
    prd/            # Production environment
 README.md           # This file
```

## Naming Convention

Resources follow the pattern: `<svc>-<env>-<org>-<project>-<purpose>-<instance>`

Example: `loa-dev-cellenza-mvpipaas-workflow-01`

## Security Notes

- All services use Managed Identities for authentication
- Secrets are stored in Azure Key Vault (not included in demo)
- Public access is enabled for demo purposes only
- For production, implement network isolation with Private Endpoints

## Deployment Workflow

See `env/dev/RUNBOOK.md` for detailed deployment instructions.

## Tags

All resources are tagged with:
- `project`: mvp-ipaas
- `environment`: dev/prd
- `owner`: cellenza
- `cost_center`: demo
- `created_by`: terraform

## Support

For issues or questions, contact the Cellenza integration team.
