#!/bin/bash

set -euf

function check_commands_installed {
    echo "[1/14] Checking requirements"

    exists=$(which az)
    if [ "$exists" == "" ]; then
        echo "Required command line tool 'az' not available."
        exit 1
    fi
    exists=$(which kubectl)
    if [ "$exists" == "" ]; then
        echo "Required command line tool 'kubectl' not available."
        exit 1
    fi
    exists=$(which envsubst)
    if [ "$exists" == "" ]; then
        echo "Required command line tool 'envsubts' not available."
        exit 1
    fi
    exists=$(which curl)
    if [ "$exists" == "" ]; then
        echo "Required command line tool 'curl' not available."
        exit 1
    fi
}

function check_cluster {
    # Sysdig agent installed
    # Deployment not already in cluster
    #kubectl get deployment aks-audit-log-forwarder -n sysdig-aget
    echo -n "."
}

function check_az_resources {

    # Confirm we can get the Azure account id
    echo -n "."
    azure_account_id=$(az account list --output tsv --query [0].id)
    if [ "$azure_account_id" == "" ]; then
    echo
    echo "Can't get Azure account id. Try executing 'az login'"
    exit 1
    fi

    echo -n "."
    exists=$(az group exists --name "$resource_group")
    if [ "$exists" == "false" ]; then
    echo
    echo "Can't install, resource group doesn't exists: $resource_group"
    exit 1
    fi


    # TODO: avoid usage of grep
    echo -n "."
    exist=$(az aks list --resource-group "$resource_group" --output json --query '[].name' | grep "$cluster_name")
    if [ "$exists" == "" ]; then
    echo
    echo "Can't install, AKS cluster doesn't exists: $cluster_name"
    exit 1
    fi

    echo -n "."

    # exist=$(az monitor diagnostic-settings list --resource "$resource_group" \
    #   --resource-group $resource_group --resource-type "Microsoft.ContainerService/ManagedClusters" --output tsv --query name \
    #   | grep $diagnostic_name)
    # if [ "$exists" != "" ]; then
    #   echo
    #   echo "Can't install, AKS cluster's diagnostic settting already exists: $exist"
    #   exit 1
    # fi

    echo -n "."
    exist=$(az storage account check-name --name $storage_account --output json --query 'nameAvailable')
    if [ "$exist" == "false" ]; then
    echo
    echo "Can't install, resource already exist: Storage Account '$storage_account'"
    exit 1
    fi

    echo -n "."
    exist=$(az eventhubs namespace exists --name $ehubs_name --output json --query 'nameAvailable')
    if [ "$exist" == "false" ]; then
    echo
    echo "Can't install, resource already exist: Event Hubs '$ehubs_name'"
    exit 1
    fi
    echo
}

function get_region {
    region=$(az aks show -n $cluster_name -g $resource_group --output tsv --query location)
    echo "AKS region: $region"
}

function create_storage_account {
    ## Create storage account

    echo "[9/14] Creating storage account $storage_account"

    az storage account create \
        --name "$storage_account" \
        --resource-group "$resource_group" \
        --location "$region" \
        --sku Standard_RAGRS \
        --kind StorageV2 --output none

    echo "[10/14] Getting storage connection string"
    blob_connection_string=$(az storage account show-connection-string --key primary \
        --name "$storage_account" \
        --resource-group "$resource_group" \
        --output tsv --query connectionString)

    echo "[11/14] Creating blob container $blob_container"
    az storage container create --name "$blob_container" --connection-string $blob_connection_string --output none
}

function create_event_hubs {
    ## Create Event Hubs namespace

    echo "[5/14] Creating Event Hubs namespace $ehubs_name"
    az eventhubs namespace create \
        --name "$ehubs_name" \
        --resource-group "$resource_group" \
        --location "$region" --output none

    echo "[6/14] Creating Event Hub $hub_name"
    az eventhubs eventhub create --name "$hub_name"
        --namespace-name "$ehubs_name" \
        --resource-group "$resource_group" \
        --message-retention 1 \
        --partition-count 4

    echo "[7/14] Getting hub connection string"
    sleep 5
    hub_connection_string=$(az eventhubs namespace authorization-rule keys list \
        --resource-group "$resource_group" \
        --namespace-name "$ehubs_name" \
        --name RootManageSharedAccessKey \
        --output tsv --query primaryConnectionString)

    echo "[8/14] Getting hub id"
    hub_id=$(az eventhubs namespace show --resource-group "$resource_group" --name "$ehubs_name" --output tsv --query id)
}

function create_diagnostic {
    echo "[8/14] Creating diagnostic setting"
    ## Setting up aks diagnostics to send kube-audit to event hub
    az monitor diagnostic-settings create \
    --resource "$cluster_name" \
    --resource-group "$resource_group" \
    --resource-type "Microsoft.ContainerService/ManagedClusters" \
    --name "$diagnostic_name" \
    --logs    '[{"category": "kube-audit","enabled": true}]' \
    --event-hub "$hub_name" \
    --event-hub-rule "${hub_id}/authorizationrules/RootManageSharedAccessKey" \
    --output none
}

function create_deployment {
    echo "[12/14] Creating deployment"

    EhubNamespaceConnectionString="$hub_connection_string"
    BlobStorageConnectionString="$blob_connection_string"

    curl https://raw.githubusercontent.com/sysdiglabs/aks-kubernetes-audit-log/master/deployment.yaml.in |
      envsubst > deployment.yaml

    echo "[13/14] Applying service and deployment"
    kubectl apply -f https://raw.githubusercontent.com/sysdiglabs/aks-kubernetes-audit-log/master/service.yaml

    echo "[14/14] Applying service and deployment"
    kubectl apply -f deployment.yaml
}

# ==========================================================================================================

# MAIN EXECUTION

# Default resource names (might autogenerate hashed names)
storage_account='kubeauditlogstorage'
ehubs_name='AKSAuditLogEventHubs'

# Default unchanged values
blob_container='kubeauditlogcontainer'
hub_name='insights-logs-kube-audit'
diagnostic_name='auditlogdiagnostic'

# Output parameters needed
blob_connection_string=''
hub_connection_string=''
hub_id=''

# These are populated from command line parameters

if [ "$#" -lt 2 ]; then
    echo "Error: one or more required parameters missing."
    echo "Usage: "
    echo "  ./install-aks-audit-log-forwarder.sh YOUR_RESOURCE_GROUP YOUR_AKS_CLUSTER_NAME"
    echo 
    exit 1
fi
resource_group="$1"
cluster_name="$2"

echo "Installing AKS audit log"
echo "Resource group: $resource_group"
echo "AKS cluster: $cluster_name"

check_commands_installed
check_cluster
check_az_resources

get_region


create_event_hubs
create_diagnostic
create_storage_account
create_deployment
