# Maintenance & Operational Runbook

Standard operating procedures for maintaining and troubleshooting the Azure infrastructure.

## 📅 Regular Maintenance Tasks

### Daily Checks

```bash
#!/bin/bash
set -e

RESOURCE_GROUP="rg-myapp-prod"

echo "📊 Daily Health Check - $(date)"
echo "========================================"

# AKS Node Status
AKS_CLUSTER=$(az resource list --resource-group $RESOURCE_GROUP --resource-type Microsoft.ContainerService/managedClusters -o json | jq -r '.[0].name')
echo ""
echo "✓ AKS Nodes Status:"
kubectl get nodes --no-headers | while read line; do
  STATUS=$(echo $line | awk '{print $2}')
  if [ "$STATUS" != "Ready" ]; then
    echo "⚠️  Node alert: $line"
  fi
done

# Pod Restart Count
echo ""
echo "✓ Pods with High Restart Count (>5):"
kubectl get pods -A --no-headers -o json | jq -r '.items[] | select(.status.containerStatuses[0].restartCount > 5) | "\(.metadata.namespace) \(.metadata.name) \(.status.containerStatuses[0].restartCount)"'

# Pending Pods
echo ""
echo "✓ Pending Pods:"
PENDING=$(kubectl get pods -A --field-selector=status.phase=Pending --no-headers | wc -l)
if [ $PENDING -gt 0 ]; then
  echo "⚠️  Warning: $PENDING pending pods detected"
  kubectl get pods -A --field-selector=status.phase=Pending
fi

# Storage Quota
echo ""
echo "✓ Storage Account Usage:"
SA_NAME=$(az resource list --resource-group $RESOURCE_GROUP --resource-type Microsoft.Storage/storageAccounts -o json | jq -r '.[0].name')
USED=$(az storage account show \
  --resource-group $RESOURCE_GROUP \
  --name $SA_NAME \
  --query 'primaryBlobEndpoint' -o tsv | sed 's|.*https://\([^.]*\).*|\1|')

# Key Vault Status
echo ""
echo "✓ Key Vault Secrets (Expiration Check):"
KV_NAME=$(az resource list --resource-group $RESOURCE_GROUP --resource-type Microsoft.KeyVault/vaults -o json | jq -r '.[0].name')
az keyvault secret list --vault-name $KV_NAME --query '[].{Name:name, Expires:attributes.expires}' --output table

echo ""
echo "✅ Daily health check complete"
```

### Weekly Tasks

**Monday morning**:
1. Review deployment logs and CI/CD status
2. Check Cost Analysis in Azure Portal
3. Review security alerts and access logs
4. Validate backups completed successfully

**Wednesday**:
1. Update Kubernetes manifests for new deployments
2. Rotate credentials if policies require (90-day cycle)

**Friday**:
1. Capacity planning review
2. Test disaster recovery procedures
3. Backup verification audit

### Monthly Tasks

1. **Security Review**:
   ```bash
   # Check for unused resources
   az resource list --resource-group $RESOURCE_GROUP --query '[?tags.LastUsed<`'"$(date -d '30 days ago' +'%Y-%m-%d')"'`]' --output table
   
   # Review failed deployments
   az deployment group list --resource-group $RESOURCE_GROUP --query '[?properties.provisioningState==`Failed`]'
   ```

2. **Performance Optimization**:
   ```bash
   # Review slow queries
   az sql db query-performance-insight top-queries \
     --resource-group $RESOURCE_GROUP \
     --server $SQL_SERVER \
     --database $SQL_DATABASE
   ```

3. **Cost Optimization**:
   - Review underutilized resources
   - Right-size VM/AKS node SKUs
   - Analyze storage tiering effectiveness

4. **Compliance Audit**:
   - RBAC role assignments
   - Encryption status
   - Network isolation
   - Backup retention policies

## 🔧 Scaling Operations

### Scale AKS Cluster

**Manually**:
```bash
#!/bin/bash

AKS_CLUSTER="aks-myapp-prod"
RESOURCE_GROUP="rg-myapp-prod"
NEW_NODE_COUNT=5

# Scale node pool
az aks nodepool scale \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $AKS_CLUSTER \
  --name system \
  --node-count $NEW_NODE_COUNT

echo "✅ Scaled to $NEW_NODE_COUNT nodes"
```

