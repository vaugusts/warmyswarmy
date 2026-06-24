# Infrastructure-as-Code (IaC) for Production Azure Deployment

Production-ready, enterprise-grade Infrastructure-as-Code templates using **Bicep** (primary) and **Terraform** (equivalent). This IaC suite provisions a complete Azure cloud platform with networking, Kubernetes, databases, monitoring, and security controls.

## 📋 What's Included

### Infrastructure Components
- **Virtual Network (VNet)**: Multi-subnet architecture with network security groups
- **Azure Kubernetes Service (AKS)**: Production-grade Kubernetes with auto-scaling and RBAC
- **Azure SQL Database**: Managed SQL with encryption, backups, threat detection
- **Key Vault**: Secure secrets and certificate management
- **Storage Account**: Geo-redundant blob storage with lifecycle policies
- **Container Registry (ACR)**: Private Docker image registry with scanning
- **Log Analytics Workspace**: Centralized observability and monitoring
- **Application Insights**: Application Performance Monitoring (APM)

### Security & Compliance
- ✅ Network Security Groups with least-privilege rules
- ✅ RBAC role assignments (AcrPull, KeyVault access)
- ✅ Azure Policy enforcement (via AKS)
- ✅ Encryption at rest and in transit
- ✅ Diagnostic logging to Log Analytics
- ✅ Managed identities for service principals
- ✅ Soft delete and purge protection (Key Vault)
- ✅ SQL threat detection and vulnerability scanning

### Environment Support
- **Dev**: Minimal resources for cost-effective development
- **Prod**: High-availability with geo-redundancy and enhanced monitoring

## 🏗️ Directory Structure

```
infra/
├── bicep/
│   ├── main.bicep                    # Root orchestration template
│   ├── modules/
│   │   ├── vnet.bicep
│   │   ├── aks.bicep
│   │   ├── keyvault.bicep
│   │   ├── storage.bicep
│   │   ├── sql-database.bicep
│   │   ├── log-analytics.bicep
│   │   ├── app-insights.bicep
│   │   └── container-registry.bicep
│   └── parameters/
│       ├── dev.bicepparam            # Dev environment parameters
│       └── prod.bicepparam           # Prod environment parameters
│
├── terraform/
│   ├── main.tf                       # Root module and outputs
│   ├── backend.tf                    # Remote state configuration
│   ├── modules.tf                    # Module calls
│   ├── modules/
│   │   ├── resource-group/
│   │   ├── log-analytics/
│   │   ├── app-insights/
│   │   ├── vnet/
│   │   ├── keyvault/
│   │   ├── storage/
│   │   ├── container-registry/
│   │   ├── sql-database/
│   │   └── aks/
│   └── environments/
│       ├── dev/
│       │   └── dev.tfvars
│       └── prod/
│           └── prod.tfvars
│
├── pipelines/
│   ├── github-actions/
│   │   ├── bicep-deploy.yml          # Bicep CI/CD workflow
│   │   └── terraform-deploy.yml      # Terraform CI/CD workflow
│   └── azure-devops/
│       └── infrastructure-pipeline.yml # Azure DevOps pipeline
│
├── runbooks/
│   ├── DEPLOYMENT.md                 # Step-by-step deployment guide
│   └── MAINTENANCE.md                # Operational procedures
│
└── docs/
    ├── README.md                     # This file
    └── SECURITY.md                   # Security hardening guide
```

## 🚀 Quick Start

### Prerequisites
- Azure subscription with appropriate permissions
- Azure CLI or PowerShell
- For Terraform: Terraform >= 1.5.0
- For Bicep: Azure CLI with bicep CLI extension
- GitHub Actions or Azure DevOps for CI/CD

### Deploy with Bicep

```bash
# Set variables
export ENVIRONMENT=dev
export LOCATION=eastus
export PROJECT_NAME=myapp
export KEY_VAULT_ADMIN_ID="<your-azure-ad-object-id>"

# Login to Azure
az login --use-device-code

# Select subscription
az account set --subscription <subscription-id>

# Create resource group
az group create \
  --name rg-${PROJECT_NAME}-${ENVIRONMENT} \
  --location ${LOCATION}

# Deploy Bicep template
az deployment group create \
  --resource-group rg-${PROJECT_NAME}-${ENVIRONMENT} \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/parameters/${ENVIRONMENT}.bicepparam \
  --parameters keyVaultAdminObjectId=${KEY_VAULT_ADMIN_ID}
```

### Deploy with Terraform

```bash
# Set variables
export ENVIRONMENT=dev
export LOCATION=eastus

# Initialize Terraform (configure backend first)
cd infra/terraform
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=stterraformstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=${ENVIRONMENT}.tfstate"

# Plan deployment
terraform plan \
  -var-file="environments/${ENVIRONMENT}/${ENVIRONMENT}.tfvars" \
  -out=tfplan

# Apply configuration
terraform apply tfplan
```

## 🔐 Security Configuration

