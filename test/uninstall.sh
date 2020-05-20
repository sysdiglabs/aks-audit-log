#!/bin/bash

echo "Resource group: $my_resource_group"
echo "Cluster name: $my_cluster_name"

../uninstall-aks-audit-log.sh $my_resource_group $my_cluster_name --yes