**Autoscale Configuration**:
```bash
# Update autoscale limits
az aks nodepool update \
  --resource-group $RESOURCE_GROUP \
  --cluster-name $AKS_CLUSTER \
  --name system \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 10

echo "✅ Autoscaling enabled (min: 2, max: 10)"
```

### Scale SQL Database

```bash
#!/bin/bash

SQL_SERVER="sqlmyappprod"
SQL_DATABASE="dbmyappprod"
RESOURCE_GROUP="rg-myapp-prod"

# Current SKU
echo "Current SKU:"
az sql db show --resource-group $RESOURCE_GROUP --server $SQL_SERVER --name $SQL_DATABASE --query 'sku.name'

# Scale to higher SKU
az sql db update \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER \
  --name $SQL_DATABASE \
  --service-objective 'GP_Gen5_4'

echo "✅ Scaled SQL database to GP_Gen5_4"
```

### Scale Storage Account

```bash
# Storage is auto-scaled; manage access tiers instead
az storage account update \
  --resource-group $RESOURCE_GROUP \
  --name $SA_NAME \
  --access-tier Cool

# For geo-replication to another region
# (requires new storage account due to immutable replica location)
```

## 🔄 Updates & Upgrades

### Kubernetes Version Upgrade

```bash
#!/bin/bash

AKS_CLUSTER="aks-myapp-prod"
RESOURCE_GROUP="rg-myapp-prod"
TARGET_VERSION="1.28.0"

# Check available versions
az aks get-versions --location eastus --query 'orchestrators[].version'

# Upgrade control plane
az aks upgrade \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER \
  --kubernetes-version $TARGET_VERSION \
  --control-plane-only

# Wait for control plane upgrade
echo "Waiting for control plane upgrade..."
while true; do
  STATUS=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --query 'kubernetesVersion' -o tsv)
  if [ "$STATUS" == "$TARGET_VERSION" ]; then
    echo "✅ Control plane upgraded"
    break
  fi
  sleep 30
done

# Upgrade node pools
for POOL in $(az aks nodepool list --resource-group $RESOURCE_GROUP --cluster-name $AKS_CLUSTER -o json | jq -r '.[].name'); do
  az aks nodepool upgrade \
    --resource-group $RESOURCE_GROUP \
    --cluster-name $AKS_CLUSTER \
    --name $POOL \
    --kubernetes-version $TARGET_VERSION
done

echo "✅ Kubernetes upgraded to $TARGET_VERSION"
```

### Azure SQL Database Maintenance Window

```bash
# Set maintenance window (non-prod times)
az sql db maintenance-window set \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER \
  --database $SQL_DATABASE \
  --maintenance-window-start-day Sun \
  --maintenance-window-start-hour 22 \
  --maintenance-window-duration 60

echo "✅ Maintenance window configured"
```

## 🔍 Troubleshooting

### AKS Issues

**Nodes NotReady**:
```bash
# Check node status
kubectl describe node <node-name>

# Check kubelet logs
az aks command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER \
  --command "journalctl -u kubelet -n 50"

# Cordon and drain for maintenance
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets
```

**Pods Pending**:
```bash
# Check events
kubectl describe pod <pod-name> -n <namespace>

# Check resource requests/limits
kubectl get pod <pod-name> -n <namespace> -o json | jq '.spec.containers[].resources'

# Check node capacity
kubectl top nodes

# Increase resource limits
kubectl set resources deployment <deployment> \
  -n <namespace> \
  --limits=cpu=500m,memory=512Mi \
  --requests=cpu=250m,memory=256Mi
```

**Image Pull Errors**:
```bash
# Check ACR credentials
az acr credential show --resource-group $RESOURCE_GROUP --name $ACR_NAME

# Create image pull secret
kubectl create secret docker-registry acr-secret \
  --docker-server=<acr-login-server> \
  --docker-username=<username> \
  --docker-password=<password> \
  -n <namespace>

# Update deployment to use secret
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "acr-secret"}]}' -n <namespace>
```

### SQL Server Issues

**Connection Timeouts**:
```bash
# Check firewall rules
az sql server firewall-rule list --resource-group $RESOURCE_GROUP --server $SQL_SERVER

# Add connection troubleshooting
az sql server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Check connection string
# Format: Server=tcp:<server>.database.windows.net,1433;Initial Catalog=<db>;...
```

