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
  default = "Standard_LRS"
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

resource "azurerm_storage_account" "sa" {
  name                     = "st${replace(var.resource_suffix, "-", "")}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = split("_", var.sku_name)[1]
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  https_traffic_only_enabled = true
  min_tls_version          = "TLS1_2"
  shared_access_key_enabled = true
  tags                     = var.common_tags
}

resource "azurerm_storage_blob_container" "containers" {
  for_each              = toset(["app-data", "logs", "backups"])
  name                  = each.value
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.sa.id

  rule {
    name    = "archive-old-logs"
    enabled = true
    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["logs/"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_greater_than    = 30
        tier_to_archive_after_days_greater_than = 90
        delete_after_days_greater_than          = 365
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage_diagnostics" {
  count              = var.enable_diagnostics ? 1 : 0
  name               = "diag-${azurerm_storage_account.sa.name}"
  target_resource_id = "${azurerm_storage_account.sa.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}

output "storage_account_id" {
  value = azurerm_storage_account.sa.id
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.sa.primary_blob_endpoint
}
