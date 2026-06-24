# Development environment variables
# Lower resource SKUs for cost optimization

environment                    = "dev"
project_name                   = "myapp"
location                       = "eastus"
aks_vm_sku                     = "Standard_D2s_v3"
aks_node_count                 = 1
sql_admin_login                = "sqladmin"
sql_admin_password             = "CHANGE-ME-DEV-PASSWORD-123!"
key_vault_admin_object_id      = "00000000-0000-0000-0000-000000000000"
enable_diagnostics             = true
log_retention_days             = 30

common_tags = {
  Environment = "dev"
  Project     = "myapp"
  ManagedBy   = "Terraform"
  CostCenter  = "engineering"
}
