terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    virtual_machine {
      graceful_shutdown = true
    }
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 10
    error_message = "Project name must be 1-10 characters."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "aks_vm_sku" {
  description = "VM SKU for AKS node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "aks_node_count" {
  description = "Number of AKS nodes"
  type        = number
  validation {
    condition     = var.aks_node_count >= 1 && var.aks_node_count <= 100
    error_message = "AKS node count must be between 1 and 100."
  }
  default = 1
}

variable "sql_admin_login" {
  description = "SQL Server admin username"
  type        = string
  sensitive   = true
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "SQL Server admin password - CHANGE IN PRODUCTION"
  type        = string
  sensitive   = true
  default     = "PLACEHOLDER-CHANGE-ME"
}

variable "key_vault_admin_object_id" {
  description = "Azure AD object ID for Key Vault admin"
  type        = string
  sensitive   = true
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "enable_diagnostics" {
  description = "Enable diagnostic logging to Log Analytics"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "MyApp"
  }
}

locals {
  resource_suffix = "${var.project_name}-${var.environment}"
  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      DeployedAt  = timestamp()
    }
  )
}

# Module outputs available in root module
output "vnet_id" {
  value = module.vnet.vnet_id
}

output "aks_cluster_id" {
  value = module.aks.cluster_id
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "key_vault_uri" {
  value = module.keyvault.vault_uri
}

output "storage_account_id" {
  value = module.storage.storage_account_id
}

output "log_analytics_workspace_id" {
  value = module.log_analytics.workspace_id
}

output "app_insights_instrumentation_key" {
  value     = module.app_insights.instrumentation_key
  sensitive = true
}

output "sql_database_name" {
  value = module.sql_database.database_name
}
