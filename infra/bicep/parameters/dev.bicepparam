// Development environment parameters
// Lower resource SKUs, minimal redundancy, shorter retention for cost optimization

using './main.bicep'

param environment = 'dev'
param projectName = 'myapp'
param location = 'eastus'
param vmSkuAKS = 'Standard_D2s_v3'
param aksNodeCount = 1
param sqlAdminLogin = 'sqladmin'
// PLACEHOLDER: Replace with actual password during deployment
param sqlAdminPassword = 'CHANGE-ME-DEV-PASSWORD-123!'
// PLACEHOLDER: Replace with your Azure AD object ID for Key Vault admin
param keyVaultAdminObjectId = '00000000-0000-0000-0000-000000000000'
param enableDiagnostics = true
param logRetentionDays = 30