**Performance Issues**:
```bash
# Check Query Performance Insights
az sql db query-performance-insight \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER \
  --database $SQL_DATABASE

# Run diagnostic
DBCC SQLPERF(logspace);  -- in SQL
DBCC DROPCLEANBUFFERS;   -- clear cache for clean test
```

**Backup & Restore**:
```bash
# List backups
az sql db list-backups \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER \
  --database $SQL_DATABASE

# Restore to point-in-time
az sql db restore \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER \
  --name $SQL_DATABASE \
  --dest-name ${SQL_DATABASE}-restored \
  --time "2024-01-15T12:00:00Z"
```

### Key Vault Issues

**Access Denied**:
```bash
# Check access policies
az keyvault show --name $KV_NAME --resource-group $RESOURCE_GROUP --query 'properties.accessPolicies'

# Add access policy
az keyvault set-policy \
  --name $KV_NAME \
  --object-id <principal-id> \
  --secret-permissions get list set delete

# Check RBAC
az role assignment list --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KV_NAME"
```

**Secret Rotation Issues**:
```bash
# Rotate secret
az keyvault secret set \
  --vault-name $KV_NAME \
  --name <secret-name> \
  --value <new-value>

# Update applications to use new secret
# (Restart pods if using mounted secrets)
```

### Storage Account Issues

**Blob Access Problems**:
```bash
# Check access tier
az storage account show \
  --resource-group $RESOURCE_GROUP \
  --name $SA_NAME \
  --query 'accessTier'

# List blob containers
az storage container list --account-name $SA_NAME

# Check SAS token
az storage account generate-sas \
  --account-name $SA_NAME \
  --resource-types sco \
  --services bfqt \
  --expiry 2024-12-31T23:59:59Z \
  --permissions racwd \
  --https-only
```

## 🚨 Emergency Procedures

### Service Recovery (AKS Down)

```bash
#!/bin/bash
set -e

echo "🚨 Emergency AKS Recovery Procedure"

RESOURCE_GROUP="rg-myapp-prod"
AKS_CLUSTER="aks-myapp-prod"

# Step 1: Check cluster status
STATUS=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --query 'provisioningState' -o tsv)
echo "Cluster status: $STATUS"

# Step 2: Restart AKS API server (if responsive)
if [ "$STATUS" == "Succeeded" ]; then
  echo "Attempting cluster restart..."
  az aks stop --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER
  sleep 60
  az aks start --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER
  echo "✅ Cluster restarted"
fi

# Step 3: Check node pool health
NODES=$(kubectl get nodes --no-headers | wc -l)
if [ $NODES -lt 1 ]; then
  echo "⚠️  No ready nodes! Scaling node pool..."
  az aks nodepool scale \
    --resource-group $RESOURCE_GROUP \
    --cluster-name $AKS_CLUSTER \
    --name system \
    --node-count 3
fi

# Step 4: Wait for nodes to be ready
echo "Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=600s

# Step 5: Verify critical pods
echo "Verifying critical pods..."
kubectl get pods -A

echo "✅ Emergency recovery complete"
```

### Database Recovery (SQL Corrupted)

```bash
# Quick recovery: Point-in-time restore
az sql db restore \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER \
  --name $SQL_DATABASE \
  --dest-name ${SQL_DATABASE}-recovery \
  --time "2024-01-15T11:00:00Z"

# Swap connections to recovered DB
# (Update connection strings in Key Vault)
```

## 📞 Escalation Contacts

| Issue | Primary Contact | Escalation |
|-------|---|---|
| AKS/Kubernetes | Platform Team | Cloud Ops |
| SQL Database | Database Team | Microsoft Support |
| Network | Network Team | Cloud Ops |
| Security | InfoSec Team | CISO |
| Cost Overruns | Finance + Platform | VP Engineering |

## 📚 Documentation References

- **IaC Updates**: See [../../docs/README.md](../../docs/README.md)
- **Security**: See [../../docs/SECURITY.md](../../docs/SECURITY.md)
- **Deployment**: See [./DEPLOYMENT.md](./DEPLOYMENT.md)
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **Azure Docs**: https://docs.microsoft.com/en-us/azure/

---

**Last Updated**: 2026-06-24 | **Version**: 1.0 | **Owner**: Operations Team
