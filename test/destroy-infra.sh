#!/bin/bash

# set -x

echo "Destroy infra"
echo "Resource group: $my_resource_group"
#echo "Cluster name: $my_cluster_name"
echo "This operation will take a lot of time"
echo
read -n 1 -s -r -p "Press ENTER to continue"
echo
echo

echo "Destroying resource group $my_resource_group and all its resources"

#az aks delete --name "$my_cluster_name" -g "$my_resource_group" --yes

az group delete --name "$my_resource_group" --yes

# az group show --name "$my_resource_group" --query properties.provisioningState -o tsv 2>/dev/null

# state="Deleting"
# while [[ "$state" == "Deleting" ]]; do
#     state=$(az group show --name "$my_resource_group" --query properties.provisioningState -o tsv 2>/dev/null || true)
#     echo "$state"
#     echo -n "."
# done
# echo $state

say "Infrastructure destroyed"



