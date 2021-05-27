#!/bin/bash

my_resource_group="${RESOURCE_GROUP:-aks-test-group}"
my_cluster_name="${CLUSTER_NAME:-aks-test-cluster}"

echo "Resource group: $my_resource_group"
echo "Cluster name: $my_cluster_name"

resource_group="$my_resource_group"
cluster_name="$my_cluster_name"

# Calculated values

## Hash from cluster name for resources
hash=$(echo -n "${cluster_name}${resource_group}" | md5sum)
hash="${hash:0:4}"

## Default resource names
storage_account=$(echo "${cluster_name}" | tr '[:upper:]' '[:lower:]')
storage_account=$(echo "$storage_account" | tr -cd 'a-zA-Z0-9')
storage_account="${storage_account:0:20}${hash}"
ehubs_name="${cluster_name:0:46}${hash}"

## Default unchanged values
blob_container='kubeauditlogcontainer'
hub_name='insights-logs-kube-audit'
diagnostic_name='auditlogdiagnostic'

## Output parameters needed
blob_connection_string=''
hub_connection_string=''
hub_id=''

echo "storage_account: $storage_account"
echo "ehubs_name: $ehubs_name"
echo

export WebSinkURL=""
export EhubNamespaceConnectionString=""
export BlobStorageConnectionString=""

# echo "Getting DNS prefix"

# set my_dns_prefix (az aks show \
#     --resource-group $my_resource_group \
#     --name $my_cluster_name \
#     --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName \
#     -o tsv)

# set -Ux my_dns_prefix $my_dns_prefix
# echo "Prefix: $my_dns_prefix"
# # cat ingress.yaml.in | envsubst > ingress.yaml
# # set -Ux WebSinkURL "http://sysdig-agent-ingress.$my_dns_prefix:7756/k8s_audit"
# echo

echo "Getting storage connection string"

blob_connection_string=$(az storage account show-connection-string --key primary \
    --name "$storage_account" \
    --resource-group "$resource_group" \
    --output tsv --query connectionString)

export BlobStorageConnectionString="$blob_connection_string"
echo BlobStorageConnectionString 
echo "$blob_connection_string"
echo

echo "Getting Event Hubs connection string"

hub_connection_string=$(az eventhubs namespace authorization-rule keys list \
    --resource-group "$resource_group" \
    --namespace-name "$ehubs_name" \
    --name RootManageSharedAccessKey \
    --output tsv --query primaryConnectionString)

export EhubNamespaceConnectionString="$hub_connection_string"
echo EhubNamespaceConnectionString 
echo "$hub_connection_string"
echo


echo "Generating custom deployment"

export VerboseLevel="4"
export ImagePullPolicy="Always"
export ImageVersion="dev"

# curl https://raw.githubusercontent.com/sysdiglabs/aks-kubernetes-audit-log/master/deployment.yaml.in | envsubst > my-deployment.yaml
cat ../deployment.yaml.in | envsubst > my-deployment.yaml
echo "my-deployment.yaml generated"
echo "finished"
echo