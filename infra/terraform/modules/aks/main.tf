variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_suffix" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "aks_subnet_id" {
  type = string
}

variable "vm_sku" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "enable_diagnostics" {
  type    = bool
  default = true
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "acr_id" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.resource_suffix}"
  kubernetes_version  = "1.27.9"

  default_node_pool {
    name            = "system"
    vm_size         = var.vm_sku
    node_count      = var.node_count
    vnet_subnet_id  = var.aks_subnet_id
    max_pods        = 110
    enable_auto_scaling = true
    min_count       = var.node_count
    max_count       = var.node_count * 2
    tags            = var.common_tags
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    service_cidr        = "10.100.0.0/16"
    dns_service_ip      = "10.100.0.10"
    docker_bridge_cidr  = "172.17.0.1/16"
    outbound_type       = "loadBalancer"
    load_balancer_sku   = "standard"
    network_policy      = "azure"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  azure_policy_enabled = true
  role_based_access_control_enabled = true
  tags = var.common_tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope              = var.acr_id
  role_definition_name = "AcrPull"
  principal_id       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "aks_keyvault" {
  scope              = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

resource "azurerm_monitor_diagnostic_setting" "aks_diagnostics" {
  count              = var.enable_diagnostics ? 1 : 0
  name               = "diag-${azurerm_kubernetes_cluster.aks.name}"
  target_resource_id = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "cluster-autoscaler"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

output "cluster_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "cluster_fqdn" {
  value = azurerm_kubernetes_cluster.aks.fqdn
}

output "kube_admin_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_admin_config[0].raw_config
  sensitive = true
}
