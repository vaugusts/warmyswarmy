# Deployment Runbook

Complete step-by-step procedures for deploying Azure infrastructure via Bicep and Terraform.

## 📋 Pre-Deployment Checklist

- [ ] Azure subscription access verified
- [ ] Required Azure AD permissions (Directory.Read.All, Application.ReadWrite.All)
- [ ] CLI tools installed: Azure CLI (>=2.53), Terraform (>=1.5), kubectl
- [ ] Service principal or managed identity configured
- [ ] Backend storage account created (Terraform state)
- [ ] GitHub Actions secrets/Azure DevOps variables configured
- [ ] Parameter files reviewed and customized
- [ ] DNS and naming conventions finalized
- [ ] Budget/quota limits verified

## 🔧 Prerequisites Setup

### 1. Create Terraform Backend Storage

```bash
#!/bin/bash
set -e

SUBSCRIPTION_ID="<your-subscription-id>"
BACKEND_RG="rg-terraform-state"
BACKEND_SA="stterraformstate"
BACKEND_CONTAINER="tfstate"
LOCATION="eastus"

# Login
az login --use-device-code
az account set --subscription $SUBSCRIPTION_ID

# Create resource group
az group create \
  --name $BACKEND_RG \
  --location $LOCATION \
  --tags Purpose=TerraformState Environment=shared

# Create storage account
az storage account create \
  --resource-group $BACKEND_RG \
  --name $BACKEND_SA \
  --location $LOCATION \
  --sku Standard_GRS \
  --kind StorageV2 \
  --access-tier Hot \
  --https-only true \
  --min-tls-version TLS1_2 \
  --enable-hierarchical-namespace false

# Create container
az storage container create \
  --account-name $BACKEND_SA \
  --name $BACKEND_CONTAINER

# Enable versioning for recovery
az storage account blob-service-properties update \
  --account-name $BACKEND_SA \
  --enable-restore-policy true \
  --enable-change-feed true

echo "✅ Backend infrastructure ready"
echo "Backend Storage: $BACKEND_SA/$BACKEND_CONTAINER"
```

### 2. Configure Service Principal (for CI/CD)

```bash
#!/bin/bash
set -e

SUBSCRIPTION_ID="<your-subscription-id>"
SERVICE_PRINCIPAL_NAME="sp-iac-deployment"
LOCATION="eastus"

# Create service principal
az ad sp create-for-rbac \
  --name $SERVICE_PRINCIPAL_NAME \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --query '{clientId:appId, clientSecret:password, tenantId:tenant}' \
  --output json > sp-credentials.json

# Extract credentials (for GitHub Actions/Azure DevOps)
CLIENT_ID=$(jq -r '.clientId' sp-credentials.json)
CLIENT_SECRET=$(jq -r '.clientSecret' sp-credentials.json)
TENANT_ID=$(jq -r '.tenantId' sp-credentials.json)

echo "Store these values as secrets:"
echo "AZURE_CLIENT_ID=$CLIENT_ID"
echo "AZURE_CLIENT_SECRET=$CLIENT_SECRET"
echo "AZURE_TENANT_ID=$TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID"

# Enable federated credentials for GitHub (OIDC)
SUBJECT_IDENTIFIER="repo:<owner>/<repo>:ref:refs/heads/main"
ISSUER="https://token.actions.githubusercontent.com"

az ad app federated-credential create \
  --id $CLIENT_ID \
  --parameters "{
    'name': 'GitHubActionsFederated',
    'issuer': '$ISSUER',
    'subject': '$SUBJECT_IDENTIFIER',
    'audiences': ['api://AzureADTokenExchange']
  }"

rm sp-credentials.json
```

### 3. Get Azure AD Object ID for Key Vault Admin

