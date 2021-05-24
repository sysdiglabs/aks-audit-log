#!/bin/bash

set -euf

my_resource_group="${RESOURCE_GROUP:-aks-test-group}"
my_cluster_name="${CLUSTER_NAME:-aks-test-cluster}"
my_namespace="${SYSDIG_NAMESPACE:-sysdig-agent}"

echo "Resource group: $my_resource_group"
echo "Cluster name: $my_cluster_name"

../install-aks-audit-log.sh -g "$my_resource_group" -c "$my_cluster_name" -n "$my_namespace"  --yes

