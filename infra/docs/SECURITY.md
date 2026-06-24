# Security Hardening & Best Practices

This document outlines security controls, hardening measures, and compliance considerations for the Azure infrastructure deployed via this IaC suite.

## 🔒 Network Security

### Network Segmentation
```
┌─────────────────────────────────────────────────────────────────┐
│ VNet (10.0.0.0/16 prod | 10.1.0.0/16 dev)                      │
│ ├─ AKS Subnet (10.0.1.0/24 | 10.1.1.0/24)                       │
│ │  └─ NSG: Allow HTTP/HTTPS from any, Internal VNet traffic    │
│ ├─ App Subnet (10.0.2.0/24 | 10.1.2.0/24)                       │
│ │  └─ NSG: Allow HTTPS only from AKS subnet                    │
│ └─ Gateway Subnet (10.0.3.0/24 | 10.1.3.0/24)                   │
│    └─ For future Application Gateway/VPN gateway               │
└─────────────────────────────────────────────────────────────────┘
```

### Network Security Group Rules (Priority Order)

**AKS NSG**:
- 100: Allow VirtualNetwork → VirtualNetwork (all ports)
- 110: Allow * → 443 HTTPS
- 120: Allow * → 80 HTTP
- 4096: Deny all others (implicit)

**App NSG**:
- 100: Allow 10.0.1.0/24 (AKS subnet) → 443
- 4096: Deny all others (implicit)

### Implementation
```bash
# View NSG rules
az network nsg rule list --resource-group <rg> --nsg-name <nsg-name> --output table

# Add custom rule (least privilege)
az network nsg rule create \
  --resource-group <rg> \
  --nsg-name nsg-app-prod \
  --name allow-private-ip \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 10.0.0.0/8 \
  --destination-port-ranges 443
```

## 🔑 Identity & Access Management (IAM)

### Role-Based Access Control (RBAC)

**Least Privilege Principle**: Each service gets minimum required permissions.

| Service | Role | Scope | Purpose |
|---------|------|-------|---------|
| AKS | AcrPull | ACR | Pull container images |
| AKS | Key Vault Secrets User | Key Vault | Access secrets |
| App | Key Vault Secrets User | Key Vault | Runtime secrets |
| SQL | SQL DB Admin | SQL Database | Application queries |

### Implementation

```bicep
// AKS to ACR access
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, aksCluster.id, 'AcrPull')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull role ID
    )
    principalId: aksCluster.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// AKS to Key Vault access
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultId, aksCluster.id, 'KeyVaultSecretsUser')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86d0e6e' // Key Vault Secrets User
    )
    principalId: aksCluster.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
```

### Custom Roles (Advanced)

Create custom roles for application-specific permissions:

```json
{
  "Name": "AKS App Operations",
  "IsCustom": true,
  "Description": "Permissions for AKS app deployment operations",
  "Actions": [
    "Microsoft.ContainerRegistry/registries/pull/read",
    "Microsoft.KeyVault/vaults/secrets/getSecret/action"
  ],
  "NotActions": [],
  "AssignableScopes": ["/subscriptions/<subscription-id>"]
}
```

## 🛡️ Data Security

### Encryption

**At Rest** (Azure-managed):
- ✅ Storage Account: SSE with Microsoft-managed keys
- ✅ SQL Database: TDE (Transparent Data Encryption)
- ✅ Key Vault: FIPS 140-2 Level 2 certified

**In Transit**:
- ✅ HTTPS/TLS 1.2 minimum enforced
- ✅ Storage Account: `https_traffic_only_enabled = true`
- ✅ SQL Server: `minimumTlsVersion = '1.2'`
- ✅ Key Vault: Only HTTPS connections allowed

### Implementation Example

```terraform
resource "azurerm_storage_account" "sa" {
  name                     = "st${var.resource_suffix}"
  https_traffic_only_enabled = true
  min_tls_version          = "TLS1_2"

  # Encryption configuration
  encryption {
    status           = "Enabled"
    key_source       = "Microsoft.Storage"
    key_vault_key_id = azurerm_key_vault_key.sa_key.id # BYOK
  }
}
```