```bash
#!/bin/bash

# Option 1: Your user
YOUR_EMAIL="your.email@company.com"
OBJECT_ID=$(az ad user show --id $YOUR_EMAIL --query id -o tsv)
echo "Your Object ID: $OBJECT_ID"

# Option 2: Group
GROUP_NAME="Azure Infrastructure Admins"
GROUP_ID=$(az ad group show --group "$GROUP_NAME" --query id -o tsv)
echo "Group Object ID: $GROUP_ID"

# Option 3: Service Principal
SP_NAME="sp-iac-deployment"
SP_ID=$(az ad sp show --id $SP_NAME --query id -o tsv)
echo "Service Principal Object ID: $SP_ID"
```

## 🚀 Deployment - Bicep

### Local Deployment (Single Environment)

```bash
#!/bin/bash
set -e

# Configuration
ENVIRONMENT="dev"  # or "prod"
PROJECT_NAME="myapp"
LOCATION="eastus"
RESOURCE_GROUP="rg-${PROJECT_NAME}-${ENVIRONMENT}"
KEY_VAULT_ADMIN_ID="<from-previous-step>"
SQL_ADMIN_PASSWORD="<strong-password-123!>" # Change in production

# Step 1: Login
echo "🔐 Authenticating to Azure..."
az login --use-device-code
az account set --subscription <subscription-id>

# Step 2: Create resource group
echo "📦 Creating resource group..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags \
    Environment=$ENVIRONMENT \
    Project=$PROJECT_NAME \
    ManagedBy=Bicep \
    DeployedAt=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

# Step 3: Validate template
echo "✔️  Validating Bicep template..."
az bicep build --file infra/bicep/main.bicep --outdir /tmp

az deployment group validate \
  --resource-group $RESOURCE_GROUP \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/parameters/${ENVIRONMENT}.bicepparam \
  --parameters \
    keyVaultAdminObjectId=$KEY_VAULT_ADMIN_ID \
    sqlAdminPassword=$SQL_ADMIN_PASSWORD

# Step 4: Preview changes (what-if)
echo "👀 Previewing deployment changes..."
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/parameters/${ENVIRONMENT}.bicepparam \
  --parameters \
    keyVaultAdminObjectId=$KEY_VAULT_ADMIN_ID \
    sqlAdminPassword=$SQL_ADMIN_PASSWORD \
  --no-pretty-print > what-if-results.json

# Step 5: Deploy
echo "🚀 Deploying infrastructure (this may take 15-30 minutes)..."
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/parameters/${ENVIRONMENT}.bicepparam \
  --parameters \
    keyVaultAdminObjectId=$KEY_VAULT_ADMIN_ID \
    sqlAdminPassword=$SQL_ADMIN_PASSWORD \
  --mode Complete \
  --verbose

# Step 6: Retrieve and display outputs
echo "✅ Deployment complete!"
echo ""
echo "📊 Deployment Outputs:"
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name main \
  --query "properties.outputs" \
  --output json | jq '.'

# Step 7: Verify resources
echo ""
echo "🔍 Verifying resources..."
az resource list \
  --resource-group $RESOURCE_GROUP \
  --output table

# Step 8: Post-deployment (store outputs, notifications, etc.)
echo ""
echo "✨ Next steps:"
echo "1. Review deployment outputs (saved above)"
echo "2. Configure additional secrets in Key Vault"
echo "3. Update application configuration with outputs"
echo "4. Run post-deployment tests"
```

### Dry Run / What-If Analysis

```bash
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/parameters/${ENVIRONMENT}.bicepparam \
  | tee what-if-${ENVIRONMENT}-$(date +%s).log
```

## 🚀 Deployment - Terraform

### Local Deployment (Sequential: Dev → Prod)

