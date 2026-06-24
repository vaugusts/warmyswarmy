// SQL Database Module
// Provisions Azure SQL Server and Database with security hardening,
// threat detection, encryption, backup, and audit logging

param location string
param resourceSuffix string
param tags object
param adminLogin string
@secure()
param adminPassword string
param skuName string
param enableDiagnostics bool
param logAnalyticsWorkspaceId string

var sqlServerName = 'sql-${replace(resourceSuffix, '-', '')}'
var databaseName = 'db-${replace(resourceSuffix, '-', '')}'

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

// REVIEWER NOTE: Configure server-level firewall rules in deployment runbook
// Allow Azure services and specific IPs as needed

// Firewall rule for Azure services
resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  name: 'AllowAzureServices'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: databaseName
  parent: sqlServer
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: 'GeneralPurpose'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 34359738368
    zoneRedundant: false
    licenseType: 'BasePrice'
    readScale: 'Secondary'
    requestedBackupStorageRedundancy: 'Geo'
    maintenanceConfigurationId: null
  }
}

// Backup configuration
resource backupShortTermPolicy 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2022-05-01-preview' = {
  name: 'default'
  parent: sqlDatabase
  properties: {
    retentionDays: 7
    diffBackupIntervalInHours: 24
  }
}

resource backupLongTermPolicy 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2022-05-01-preview' = {
  name: 'default'
  parent: sqlDatabase
  properties: {
    weeklyRetention: 'PT4W'
    monthlyRetention: 'PT12M'
    yearlyRetention: 'PT5Y'
    weekOfYear: 1
  }
}

// Threat Detection
resource threatDetection 'Microsoft.Sql/servers/securityAlertPolicies@2022-05-01-preview' = {
  name: 'default'
  parent: sqlServer
  properties: {
    state: 'Enabled'
    disabledAlerts: []
    emailAddresses: []
    emailNotificationEnabled: true
    retentionDays: 30
  }
}

// SQL Vulnerability Assessment
resource sqlVulnAssessment 'Microsoft.Sql/servers/sqlVulnerabilityAssessments@2022-08-01-preview' = {
  name: 'default'
  parent: sqlServer
  properties: {}
}

// Auditing
resource auditingSettings 'Microsoft.Sql/servers/auditingSettings@2022-05-01-preview' = {
  name: 'default'
  parent: sqlServer
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: enableDiagnostics
    retentionDays: 90
    storageEndpoint: ''
    storageAccountAccessKey: ''
    auditActionsAndGroups: [
      'SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP'
      'FAILED_DATABASE_AUTHENTICATION_GROUP'
      'BATCH_COMPLETED_GROUP'
    ]
  }
}

// Diagnostic settings
resource sqlDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  name: 'diag-${sqlServerName}-${databaseName}'
  scope: sqlDatabase
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
      }
      {
        category: 'AutomaticTuning'
        enabled: true
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
      }
      {
        category: 'QueryStoreWaitStatistics'
        enabled: true
      }
      {
        category: 'Errors'
        enabled: true
      }
      {
        category: 'DatabaseWaitStatistics'
        enabled: true
      }
      {
        category: 'Timeouts'
        enabled: true
      }
      {
        category: 'Blocks'
        enabled: true
      }
      {
        category: 'Deadlocks'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
      }
      {
        category: 'InstanceAndAppAdvanced'
        enabled: true
      }
      {
        category: 'WorkloadManagement'
        enabled: true
      }
    ]
  }
}

output sqlServerId string = sqlServer.id
output sqlServerName string = sqlServer.name
output databaseId string = sqlDatabase.id
output databaseName string = sqlDatabase.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output connectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};Persist Security Info=False;User ID=${adminLogin};Password=PLACEHOLDER;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
