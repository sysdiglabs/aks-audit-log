#!/bin/bash

echo "Getting Kubectl credentials"
az aks get-credentials --name $my_cluster_name --resource-group $my_resource_group

echo "Installing Sysdig agent"
curl -s https://download.sysdig.com/stable/install-agent-kubernetes | \
  bash -s -- --access_key $SYSDIG_AGENT_ACCESS_KEY \
    --collector collector.sysdigcloud.com --collector_port 6443 \
    --cluster_name $my_cluster_name --imageanalyzer

