#!/bin/bash

# Required user input
if [ "$1" == "" ] || [ "$2" == "" ]; then
    echo "Error: one or more required parameters missing."
    echo "Usage: "
    echo "  ./install-aks-audit-log-forwarder.sh YOUR_RESOURCE_GROUP YOUR_AKS_CLUSTER_NAME"
    echo 
    exit 1
fi
resource_group="$1"
cluster_name="$2"

# Hash from cluster name for resources
hash=$(echo -n "${cluster_name}${resource_group}" | md5sum)
hash="${hash:0:4}"

# Default resource names
storage_account=$(echo "${cluster_name}" | tr '[:upper:]' '[:lower:]')
storage_account=$(echo $storage_account | tr -cd '[a-zA-Z0-9]')
storage_account="${storage_account:0:20}${hash}"
ehubs_name="${cluster_name:0:46}${hash}"

# Default unchanged values
blob_container='kubeauditlogcontainer'
hub_name='insights-logs-kube-audit'
diagnostic_name='auditlogdiagnostic'

echo "Uninstall AKS audit log resources"
echo "Resource group: $resource_group"
echo "AKS cluster: $cluster_name"
echo

echo "This script will delete resources for AKS audit log:"
echo "  * Diagnostic setting $diagnostic_name in the cluster"
echo "  * Storage account $storage_account and all its containers"
echo "  * Event Hubs namespace $ehubs_name and all its hubs"
echo "  * Kubernetes deployment aks-audit-log-forwarder"
echo "  * Kubernetes service sysdig-agent"
echo

if [[ "$3" != "--yes" ]]; then
    echo "Press ENTER to continue"
    response=$(read)
fi

echo "Deleting diagnostic settings: $diagnostic_name"
az monitor diagnostic-settings delete \
 --resource "$cluster_name" \
 --resource-group "$resource_group" \
 --resource-type "Microsoft.ContainerService/ManagedClusters" \
 --name "$diagnostic_name" --output none

echo "Deleting storage account: $storage_account"
az storage account delete --name $storage_account --yes --output none

echo "Deleting event hubs namespace: $ehubs_name"
az eventhubs namespace delete --resource-group $resource_group --name $ehubs_name --output none

az aks get-credentials \
    --name "$cluster_name" \
    --resource-group "$resource_group" --file - \
    > tempkubeconfig

echo "Deleting deployment: aks-audit-log-forwarder"
kubectl delete deployment aks-audit-log-forwarder -n sysdig-agent

echo "Deleting service: sysdig-agent"
kubectl delete service sysdig-agent -n sysdig-agent

echo
echo "Delete commands sent, it may take some minutes to complete."
echo