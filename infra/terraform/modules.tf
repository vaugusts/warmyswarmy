# Module calls for all infrastructure components

module "resource_group" {
  source = "./modules/resource-group"

  environment    = var.environment
  project_name   = var.project_name
  location       = var.location
  common_tags    = local.tags
}

module "log_analytics" {
  source = "./modules/log-analytics"

  resource_group_name    = module.resource_group.name
  location               = var.location
  resource_suffix        = local.resource_suffix
  log_retention_days     = var.log_retention_days
  common_tags            = local.tags
}

module "app_insights" {
  source = "./modules/app-insights"

  resource_group_name           = module.resource_group.name
  location                      = var.location
  resource_suffix               = local.resource_suffix
  log_analytics_workspace_id    = module.log_analytics.workspace_id
  common_tags                   = local.tags
}

module "vnet" {
  source = "./modules/vnet"

  resource_group_name = module.resource_group.name
  location            = var.location
  resource_suffix     = local.resource_suffix
  environment         = var.environment
  common_tags         = local.tags
}

module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name         = module.resource_group.name
  location                    = var.location
  resource_suffix             = local.resource_suffix
  admin_object_id             = var.key_vault_admin_object_id
  enable_purge_protection     = var.environment == "prod"
  enable_diagnostics          = var.enable_diagnostics
  log_analytics_workspace_id  = module.log_analytics.workspace_id
  common_tags                 = local.tags

  depends_on = [module.log_analytics]
}

module "storage" {
  source = "./modules/storage"

  resource_group_name         = module.resource_group.name
  location                    = var.location
  resource_suffix             = local.resource_suffix
  sku_name                    = var.environment == "prod" ? "Standard_GRS" : "Standard_LRS"
  enable_diagnostics          = var.enable_diagnostics
  log_analytics_workspace_id  = module.log_analytics.workspace_id
  common_tags                 = local.tags

  depends_on = [module.log_analytics]
}

module "acr" {
  source = "./modules/container-registry"

  resource_group_name         = module.resource_group.name
  location                    = var.location
  resource_suffix             = local.resource_suffix
  sku_name                    = var.environment == "prod" ? "Premium" : "Standard"
  admin_user_enabled          = false
  enable_diagnostics          = var.enable_diagnostics
  log_analytics_workspace_id  = module.log_analytics.workspace_id
  common_tags                 = local.tags

  depends_on = [module.log_analytics]
}

module "sql_database" {
  source = "./modules/sql-database"

  resource_group_name         = module.resource_group.name
  location                    = var.location
  resource_suffix             = local.resource_suffix
  admin_login                 = var.sql_admin_login
  admin_password              = var.sql_admin_password
  sku_name                    = var.environment == "prod" ? "GP_Gen5_4" : "GP_Gen5_2"
  enable_diagnostics          = var.enable_diagnostics
  log_analytics_workspace_id  = module.log_analytics.workspace_id
  common_tags                 = local.tags

  depends_on = [module.log_analytics]
}

module "aks" {
  source = "./modules/aks"

  resource_group_name         = module.resource_group.name
  location                    = var.location
  resource_suffix             = local.resource_suffix
  vnet_id                     = module.vnet.vnet_id
  aks_subnet_id               = module.vnet.aks_subnet_id
  vm_sku                      = var.aks_vm_sku
  node_count                  = var.aks_node_count
  enable_diagnostics          = var.enable_diagnostics
  log_analytics_workspace_id  = module.log_analytics.workspace_id
  acr_id                      = module.acr.acr_id
  key_vault_id                = module.keyvault.key_vault_id
  common_tags                 = local.tags

  depends_on = [module.vnet, module.log_analytics, module.acr, module.keyvault]
}
