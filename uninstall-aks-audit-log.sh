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

# Resources that will be created
storage_account='kubeauditlogstorage'
ehubs_name='AKSAuditLogEventHubs'

# Default unchanged values
blob_container='kubeauditlogcontainer'
hub_name='insights-logs-kube-audit'
diagnostic_name='auditlogdiagnostic'


echo "Uninstall AKS audit log resources"
echo "Resource group: $resource_group"
echo "AKS cluster: $cluster_name"


echo "Deleting deployment"
kubectl delete deployment aks-audit-log-forwarder -n sysdig-agent

echo "Deleting service"
kubectl delete service sysdig-agent -n sysdig-agent

echo "Deleting event hubs namespace"
az eventhubs namespace delete --resource-group $resource_group --name $ehubs_name --output none

echo "Deleting storage account"
az storage account delete --name $storage_account --yes --output none

echo "Deleting diagnostic settings"
az monitor diagnostic-settings delete \
 --resource "$cluster_name" \
 --resource-group "$resource_group" \
 --resource-type "Microsoft.ContainerService/ManagedClusters" \
 --name "$diagnostic_name" --output none

echo
echo "Delete commands sent, it may take some minutes to complete."
echo