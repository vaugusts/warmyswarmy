// Root Bicep template for Azure infrastructure deployment
// Orchestrates all modules for a complete application environment
// Supports dev/prod via parameter files; handles idempotency and tagging

metadata description = 'Production-ready Azure infrastructure root module'
metadata author = 'Platform Engineering'

@allowed(['dev', 'prod', 'staging'])
param environment string

@minLength(1)
@maxLength(23)
param projectName string

param location string = resourceGroup().location

@allowed(['Standard_D2s_v3', 'Standard_D4s_v3', 'Standard_E2s_v3'])
param vmSkuAKS string = 'Standard_D2s_v3'

@minValue(1)
@maxValue(100)
param aksNodeCount int = environment == 'prod' ? 3 : 1

param sqlAdminLogin string = 'sqladmin'
@secure()
param sqlAdminPassword string

@secure()
param keyVaultAdminObjectId string

param enableDiagnostics bool = true
param logRetentionDays int = environment == 'prod' ? 90 : 30

var resourceSuffix = '${projectName}-${environment}'
var commonTags = {
  environment: environment
  project: projectName
  managedBy: 'Bicep'
  deployedAt: utcNow('u')
}

// Virtual Network Module
module vnet 'modules/vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    location: location
    resourceSuffix: resourceSuffix
    tags: commonTags
    addressSpaces: [
      environment == 'prod' ? '10.0.0.0/16' : '10.1.0.0/16'
    ]
  }
}

// Log Analytics Workspace (shared observability)
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'loganalytics-deployment'
  params: {
    location: location
    resourceSuffix: resourceSuffix
    tags: commonTags
    retentionDays: logRetentionDays
  }
}

// Application Insights
module appInsights 'modules/app-insights.bicep' = {
  name: 'appinsights-deployment'
  params: {
    location: location
    resourceSuffix: resourceSuffix
    tags: commonTags
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// Container Registry
module acr 'modules/container-registry.bicep' = {
  name: 'acr-deployment'
  params: {
    location: location
    resourceSuffix: resourceSuffix
    tags: commonTags
    skuName: environment == 'prod' ? 'Premium' : 'Standard'
    adminUserEnabled: false
    enableDiagnostics: enableDiagnostics
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// Key Vault
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    location: location
    resourceSuffix: resourceSuffix
    tags: commonTags
    adminObjectId: keyVaultAdminObjectId
    enablePurgeProtection: environment == 'prod'
    enableDiagnostics: enableDiagnostics
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// Storage Account
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    location: location
    resourceSuffix: resourceSuffix
    tags: commonTags
    skuName: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
    accessTier: 'Hot'
    enableDiagnostics: enableDiagnostics
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// SQL Database
module sqlDatabase 'modules/sql-database.bicep' = {
  name: 'sql-deployment'
  params: {
    location: location
    resourceSuffix: resourceSuffix
    tags: commonTags
    adminLogin: sqlAdminLogin
    adminPassword: sqlAdminPassword
    skuName: environment == 'prod' ? 'GP_Gen5_4' : 'GP_Gen5_2'
    enableDiagnostics: enableDiagnostics
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// AKS Cluster
module aks 'modules/aks.bicep' = {
  name: 'aks-deployment'
  params: {
    location: location
    resourceSuffix: resourceSuffix
    tags: commonTags
    vnetId: vnet.outputs.vnetId
    aksSubnetId: vnet.outputs.aksSubnetId
    vmSku: vmSkuAKS
    nodeCount: aksNodeCount
    enableDiagnostics: enableDiagnostics
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    acrId: acr.outputs.acrId
    keyVaultId: keyVault.outputs.keyVaultId
  }
}

output vnetId string = vnet.outputs.vnetId
output aksClusterId string = aks.outputs.aksClusterId
output acrLoginServer string = acr.outputs.loginServer
output keyVaultUri string = keyVault.outputs.vaultUri
output storageAccountId string = storage.outputs.storageAccountId
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId
output appInsightsInstrumentationKey string = appInsights.outputs.instrumentationKey
output sqlDatabaseName string = sqlDatabase.outputs.databaseName
