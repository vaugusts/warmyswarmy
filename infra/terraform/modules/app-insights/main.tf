variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_suffix" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

resource "azurerm_application_insights" "appi" {
  name                = "appi-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = var.log_analytics_workspace_id
  tags                = var.common_tags
}

resource "azurerm_monitor_metric_alert" "failure_rate_alert" {
  name                = "alert-${azurerm_application_insights.appi.name}-high-failure-rate"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_application_insights.appi.id]
  description         = "Alert when request failure rate exceeds 5%"
  severity            = 2
  enabled             = true

  criteria {
    metric_name      = "server/exceptionsPerSecond"
    metric_namespace = "microsoft.insights/components"
    operator         = "GreaterThan"
    threshold        = 0.05
    aggregation      = "Average"
  }

  frequency   = "PT5M"
  window_size = "PT15M"
}

output "app_insights_id" {
  value = azurerm_application_insights.appi.id
}

output "instrumentation_key" {
  value     = azurerm_application_insights.appi.instrumentation_key
  sensitive = true
}

output "app_id" {
  value = azurerm_application_insights.appi.app_id
}
