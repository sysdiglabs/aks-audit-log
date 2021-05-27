#!/bin/bash

set -euf

my_resource_group="${RESOURCE_GROUP:-aks-test-group}"
my_cluster_name="${CLUSTER_NAME:-aks-test-cluster}"

echo "Getting Kubectl credentials"
az aks get-credentials --name "$my_cluster_name" --resource-group "$my_resource_group" --overwrite-existing

echo "Installing Sysdig agent"
curl -s https://download.sysdig.com/stable/install-agent-kubernetes | \
  bash -s -- --access_key $SYSDIG_AGENT_ACCESS_KEY \
    --collector collector.sysdigcloud.com --collector_port 6443 \
    --cluster_name "$my_cluster_name" --imageanalyzer \
    -ns $my_sysdig_namespace

