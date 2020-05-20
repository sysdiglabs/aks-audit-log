#!/bin/bash

echo "Resource group: $my_resource_group"
echo "Cluster name: $my_cluster_name"


../install-aks-audit-log.sh $my_resource_group $my_cluster_name

