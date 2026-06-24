// Production environment parameters
// High availability SKUs, geo-redundancy, extended retention for compliance

using './main.bicep'

param environment = 'prod'
param projectName = 'myapp'
param location = 'eastus'
param vmSkuAKS = 'Standard_D4s_v3'
param aksNodeCount = 3
param sqlAdminLogin = 'sqladmin'
// PLACEHOLDER: Replace with actual password during deployment (use Key Vault reference)
param sqlAdminPassword = 'CHANGE-ME-PROD-PASSWORD-STRONG-123!'
// PLACEHOLDER: Replace with your Azure AD object ID for Key Vault admin
param keyVaultAdminObjectId = '00000000-0000-0000-0000-000000000000'
param enableDiagnostics = true
param logRetentionDays = 90
