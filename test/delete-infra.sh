#!/bin/bash

set -x

echo "Resource group: $my_resource_group"
echo "Cluster name: $my_cluster_name"

az aks delete --name $my_cluster_name -g $my_resource_group --yes

az group delete --name $my_cluster_name --yes

