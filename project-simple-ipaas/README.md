# Simple iPaaS Platform

[![Terraform CI](https://github.com/JLU-Cellenza/playground/actions/workflows/terraform-ci.yaml/badge.svg)](https://github.com/JLU-Cellenza/playground/actions/workflows/terraform-ci.yaml)
[![Deploy](https://github.com/JLU-Cellenza/playground/actions/workflows/deploy.yaml/badge.svg)](https://github.com/JLU-Cellenza/playground/actions/workflows/deploy.yaml)

## Overview

This project provisions a simple Integration Platform as a Service (iPaaS) on Azure with core messaging and workflow capabilities.

## Architecture

The platform consists of:
- **Service Bus**: Central message broker with inbound queue for async messaging
- **Logic App Standard**: Workflow orchestration engine
- **Key Vault**: Secure secrets and configuration management
- **Storage Account**: Platform configuration and Logic App storage backend

## Project Structure

```
project-simple-ipaas/
├── modules/
│   ├── servicebus/       # Service Bus namespace and queue
│   ├── logicapp/         # Logic App Standard with App Service Plan
│   ├── keyvault/         # Key Vault with RBAC
│   └── storage/          # Storage Account
├── env/
│   └── dev/              # Development environment overlay
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── locals.tf
│       ├── backend.tfvars
│       ├── dev.tfvars.example
│       └── RUNBOOK.md
└── README.md
```

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Terraform >= 1.5.0
- Azure subscription with sufficient permissions
- Resource group created (or use Terraform to create one)

## Quick Start

### Manual Deployment

See [env/dev/RUNBOOK.md](env/dev/RUNBOOK.md) for detailed deployment instructions.

### GitHub Actions CI/CD

This project includes automated deployment workflows:

- **CI Validation**: Automatic Terraform validation and planning on pull requests
- **Deployment**: Automatic deployment to dev/prd on push to main or manual trigger
- **Destruction**: Manual infrastructure teardown with approval gates

**Setup Instructions:** See [DEPLOYMENT-SETUP.md](DEPLOYMENT-SETUP.md) for complete GitHub Actions configuration guide.

**Quick Deployment via GitHub Actions:**
1. Configure GitHub Secrets (see DEPLOYMENT-SETUP.md)
2. Push to repository
3. Go to Actions → Deploy Infrastructure → Run workflow

## Security

- All secrets stored in Key Vault
- Managed Identities used for service-to-service authentication
- Storage account keys stored in Key Vault
- Service Bus connection strings stored in Key Vault

## Naming Convention

Resources follow the pattern: `<svc>-<env>-<org>-<project>-<purpose>-<instance>`

Example: `svb-dev-org-simpleipaas-inbound-01`
