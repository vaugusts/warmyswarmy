variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_suffix" {
  type = string
}

variable "log_retention_days" {
  type = number
}

variable "common_tags" {
  type = map(string)
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.common_tags

  identity {
    type = "SystemAssigned"
  }
}

output "workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}

output "workspace_name" {
  value = azurerm_log_analytics_workspace.law.name
}

output "customer_id" {
  value = azurerm_log_analytics_workspace.law.workspace_id
}