### Key Rotation

**SQL Database Credentials**:
```bash
# Rotate SQL password
az sql server ad-admin update \
  --resource-group <rg> \
  --server-name <server> \
  --display-name <admin-email> \
  --object-id <object-id>

# Update Key Vault secret
az keyvault secret set \
  --vault-name <kv-name> \
  --name sql-admin-password \
  --value <new-password>
```

**Storage Account Keys**:
```bash
az storage account keys renew \
  --resource-group <rg> \
  --account-name <sa-name> \
  --key primary
```

## 📊 Monitoring & Auditing

### Diagnostic Logging

All resources send logs to Log Analytics:

```bicep
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${resourceName}'
  scope: resource
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'       // Key Vault
        category: 'kube-audit'       // AKS
        category: 'Errors'           // SQL
        category: 'ContainerRegistryRepositoryEvents' // ACR
        enabled: true
      }
    ]
  }
}
```

### Key Audit Queries (KQL)

**Failed Login Attempts**:
```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.KEYVAULT"
| where OperationName == "SecretGet" and ResultSignature == "Unauthorized"
| summarize FailedAttempts = count() by ClientIPAddress, UserPrincipalName
| where FailedAttempts > 5
```

**SQL Query Anomalies**:
```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.SQL"
| where Category == "QueryStoreRuntimeStatistics"
| where Duration > 5000
| project TimeGenerated, Query_s, Duration, ResourceName
| order by Duration desc
```

**ACR Image Push Events**:
```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.CONTAINERREGISTRY"
| where OperationName == "ImagePush"
| project TimeGenerated, RepositoryName_s, ImageTag_s, UserPrincipalName
```

### Alerting

**High-Priority Alerts**:
- Key Vault unauthorized access (5+ attempts in 5 min)
- SQL threat detection events
- Failed AKS node provisioning
- Storage account public access changes

```bicep
resource kvAccessAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-kv-unauthorized-access'
  location: 'global'
  properties: {
    description: 'Alert on Key Vault unauthorized access'
    severity: 1
    enabled: true
    scopes: [keyVault.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [{
        metricName: 'ServiceApiHit'
        operator: 'GreaterThan'
        threshold: 5
        timeAggregation: 'Count'
      }]
    }
  }
}
```

## 🔒 Key Vault Hardening

### Soft Delete & Purge Protection

```bicep
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  // ... configuration
  properties: {
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: environment == 'prod' ? true : false
  }
}
```

### Access Policies vs RBAC (Recommended)

```bicep
// Legacy (deprecated): Access policies
accessPolicies: [{
  tenantId: subscription().tenantId
  objectId: adminObjectId
  permissions: {
    keys: ['get', 'list', 'create', 'delete']
    secrets: ['get', 'list', 'set', 'delete']
  }
}]

// Recommended: RBAC
enableRbacAuthorization: true
// Use role assignments instead
```

### Network Restrictions

```bicep
networkAcls: {
  bypass: 'AzureServices'
  defaultAction: 'Allow'
  // Optional: Add private endpoint restrictions
  virtualNetworkRules: [{
    id: vnetRuleId
    action: 'Allow'
  }]
}
```

## 🗄️ SQL Security

### Threat Detection & Scanning

```bicep
resource threatDetection 'Microsoft.Sql/servers/securityAlertPolicies@2022-05-01-preview' = {
  properties: {
    state: 'Enabled'
    disabledAlerts: []
    emailAddresses: ['security@company.com']
    emailNotificationEnabled: true
    retentionDays: 30
  }
}

resource vulnAssessment 'Microsoft.Sql/servers/sqlVulnerabilityAssessments@2022-08-01-preview' = {
  properties: {
    recurringScans: {
      isEnabled: true
      scanTriggerType: 'Weekly'
      weeklyScans: { isEnabled: true, day: 'Sunday' }
    }
  }
}
```