### Key Vault Setup
1. **Admin Object ID**: Update `keyVaultAdminObjectId` parameter with your Azure AD object ID
   ```bash
   az ad user show --id <your-email@company.com> --query id
   ```

2. **Secrets Management**: All sensitive values use `@secure()` parameters or `sensitive = true`
   - SQL admin password (update in deployment)
   - Database connection strings
   - API keys (added post-deployment)

3. **Access Control**: Implement RBAC for service principals
   ```bash
   # Example: Grant AKS managed identity Key Vault access
   az role assignment create \
     --role "Key Vault Secrets User" \
     --assignee-object-id <aks-managed-identity-object-id> \
     --scope /subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault-name>
   ```

### Network Security
- **NSGs**: Subnets isolated with security rules
  - AKS subnet: Allows HTTPS/HTTP from any source, internal VNet traffic
  - App subnet: Only allows traffic from AKS subnet on port 443
  
- **Private Endpoints** (optional): Configure for SQL, Storage, Key Vault
- **Network Policies**: Azure Network Policy enabled on AKS

### Monitoring & Alerts
- **Log Analytics**: All resources send logs (retention: 30 days dev / 90 days prod)
- **App Insights**: Failure rate alerts configured (>5% threshold)
- **Diagnostic Settings**: Enabled for AKS, SQL, Key Vault, Storage, ACR

## 📊 Parameter Customization

### Dev vs Prod Differences

| Component | Dev | Prod |
|-----------|-----|------|
| VM SKU | D2s_v3 | D4s_v3 |
| Node Count | 1 | 3 |
| SQL SKU | GP_Gen5_2 | GP_Gen5_4 |
| Storage Replication | LRS | GRS |
| Log Retention | 30 days | 90 days |
| Key Vault Purge Protection | Disabled | Enabled |
| ACR SKU | Standard | Premium |

## 🔄 CI/CD Integration

### GitHub Actions
1. **Bicep Workflow** (`bicep-deploy.yml`):
   - Validates templates on PR
   - Runs `what-if` analysis
   - Deploys on merge to main

2. **Terraform Workflow** (`terraform-deploy.yml`):
   - Validates configuration
   - Generates plan on PR
   - Applies on merge (with sequential environment approval)

### Azure DevOps
1. Configure these variables in Azure DevOps:
   - `AzureResourceConnection`: Service connection name
   - `AzureSubscriptionId`: Target subscription
   - `TfBackendRg`, `TfBackendSa`, `TfBackendContainer`: Backend config

2. Pipeline stages:
   - **Validate**: Syntax and security checks
   - **Plan**: Generate deployment plans
   - **Deploy**: Dev → Prod (sequential)

## 🛠️ Maintenance & Operations

### Updating Configuration
1. Modify parameters in `dev.bicepparam` or `environments/dev/dev.tfvars`
2. Test in pull request (triggers plan/what-if)
3. Merge to main (auto-deploys)

### Scaling AKS
```bicep
// Update aksNodeCount parameter
param aksNodeCount int = 5
```

### Adding Secrets to Key Vault
```bicep
// Add to keyvault.bicep module
resource mySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'my-secret-name'
  parent: keyVault
  properties: {
    value: 'PLACEHOLDER-CHANGE-ME'
  }
}
```

## 📚 Additional Documentation

- **[DEPLOYMENT.md](./DEPLOYMENT.md)**: Step-by-step deployment procedures
- **[MAINTENANCE.md](./MAINTENANCE.md)**: Operational runbooks
- **[SECURITY.md](./docs/SECURITY.md)**: Security hardening details and compliance

## 🐛 Troubleshooting

### Common Issues

1. **"Insufficient permissions"**
   - Ensure service principal has Owner or Contributor role on subscription

2. **"Quota exceeded"**
   - Check Azure quota for VM, storage, or IP addresses
   - See `infra/docs/QUOTAS.md` for quota requirements

3. **Bicep validation fails**
   - Update Azure CLI: `az upgrade`
   - Verify template syntax: `az bicep build --file main.bicep`

4. **Terraform backend not found**
   - Create storage account and container for backend (see DEPLOYMENT.md)
   - Verify storage account name and key in backend.tf

## 📝 Contributing

1. Create feature branch: `git checkout -b feature/add-new-module`
2. Validate templates:
   ```bash
   az bicep build --file infra/bicep/main.bicep
   terraform validate
   ```
3. Test in dev environment via PR
4. Merge after approval

## ⚠️ Important Notes

- **Sensitive Data**: Never commit secrets; use Key Vault or GitHub Secrets
- **State File**: Terraform state contains sensitive info; store in secured backend only
- **Cost**: Prod environment uses premium SKUs; review Azure pricing before deployment
- **Idempotency**: All templates are idempotent and safe to reapply
- **Tags**: All resources tagged with environment, project, and deployment metadata

## 📖 References

- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/architecture/framework/)
- [Azure Security Best Practices](https://learn.microsoft.com/en-us/azure/security/)

## 📄 License

[Specify your license here]

---

**Last Updated**: 2026-06-24 | **Maintainers**: Platform Engineering Team
