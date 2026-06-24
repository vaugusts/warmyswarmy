variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_suffix" {
  type = string
}

variable "admin_login" {
  type    = string
  default = "sqladmin"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "sku_name" {
  type    = string
  default = "GP_Gen5_2"
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

resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql${replace(var.resource_suffix, "-", "")}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.admin_login
  administrator_login_password = var.admin_password
  minimum_tls_version          = "1.2"
  tags                         = var.common_tags
}

resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "database" {
  name           = "db${replace(var.resource_suffix, "-", "")}"
  server_id      = azurerm_mssql_server.sql_server.id
  sku_name       = var.sku_name
  zone_redundant = false
  tags           = var.common_tags

  short_term_retention_policy {
    retention_days = 7
  }

  long_term_retention_policy {
    weekly_retention  = "P4W"
    monthly_retention = "P12M"
    yearly_retention  = "P5Y"
    week_of_year      = 1
  }
}

resource "azurerm_mssql_server_security_alert_policy" "threat_detection" {
  resource_group_name        = var.resource_group_name
  server_name                = azurerm_mssql_server.sql_server.name
  state                      = "Enabled"
  retention_days             = 30
  email_notification_enabled = true
}

resource "azurerm_monitor_diagnostic_setting" "sql_diagnostics" {
  count              = var.enable_diagnostics ? 1 : 0
  name               = "diag-${azurerm_mssql_database.database.name}"
  target_resource_id = azurerm_mssql_database.database.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLInsights"
  }

  enabled_log {
    category = "AutomaticTuning"
  }

  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }

  enabled_log {
    category = "Errors"
  }

  metric {
    category = "Basic"
    enabled  = true
  }
}

output "sql_server_id" {
  value = azurerm_mssql_server.sql_server.id
}

output "sql_server_name" {
  value = azurerm_mssql_server.sql_server.name
}

output "database_id" {
  value = azurerm_mssql_database.database.id
}

output "database_name" {
  value = azurerm_mssql_database.database.name
}

output "server_fqdn" {
  value = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}
