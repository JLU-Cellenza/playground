# Backend configuration for APIM Terraform state
# Separate from main platform state to allow independent deployments

resource_group_name  = "rg-terraform-state"
storage_account_name = "stterraformstate001"
container_name       = "tfstate"
key                  = "mvp-ipaas-dev-apim.tfstate"
