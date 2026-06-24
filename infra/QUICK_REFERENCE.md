# Quick Reference Guide

## 🚀 Deploy in 5 Minutes (Bicep)

```bash
export ENV=dev
az login
az group create -n rg-myapp-$ENV -l eastus
az deployment group create \
  --resource-group rg-myapp-$ENV \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/parameters/$ENV.bicepparam
```

## 🚀 Deploy in 5 Minutes (Terraform)

```bash
cd infra/terraform
terraform init -backend=false
terraform plan -var-file=environments/dev/dev.tfvars
terraform apply
```

## 📋 Essential Commands

### Bicep
```bash
az bicep build --file infra/bicep/main.bicep
az deployment group validate --resource-group <rg> --template-file infra/bicep/main.bicep
az deployment group what-if --resource-group <rg> --template-file infra/bicep/main.bicep
az deployment group create --resource-group <rg> --template-file infra/bicep/main.bicep
az deployment group show --resource-group <rg> --query properties.outputs
```

### Terraform
```bash
terraform init -backend-config=...
terraform plan -var-file=environments/dev/dev.tfvars
terraform apply tfplan
terraform output -json > outputs.json
terraform state list/show/refresh
```

### AKS
```bash
az aks get-credentials --resource-group <rg> --name <aks>
kubectl get nodes/pods/svc
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

### Key Vault
```bash
az keyvault secret list --vault-name <kv>
az keyvault secret show --vault-name <kv> --name <secret>
az keyvault secret set --vault-name <kv> --name <secret> --value <value>
```

### SQL
```bash
az sql db list --resource-group <rg> --server <server>
az sql db show --resource-group <rg> --server <server> --name <db>
sqlcmd -S <server>.database.windows.net -U <user> -P <password>
```

### Storage
```bash
az storage account list --resource-group <rg>
az storage container list --account-name <sa>
az storage blob list --account-name <sa> --container-name <container>
```

## 🔍 Troubleshooting Quick Checks

```bash
# 1. Check resource group exists
az group list --query "[?name=='rg-myapp-prod']"

# 2. Check all resources
az resource list --resource-group rg-myapp-prod

# 3. Check deployment status
az deployment group list --resource-group rg-myapp-prod

# 4. Check failed deployments
az deployment group list --resource-group rg-myapp-prod --query "[?properties.provisioningState=='Failed']"

# 5. Get detailed error
az deployment group show --resource-group rg-myapp-prod --name main --query properties.error

# 6. Check AKS nodes
kubectl get nodes -o wide

# 7. Check pod status
kubectl get pods -A --field-selector=status.phase!=Running

# 8. Check logs
kubectl logs -n kube-system -l component=kubelet --tail=50
```

## 📊 Monitor Key Metrics

```bash
# AKS resource usage
kubectl top nodes
kubectl top pods -A

# Storage usage
az storage account show-usage --resource-group <rg>

# SQL DTU usage
az sql db list --resource-group <rg> --server <server> --query '[].{Name:name, Dtu:currentServiceObjectiveName}'

# Key Vault operations
az monitor metrics list --resource /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<kv> --metric ServiceApiHit
```

## 🔐 Security Checks

```bash
# Review RBAC assignments
az role assignment list --resource-group <rg>

# Check Key Vault access policies
az keyvault show --name <kv> --resource-group <rg> --query properties.accessPolicies

# Review NSG rules
az network nsg rule list --resource-group <rg> --nsg-name <nsg>

# Check storage encryption
az storage account show --resource-group <rg> --name <sa> --query encryption

# Check SQL threat detection
az sql server threat-detection-policy show --resource-group <rg> --server <server>
```

## 🗑️ Cleanup

```bash
# Delete entire environment
az group delete --name rg-myapp-dev

# Delete specific resource
az resource delete --ids <resource-id>

# Terraform destroy
terraform destroy -var-file=environments/dev/dev.tfvars
```

## 📞 Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| "Insufficient permissions" | Check service principal has Contributor role |
| "Quota exceeded" | Request quota increase in Azure Portal |
| "Template invalid" | Run `az bicep build` to validate |
| "Deployment timeout" | Increase wait time or check resource limits |
| "AKS NotReady" | `kubectl describe node <name>`, check logs |
| "Pod pending" | `kubectl describe pod <pod>`, check resources/quotas |
| "Connection refused" | Check NSG rules, firewall, and subnet routing |
| "Access denied to Key Vault" | Check RBAC roles and access policies |

---

**For detailed procedures, see:**
- 📖 [docs/README.md](../docs/README.md) - Overview & architecture
- 🔐 [docs/SECURITY.md](../docs/SECURITY.md) - Security hardening
- 📋 [runbooks/DEPLOYMENT.md](../runbooks/DEPLOYMENT.md) - Step-by-step deployment
- 🛠️ [runbooks/MAINTENANCE.md](../runbooks/MAINTENANCE.md) - Operational procedures