### Firewall & Connectivity

```sql
-- Allow specific IP range
EXECUTE sp_set_database_firewall_rule
  @name = 'AllowAppServer',
  @start_ip_address = '10.0.1.0',
  @end_ip_address = '10.0.1.255';

-- Deny direct internet access
-- Only allow via private endpoint in production
```

## 🐳 Container Registry Security

### Image Scanning & Signing

```bicep
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  properties: {
    policies: {
      quarantinePolicy: {
        status: 'enabled'  // Scan before use
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled' // Enable for production
      }
    }
  }
}
```

### Restrict Access

```bash
# Allow only VNet access to ACR
az network vnet-endpoint service-endpoint add \
  --resource-group <rg> \
  --vnet <vnet-name> \
  --subnet <subnet-name> \
  --service Microsoft.ContainerRegistry

# Add ACR firewall rule
az acr network-rule add \
  --resource-group <rg> \
  --name <acr-name> \
  --vnet-id <vnet-id> \
  --subnet <subnet-id>
```

## ☸️ AKS Security

### Network Policies

```yaml
# Deny all inbound by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress

---
# Allow ingress only from specific namespaces
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-api
spec:
  podSelector:
    matchLabels:
      role: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: backend
```

### Azure Policy Enforcement

```bicep
resource aks 'Microsoft.ContainerService/managedClusters@2023-10-01' = {
  properties: {
    azurePolicy: {
      enabled: true
      config: {
        version: 'v2'
      }
    }
  }
}
```

## 🔄 Backup & Disaster Recovery

### Backup Policies

**SQL Database**:
- Short-term: 7 days (daily)
- Long-term: 12 months (yearly)
- Geo-redundant: Automatic (prod)

**Storage Account**:
- Blob versioning: Enabled
- Soft delete: 7 days
- Lifecycle: Archive after 30 days, delete after 365 days

### Restore Procedures

```bash
# Restore SQL database to point-in-time
az sql db restore \
  --resource-group <rg> \
  --server <server> \
  --name <db-name> \
  --dest-name <new-db-name> \
  --time "2024-01-15T12:00:00"

# Restore blob from snapshot
az storage blob copy start \
  --account-name <sa-name> \
  --source-container <source-container> \
  --source-blob <blob-snapshot-uri> \
  --destination-container <dest-container> \
  --destination-blob <new-blob-name>
```

## 📋 Compliance Checklist

- [ ] All resources tagged with owner, environment, cost-center
- [ ] Diagnostic logging enabled for all services
- [ ] Key Vault soft delete and purge protection configured
- [ ] Network security groups restrict traffic to least-privilege
- [ ] RBAC roles assigned using managed identities
- [ ] SQL threat detection and auditing enabled
- [ ] Container images scanned before deployment
- [ ] Backups configured and tested
- [ ] DDoS protection considered (Application Gateway)
- [ ] Secrets never committed to repository
- [ ] Regular security assessments scheduled (quarterly)
- [ ] Incident response procedures documented

## 🚨 Security Incident Response

### Key Vault Unauthorized Access
1. Check audit logs: `AzureDiagnostics | where OperationName == "SecretGet" | where ResultSignature == "Unauthorized"`
2. Revoke compromised credentials
3. Rotate affected secrets
4. Review access policies and RBAC assignments

### Suspicious SQL Activity
1. Check threat detection alerts
2. Review query logs for unusual patterns
3. Implement stricter firewall rules
4. Consider enabling Advanced Threat Protection (ATP)

### Container Image Compromise
1. Flag image in ACR (set `quarantine` policy)
2. Review deployment history
3. Force pod restart with new image
4. Scan cluster for affected deployments

---

**Last Reviewed**: 2026-06-24  
**Next Review**: 2026-09-24  
**Owner**: Security & Platform Teams
