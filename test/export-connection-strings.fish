#/usr/local/bin/fish

echo "Resource group: $my_resource_group"
echo "Cluster name: $my_cluster_name"

set -x resource_group $my_resource_group
set -x cluster_name $my_cluster_name

set -x hash (echo -n "$cluster_name$resource_group" | md5sum)
set -x hash (string sub --length 4 "$hash")
set -x storage_account (echo "$cluster_name" | tr '[:upper:]' '[:lower:]')
set -x storage_account (echo $storage_account | tr -cd '[a-zA-Z0-9]')
set -x storage_account (string sub --length 20 "$storage_account")
set -x storage_account "$storage_account""$hash"
set -x ehubs_name (string sub --length 46 "$cluster_name")
set -x ehubs_name "$ehubs_name""$hash"

echo "storage_account: $storage_account"
echo "ehubs_name: $ehubs_name"
echo

set -Ux WebSinkURL ""
set -Ux EhubNamespaceConnectionString ""
set -Ux BlobStorageConnectionString ""

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

set -x blob_connection_string (az storage account show-connection-string --key primary \
    --name "$storage_account" \
    --resource-group "$resource_group" \
    --output tsv --query connectionString)

set -Ux BlobStorageConnectionString "$blob_connection_string"
echo BlobStorageConnectionString 
echo "$blob_connection_string"
echo

echo "Getting Event Hubs connection string"

set -x hub_connection_string (az eventhubs namespace authorization-rule keys list \
    --resource-group "$resource_group" \
    --namespace-name "$ehubs_name" \
    --name RootManageSharedAccessKey \
    --output tsv --query primaryConnectionString)

set -Ux EhubNamespaceConnectionString "$hub_connection_string"
echo EhubNamespaceConnectionString 
echo "$hub_connection_string"
echo

echo "Generating custom deployment"

# curl https://raw.githubusercontent.com/sysdiglabs/aks-kubernetes-audit-log/master/deployment.yaml.in | envsubst > my-deployment.yaml
cat ../deployment.yaml.in | envsubst > my-deployment.yaml
echo "my-deployment.yaml generated"
echo "finished"
echo