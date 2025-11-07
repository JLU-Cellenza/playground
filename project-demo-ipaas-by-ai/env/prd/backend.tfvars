resource_group_name  = "rg-terraform-state-<SUBSCRIPTION>"
storage_account_name = "stterraformstate<UNIQUE_SUFFIX>"
container_name       = "tfstate"
key                  = "mvp-ipaas-prd.tfstate"

# Notes:
# - Replace <SUBSCRIPTION> and <UNIQUE_SUFFIX> with your values. For production, use a unique, compliant storage account name.
# - Enable secure defaults in production: private endpoints, secure transfer required, and appropriate RBAC.
# - Example creation (Azure CLI):
#   az group create -n rg-terraform-state-<SUBSCRIPTION> -l francecentral
#   az storage account create -n stterraformstate<UNIQUE_SUFFIX> -g rg-terraform-state-<SUBSCRIPTION> -l francecentral --sku Standard_LRS
#   az storage container create -n tfstate --account-name stterraformstate<UNIQUE_SUFFIX>
