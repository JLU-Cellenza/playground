resource_group_name  = "rg-common-iac-01"
storage_account_name = "stocommoniac398"
container_name       = "terraform"
key                  = "mvp-ipaas-dev.tfstate"

# Notes:
# - Replace <SUBSCRIPTION> and <UNIQUE_SUFFIX> with your values.
# - Create the resource group, storage account and container before running terraform init.
# - Example creation (Azure CLI):
#   az group create -n rg-terraform-state-<SUBSCRIPTION> -l francecentral
#   az storage account create -n stterraformstate<UNIQUE_SUFFIX> -g rg-terraform-state-<SUBSCRIPTION> -l francecentral --sku Standard_LRS
#   az storage container create -n tfstate --account-name stterraformstate<UNIQUE_SUFFIX>