```bash
#!/bin/bash
set -e

cd infra/terraform

# Configuration
ENVIRONMENTS=("dev" "prod")
BACKEND_RG="rg-terraform-state"
BACKEND_SA="stterraformstate"
BACKEND_CONTAINER="tfstate"

# Login
az login --use-device-code
az account set --subscription <subscription-id>

for ENV in "${ENVIRONMENTS[@]}"; do
  echo ""
  echo "=========================================="
  echo "Deploying: $ENV"
  echo "=========================================="

  # Step 1: Initialize
  echo "🔧 Initializing Terraform for $ENV..."
  terraform init \
    -backend-config="resource_group_name=$BACKEND_RG" \
    -backend-config="storage_account_name=$BACKEND_SA" \
    -backend-config="container_name=$BACKEND_CONTAINER" \
    -backend-config="key=${ENV}.tfstate" \
    -backend-config="use_azuread_auth=true"

  # Step 2: Format check
  echo "📋 Checking format..."
  terraform fmt -check -recursive . || terraform fmt -recursive .

  # Step 3: Validate
  echo "✔️  Validating configuration..."
  terraform validate

  # Step 4: Plan
  echo "📊 Generating plan..."
  terraform plan \
    -var-file="environments/${ENV}/${ENV}.tfvars" \
    -out=tfplan_${ENV} \
    -lock=true

  # Step 5: Interactive approval
  read -p "Review the plan above. Proceed with apply? (yes/no): " -r
  if [[ $REPLY != "yes" ]]; then
    echo "❌ Deployment cancelled by user"
    exit 1
  fi

  # Step 6: Apply
  echo "🚀 Applying configuration..."
  terraform apply tfplan_${ENV}

  # Step 7: Export outputs
  echo ""
  echo "📤 Exporting outputs..."
  terraform output -json > outputs_${ENV}.json
  echo "Outputs saved to: outputs_${ENV}.json"

  # Step 8: Cleanup plan file
  rm -f tfplan_${ENV}

  echo "✅ Deployment complete for $ENV"
done

echo ""
echo "✨ All environments deployed successfully!"
```

### State Management & Troubleshooting

```bash
# List current state
terraform state list

# Inspect specific resource
terraform state show azurerm_kubernetes_cluster.aks

# Backup state
cp terraform.tfstate terraform.tfstate.backup.$(date +%s)

# Remote state operations
terraform state pull > local-state-backup.json
terraform state push local-state-backup.json  # Careful!

# Refresh state (detect drift)
terraform refresh -var-file="environments/prod/prod.tfvars"

# Unlock stuck deployment (if mutex locked)
terraform force-unlock <lock-id>

# Import existing resource
terraform import azurerm_resource_group.rg /subscriptions/<sub>/resourceGroups/<rg-name>
```

## 🔐 Post-Deployment Steps

### 1. Secure SQL Database

```bash
#!/bin/bash

RESOURCE_GROUP="rg-myapp-prod"
SQL_SERVER="sql${RANDOM}"
SQL_DATABASE="dbmyappprod"
SQL_ADMIN="sqladmin"

# Set strong SQL password
NEW_SQL_PASSWORD="ChangeMe-Strong-Pass-$(date +%s | tail -c 5)"

# Update SQL admin password
az sql server update \
  --name $SQL_SERVER \
  --resource-group $RESOURCE_GROUP \
  --admin-password $NEW_SQL_PASSWORD

# Store in Key Vault
az keyvault secret set \
  --vault-name <kv-name> \
  --name "sql-admin-password" \
  --value $NEW_SQL_PASSWORD

# Test connection
sqlcmd -S "${SQL_SERVER}.database.windows.net" \
  -U $SQL_ADMIN \
  -P $NEW_SQL_PASSWORD \
  -d $SQL_DATABASE \
  -Q "SELECT @@version;"

echo "✅ SQL Server secured"
```

### 2. Configure AKS Cluster Access

```bash
#!/bin/bash

RESOURCE_GROUP="rg-myapp-prod"
AKS_CLUSTER="aks-myapp-prod"

# Get kubeconfig
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER \
  --admin  # Admin credentials for setup

# Verify cluster access
kubectl get nodes

# List available namespaces
kubectl get ns

# Deploy sample application (optional)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: default
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: test
        image: nginx:latest
EOF

echo "✅ AKS cluster ready"
```

