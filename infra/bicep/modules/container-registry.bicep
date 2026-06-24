// Azure Container Registry Module
// Private container image registry with security, compliance, and monitoring

param location string
param resourceSuffix string
param tags object
param skuName string
param adminUserEnabled bool
param enableDiagnostics bool
param logAnalyticsWorkspaceId string

var acrName = 'acr${replace(resourceSuffix, '-', '')}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    policies: {
      quarantinePolicy: {
        status: 'enabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 30
        status: 'enabled'
      }
    }
    encryption: {
      status: 'enabled'
      keyVaultProperties: null
    }
    dataEndpointEnabled: false
    networkRuleSet: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
    }
    anonymousPullEnabled: false
    zoneRedundancy: skuName == 'Premium' ? 'Enabled' : 'Disabled'
  }
}

// Webhook for image push notifications (optional)
resource acrWebhook 'Microsoft.ContainerRegistry/registries/webhooks@2023-07-01' = {
  name: 'webhook-onpush'
  parent: acr
  location: location
  properties: {
    actions: ['push', 'delete']
    scope: '*'
    status: 'enabled'
    serviceUri: 'https://PLACEHOLDER-webhook-endpoint.azurewebsites.net/webhook'
    customHeaders: {}
  }
}

// Diagnostic settings
resource acrDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  name: 'diag-${acrName}'
  scope: acr
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
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

// REVIEWER NOTE: Configure additional security policies
// TODO: Enable content trust and image scanning as needed

output acrId string = acr.id
output acrName string = acr.name
output loginServer string = acr.properties.loginServer
output adminUsername string = acr.listCredentials().username
