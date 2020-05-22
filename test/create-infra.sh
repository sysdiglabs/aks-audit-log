#!/bin/bash

set -euf

echo "Create infra"
echo "Resource group: $my_resource_group"
echo "Cluster name: $my_cluster_name"
echo
echo "Press ENTER to continue"
read 


echo "Creating resource group"
az group create --location eastus --name $my_resource_group -o none
echo "Waiting so service principal creation can success"
sleep 15

echo "Creating AKS cluster"
az aks create --name "$my_cluster_name" -g "$my_resource_group" --node-count 3

echo "Waiting to finalize creation"
state=$(az aks show --resource-group $my_resource_group --name $my_cluster_name  --query provisioningState -o tsv )
while [[ "$state" != "Succeeded" ]]; do
    echo -n "."
    state=$(az aks show --resource-group $my_resource_group --name $my_cluster_name  --query provisioningState -o tsv )
    echo $state
    sleep 10
done
echo
echo $state
