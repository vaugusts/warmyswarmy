variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_suffix" {
  type = string
}

variable "admin_object_id" {
  type      = string
  sensitive = true
}

variable "enable_purge_protection" {
  type    = bool
  default = false
}

variable "enable_diagnostics" {
  type    = bool
  default = true
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                            = "kv${replace(var.resource_suffix, "-", "")}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true
  soft_delete_retention_days      = 90
  purge_protection_enabled        = var.enable_purge_protection
  tags                            = var.common_tags
}

resource "azurerm_role_assignment" "kv_admin" {
  scope              = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id       = var.admin_object_id
}

resource "azurerm_monitor_diagnostic_setting" "kv_diagnostics" {
  count              = var.enable_diagnostics ? 1 : 0
  name               = "diag-${azurerm_key_vault.kv.name}"
  target_resource_id = azurerm_key_vault.kv.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  value        = "PLACEHOLDER-CHANGE-IN-DEPLOYMENT"
  key_vault_id = azurerm_key_vault.kv.id

  tags = merge(var.common_tags, {
    rotation_enabled = "true"
  })
}

resource "azurerm_key_vault_secret" "db_connection_string" {
  name         = "db-connection-string"
  value        = "PLACEHOLDER-CHANGE-IN-DEPLOYMENT"
  key_vault_id = azurerm_key_vault.kv.id
  tags         = var.common_tags
}

output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}
