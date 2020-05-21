#!/bin/bash

echo "Resource group: $my_resource_group"
echo "Cluster name: $my_cluster_name"


../install-aks-audit-log.sh -g $my_resource_group -c $my_cluster_name