### 3. Validate Resources

```bash
#!/bin/bash

RESOURCE_GROUP="rg-myapp-prod"

echo "🔍 Validating deployment..."

# Check all resources are created
RESOURCE_COUNT=$(az resource list --resource-group $RESOURCE_GROUP --query 'length([])' -o tsv)
echo "Total resources created: $RESOURCE_COUNT"

# Verify Key Vault
KV_NAME=$(az resource list --resource-group $RESOURCE_GROUP --resource-type Microsoft.KeyVault/vaults -o json | jq -r '.[0].name')
az keyvault show --name $KV_NAME

# Verify Storage Account
SA_NAME=$(az resource list --resource-group $RESOURCE_GROUP --resource-type Microsoft.Storage/storageAccounts -o json | jq -r '.[0].name')
az storage account show --resource-group $RESOURCE_GROUP --name $SA_NAME

# Verify SQL Server
SQL_SERVER=$(az resource list --resource-group $RESOURCE_GROUP --resource-type Microsoft.Sql/servers -o json | jq -r '.[0].name')
az sql server show --resource-group $RESOURCE_GROUP --name $SQL_SERVER

# Verify ACR
ACR_NAME=$(az resource list --resource-group $RESOURCE_GROUP --resource-type Microsoft.ContainerRegistry/registries -o json | jq -r '.[0].name')
az acr show --resource-group $RESOURCE_GROUP --name $ACR_NAME

# Verify AKS
AKS_NAME=$(az resource list --resource-group $RESOURCE_GROUP --resource-type Microsoft.ContainerService/managedClusters -o json | jq -r '.[0].name')
az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME

echo "✅ All resources validated"
```

## 🔄 CI/CD Configuration

### GitHub Actions Setup

1. **Create GitHub Secrets**:
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_CLIENT_ID` (service principal)
   - `SLACK_WEBHOOK` (optional, for notifications)

2. **Enable OIDC Federated Credentials** (recommended over secrets):
   ```bash
   az ad app federated-credential create \
     --id <client-id> \
     --parameters '{
       "name": "GitHubActionsFederated",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:<owner>/<repo>:ref:refs/heads/main",
       "audiences": ["api://AzureADTokenExchange"]
     }'
   ```

3. **Workflows** are in `.github/workflows/` and trigger automatically on PR/merge

### Azure DevOps Setup

1. **Create Service Connection**:
   ```bash
   az devops service-endpoint create --service-endpoint-type AzureRM
   ```

2. **Set Pipeline Variables**:
   - `AzureResourceConnection`: Service connection name
   - `AzureSubscriptionId`: Subscription ID
   - `TfBackendRg`, `TfBackendSa`, `TfBackendContainer`: Backend config

3. **Pipeline YAML** in `infra/pipelines/azure-devops/`

## 📊 Monitoring & Health Checks

```bash
#!/bin/bash

RESOURCE_GROUP="rg-myapp-prod"

echo "🏥 Health Check Report"
echo "======================================"
echo ""

# AKS Node Status
echo "AKS Nodes:"
kubectl get nodes -o wide

# Pod Status
echo ""
echo "Pod Status (all namespaces):"
kubectl get pods -A --no-headers | tail -5

# Storage Usage
echo ""
echo "Storage Account Usage:"
az storage account show-usage \
  --resource-group $RESOURCE_GROUP

# SQL Server Status
echo ""
echo "SQL Server DTU Usage:"
az sql db list \
  --resource-group $RESOURCE_GROUP \
  --query '[].{Name:name, Dtu:currentServiceObjectiveName}' \
  --output table

# Key Vault Access Logs
echo ""
echo "Key Vault Recent Access:"
az monitor metrics list-definitions \
  --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.KeyVault/vaults/*"
```

---

**Reviewed**: 2026-06-24 | **Version**: 1.0 | **Owner**: Platform Engineering
