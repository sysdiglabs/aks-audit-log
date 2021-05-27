#!/bin/bash

# set -uf

my_resource_group="${RESOURCE_GROUP:-aks-test-group}"
my_cluster_name="${CLUSTER_NAME:-aks-test-cluster}"

echo "Create infra"
echo "Resource group: $my_resource_group"
echo "Cluster name: $my_cluster_name"
echo
echo "Press ENTER to continue"
read 

echo "Creating resource group"
az group create --location eastus --name "$my_resource_group" 
#-o none
echo


echo "Creating AKS cluster, due to a Azure bug, will retry at most 6 times"
# https://github.com/Azure/AKS/issues/1206

result=1
i=6
while [ $result -eq 1 ] && [ $i -gt 0 ]; do 
    az aks create --name "$my_cluster_name" -g "$my_resource_group" --node-count 3
    result=$?
    #az aks show --resource-group "$my_resource_group" --name "$my_cluster_name" --query provisioningState -o tsv
    #result=$?
    i=$((i-1))
    sleep 2
    echo -n "."
done

echo
az aks show --resource-group "$my_resource_group" --name "$my_cluster_name"  --query provisioningState -o tsv
echo


