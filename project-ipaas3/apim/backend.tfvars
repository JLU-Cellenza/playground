# Backend configuration for APIM Terraform state
# Separate from main platform state to allow independent deployments

resource_group_name  = "rg-common-iac-01"
storage_account_name = "stocommoniac01"
container_name       = "terraform"
key                  = "project-ipaas3-dev-apim.tfstate"

# Notes:
# - Same backend storage as main platform
# - Different state file key to isolate APIM state
# - Deploy main platform FIRST before deploying APIM
