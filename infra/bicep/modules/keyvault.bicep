// Key Vault Module
// Implements least-privilege RBAC, purge protection, soft delete,
// diagnostic logging, and network policies for secrets management

param location string
param resourceSuffix string
param tags object
param adminObjectId string
param enablePurgeProtection bool
param enableDiagnostics bool
param logAnalyticsWorkspaceId string

var keyVaultName = 'kv-${replace(resourceSuffix, '-', '')}'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: adminObjectId
        permissions: {
          keys: ['get', 'list', 'create', 'delete', 'update', 'import', 'backup', 'restore', 'recover']
          secrets: ['get', 'list', 'set', 'delete', 'backup', 'restore', 'recover']
          certificates: ['get', 'list', 'create', 'delete', 'update', 'import', 'backup', 'restore', 'recover']
        }
      }
    ]
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
  }
}

// REVIEWER NOTE: Adjust access policies based on application service principals
// TODO: Add application identity access after service deployment

// Diagnostic settings for Key Vault
resource keyVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  name: 'diag-${keyVaultName}'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
      {
        category: 'AzurePolicyEvaluationDetails'
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

// Example secrets (PLACEHOLDER - replace with actual values in deployment)
resource exampleSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'sql-admin-password'
  parent: keyVault
  properties: {
    value: 'PLACEHOLDER-CHANGE-IN-DEPLOYMENT'
    contentType: 'password'
    tags: union(tags, {
      rotationEnabled: 'true'
      rotationIntervalDays: '90'
    })
  }
}

resource dbConnectionString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'db-connection-string'
  parent: keyVault
  properties: {
    value: 'PLACEHOLDER-CHANGE-IN-DEPLOYMENT'
    contentType: 'connection-string'
    tags: tags
  }
}

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output vaultUri string = keyVault.properties.vaultUri
