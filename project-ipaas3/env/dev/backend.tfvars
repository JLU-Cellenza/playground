# Backend configuration for main platform Terraform state
resource_group_name  = "rg-common-iac-01"
storage_account_name = "stocommoniac01"
container_name       = "terraform"
key                  = "project-ipaas3-dev.tfstate"

# Notes:
# - Shared backend storage with other projects
# - APIM uses separate state file: project-ipaas3-dev-apim.tfstate
# - Ensure backend storage account exists before running terraform init
