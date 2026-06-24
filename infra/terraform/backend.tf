# Backend configuration for remote state
# Configure storage account and container before deployment
# Run: terraform init -backend-config="key=terraform.tfstate" -backend-config="..."

terraform {
  backend "azurerm" {
    # PLACEHOLDER: Replace with your storage account details
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
  }
}
