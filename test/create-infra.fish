# fish script

set -Ux my_resource_group AKSAuditLogTest-Group
set -Ux my_cluster_name AKSAuditLogTest-Cluster

echo "Resource group: $my_resource_group"
echo "Cluster name: $my_cluster_name"

az group create --location eastus --name $my_resource_group
az group show --name $my_resource_group --query properties.provisioningState -o tsv 
az aks create --name $my_cluster_name -g $my_resource_group --node-count 3
