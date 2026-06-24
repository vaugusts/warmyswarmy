variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_suffix" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "Standard"
}

variable "admin_user_enabled" {
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

resource "azurerm_container_registry" "acr" {
  name                = "acr${replace(var.resource_suffix, "-", "")}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku_name
  admin_enabled       = var.admin_user_enabled
  tags                = var.common_tags
}

resource "azurerm_monitor_diagnostic_setting" "acr_diagnostics" {
  count              = var.enable_diagnostics ? 1 : 0
  name               = "diag-${azurerm_container_registry.acr.name}"
  target_resource_id = azurerm_container_registry.acr.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

output "acr_id" {
  value = azurerm_container_registry.acr.id
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "admin_username" {
  value     = azurerm_container_registry.acr.admin_username
  sensitive = true
}
