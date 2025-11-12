# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure for Simple iPaaS platform
- Service Bus module with inbound queue
- Logic App Standard module with App Service Plan
- Key Vault module with RBAC-based access control
- Storage Account module with configurable containers
- Development environment overlay (env/dev)
- RBAC role assignments for Logic App Managed Identity
- Automated secret storage in Key Vault (Service Bus and Storage connection strings)
- Comprehensive RUNBOOK for deployment
- Example configuration files (dev.tfvars.example, backend.tfvars.example)
- .gitignore for Terraform-specific files

### Security
- All sensitive outputs marked as `sensitive = true`
- Managed Identity enabled for Logic App
- RBAC roles assigned for Key Vault and Service Bus access
- HTTPS-only enforced on Logic App
- TLS 1.2 minimum on Storage Account
- Soft delete enabled on Key Vault

## [1.0.0] - 2025-11-12

### Initial Release
- Simple iPaaS platform with 4 core components
- Production-ready Terraform modules
- Development environment configuration
- Complete documentation and deployment guide
