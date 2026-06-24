# Production environment variables
# High availability SKUs for production grade

environment                    = "prod"
project_name                   = "myapp"
location                       = "eastus"
aks_vm_sku                     = "Standard_D4s_v3"
aks_node_count                 = 3
sql_admin_login                = "sqladmin"
sql_admin_password             = "CHANGE-ME-PROD-PASSWORD-STRONG-123!"
key_vault_admin_object_id      = "00000000-0000-0000-0000-000000000000"
enable_diagnostics             = true
log_retention_days             = 90

common_tags = {
  Environment = "prod"
  Project     = "myapp"
  ManagedBy   = "Terraform"
  CostCenter  = "production"
  Criticality = "high"
}
