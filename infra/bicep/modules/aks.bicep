// Azure Kubernetes Service (AKS) Module
// Provisions production-grade AKS cluster with system-managed identity,
// network integration, monitoring, and RBAC; supports multiple node pools

param location string
param resourceSuffix string
param tags object
param vnetId string
param aksSubnetId string
param vmSku string
param nodeCount int
param enableDiagnostics bool
param logAnalyticsWorkspaceId string
param acrId string
param keyVaultId string

var aksClusterName = 'aks-${resourceSuffix}'
var systemNodePoolName = 'system'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-10-01' = {
  name: aksClusterName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: aksClusterName
    kubernetesVersion: '1.27.9'
    enableRBAC: true
    enablePodSecurityPolicy: false
    networkProfile: {
      networkPlugin: 'azure'
      serviceCidr: '10.100.0.0/16'
      dnsServiceIP: '10.100.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
      outboundType: 'loadBalancer'
      loadBalancerSku: 'standard'
      networkPolicy: 'azure'
    }
    agentPoolProfiles: [
      {
        name: systemNodePoolName
        count: nodeCount
        vmSize: vmSku
        osType: 'Linux'
        mode: 'System'
        vnetSubnetID: aksSubnetId
        maxPods: 110
        enableAutoScaling: true
        minCount: nodeCount
        maxCount: nodeCount * 2
        type: 'VirtualMachineScaleSets'
        enableNodePublicIP: false
        tags: tags
      }
    ]
    apiServerAccessProfile: {
      enablePrivateCluster: false
      authorizedIPRanges: []
    }
    addonProfiles: {
      httpApplicationRouting: {
        enabled: false
      }
      monitoring: {
        enabled: enableDiagnostics
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
          useAAD: true
        }
      }
      omsAgent: {
        enabled: enableDiagnostics
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
    }
    securityProfile: {
      defender: {
        logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceId
        securityMonitoring: {
          enabled: enableDiagnostics
        }
      }
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
  }
}

// Grant AKS managed identity access to ACR
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, aksCluster.id, 'AcrPull')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: aksCluster.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Grant AKS managed identity access to Key Vault
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultId, aksCluster.id, 'KeyVaultSecretsUser')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86d0e6e')
    principalId: aksCluster.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Diagnostic settings for AKS
resource aksDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  name: 'diag-${aksClusterName}'
  scope: aksCluster
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'cluster-autoscaler'
        enabled: true
      }
      {
        category: 'kube-controller-manager'
        enabled: true
      }
      {
        category: 'kube-audit'
        enabled: true
      }
      {
        category: 'kube-scheduler'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output aksClusterId string = aksCluster.id
output aksClusterName string = aksCluster.name
output aksClusterFqdn string = aksCluster.properties.fqdn
output kubeConfig string = aksCluster.listClusterAdminCredential().kubeconfigs[0].value
