#!/bin/bash

set -euf

function check_commands_installed {
    echo "[1/12] Checking requirements"
    local exists
    exists=$(which az ||:)
    if [ "$exists" == "" ]; then
        echo "Required command line tool 'az' not available."
        echo "For instructions on how to install it, visit:"
        ecbo "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest"
        exit 1
    fi
    exists=$(which kubectl ||:)
    if [ "$exists" == "" ]; then
        echo "Required command line tool 'kubectl' not available."
        echo "Yoy may install it using:"
        echo "  az aks install-cli"
        exit 1
    fi
    exists=$(which envsubst ||:)
    if [ "$exists" == "" ]; then
        echo "Required command line tool 'envsubts' not available."
        echo "You may find it in the gettext or gettext-base packages."
        exit 1
    fi
    exists=$(which curl ||:)
    if [ "$exists" == "" ]; then
        echo "Required command line tool 'curl' not available."
        exit 1
    fi
    exists=$(which tr ||:)
    if [ "$exists" == "" ]; then
        echo "Required command line tool 'tr' not available."
        exit 1
    fi
    exists=$(which grep ||:)
    if [ "$exists" == "" ]; then
        echo "Required command line tool 'grep' not available."
        exit 1
    fi
    exists=$(which md5sum ||:)
    if [ "$exists" == "" ]; then
        echo "Required command line tool 'md5sum' not available."
        exit 1
    fi
}

function check_cluster {

    echo -n "."
    az aks get-credentials \
        --name "$cluster_name" \
        --resource-group "$resource_group" --file - \
        > "$WORKDIR/tempkubeconfig"

    echo -n "."
    exists=$(KUBECONFIG=$WORKDIR/tempkubeconfig kubectl get namespaces -o name | grep -w "namespace/$sysdig_namespace" || true)
    if [ "$exists" == "" ]; then
        echo "Couldn't find $sysdig_namespace namespace in the cluster."
        exit 1
    fi;

    echo -n "."
    exists=$(KUBECONFIG=$WORKDIR/tempkubeconfig kubectl get deployments -o name | grep -w "deployment.extensions/aks-audit-log-forwarder"  || true)
    if [ "$exists" != "" ]; then
        echo "Audit log forwarder deployment already present in the cluster."
        exit 1
    fi;

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

    echo -n "."
    exists=$(az aks show --name "$cluster_name" --resource-group "$resource_group" --query name --output tsv)
    if [ "$exists" != "$cluster_name" ]; then
        echo
        echo "Can't install, AKS cluster was not found: $cluster_name"
        exit 1
    fi

    echo -n "."

    exists=$(az monitor diagnostic-settings show \
        --name "$diagnostic_name" \
        --resource "$cluster_name" \
        --resource-group "$resource_group" \
        --resource-type "Microsoft.ContainerService/ManagedClusters" \
        --output none 2>/dev/null || true)
    if [ "$exists" != "" ]; then
      echo
      echo "Can't install, AKS cluster's diagnostic settting already exists: $diagnostic_name"
      exit 1
    fi

    echo -n "."
    exists=$(az storage account check-name --name "$storage_account" --output json --query 'nameAvailable')
    if [ "$exists" == "false" ]; then
        echo
        echo "Can't install, resource name not valid: Storage Account '$storage_account'"
        exit 1
    fi

    echo -n "."
    exists=$(az storage account show --name "$storage_account" --query name -o tsv 2>/dev/null || true)
    if [ "$exists" != "" ]; then
        echo
        echo "Can't install, resource already exists: Storage Account '$storage_account'"
        exit 1
    fi


    echo -n "."
    exists=$(az eventhubs namespace exists --name "$ehubs_name" --output json --query 'nameAvailable')
    if [ "$exists" == "false" ]; then
        echo
        echo "Can't install, resource already exists: Event Hubs '$ehubs_name'"
        exit 1
    fi
    echo
}

function get_region {
    region=$(az aks show -n "$cluster_name" -g "$resource_group" --output tsv --query location)
    echo "AKS region: $region"
}


function create_event_hubs {
    ## Create Event Hubs namespace

    echo "[2/12] Creating Event Hubs namespace: $ehubs_name"
    az eventhubs namespace create \
        --name "$ehubs_name" \
        --resource-group "$resource_group" \
        --location "$region" --output none

    # Message retention 1 day
    echo "[3/12] Creating Event Hub: $hub_name"
    az eventhubs eventhub create --name "$hub_name" \
        --namespace-name "$ehubs_name" \
        --resource-group "$resource_group" \
        --message-retention 1 \
        --partition-count 4 \
        --output none

    echo "[4/12] Getting hub connection string"
    sleep 5
    hub_connection_string=$(az eventhubs namespace authorization-rule keys list \
        --resource-group "$resource_group" \
        --namespace-name "$ehubs_name" \
        --name RootManageSharedAccessKey \
        --output tsv --query primaryConnectionString)

    echo "[5/12] Getting hub id"
    hub_id=$(az eventhubs namespace show --resource-group "$resource_group" --name "$ehubs_name" --output tsv --query id)
}

function create_diagnostic {
    echo "[6/12] Creating diagnostic setting: $diagnostic_name"
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

function create_storage_account {
    ## Create storage account

    echo "[7/12] Creating storage account: $storage_account"

    az storage account create \
        --name "$storage_account" \
        --resource-group "$resource_group" \
        --location "$region" \
        --sku Standard_RAGRS \
        --kind StorageV2 --output none

    echo "[8/12] Getting storage connection string"
    blob_connection_string=$(az storage account show-connection-string --key primary \
        --name "$storage_account" \
        --resource-group "$resource_group" \
        --output tsv --query connectionString)

    echo "[9/12] Creating blob container: $blob_container"
    az storage container create \
        --name "$blob_container" \
        --connection-string "$blob_connection_string" \
        --output none
}


function create_deployment {
    echo "[10/12] Creating deployment manifest"

    export EhubNamespaceConnectionString="$hub_connection_string"
    export BlobStorageConnectionString="$blob_connection_string"
    export VerboseLevel="3"
    export ImagePullPolicy="IfNotPresent"
    export ImageVersion="0.1.3"

    curl https://raw.githubusercontent.com/sysdiglabs/aks-kubernetes-audit-log/master/deployment.yaml.in |
      envsubst > "$WORKDIR/deployment.yaml"

    

    echo "[11/12] Applying Kubernetes service"

    KUBECONFIG="$WORKDIR/tempkubeconfig" kubectl apply \
        -f https://raw.githubusercontent.com/sysdiglabs/aks-kubernetes-audit-log/master/service.yaml \
        -n "$sysdig_namespace"

    echo "[12/12] Applying Kubernetes deployment"
    
    export KUBECONFIG="$WORKDIR/tempkubeconfig"
    KUBECONFIG="$WORKDIR/tempkubeconfig" kubectl apply -f "$WORKDIR/deployment.yaml" -n "$sysdig_namespace"

    rm "$WORKDIR/tempkubeconfig"
    rm "$WORKDIR/deployment.yaml"
}

# ==========================================================================================================

function is_valid_value {
	if [[ ${1} == -* ]] || [[ ${1} == --* ]] || [[ -z ${1} ]]; then
		return 1
	else
		return 0
	fi
}

function help {

	echo "Usage: $(basename "${0}") [-g|--resource_group <value>] [-c|--cluster_name <value>] [-n|--sysdig_namespace] \ "
	echo "                [-y|--yes] [-h | --help]"
	echo ""
	echo " -g  : Azure resource group where the AKS cluster is located (required)"
	echo " -c  : AKS cluster name (required)"
	echo " -n  : Kubernetes namespace where Sysdig agent is deployed (default sysdig-agent)"
    echo " -y  : Do not prompt for confirmation before execution"
	echo " -h  : print this usage and exit"
	echo
	exit 1
}

# ==========================================================================================================

# MAIN EXECUTION

# Default initial values
prompt_yes=1
resource_group=""
cluster_name=""
sysdig_namespace="sysdig-agent"

# Get and validate all arguments
while [[ ${#} -gt 0 ]]
do
	key="${1}"

	case ${key} in
		-g|--resource_group)
			if is_valid_value "${2}"; then
				resource_group="${2}"
			else
				echo "ERROR: no value provided for resource_group option, use -h | --help for $(basename "${0}") Usage"
				exit 1
			fi
			shift
			;;
		-c|--cluster_name)
			if is_valid_value "${2}"; then
				cluster_name="${2}"
			else
				echo "ERROR: no value provided for is_valid_value option, use -h | --help for $(basename "${0}") Usage"
				exit 1
			fi
			shift
			;;
		-n|--sysdig_namespace)
			if is_valid_value "${2}"; then
				sysdig_namespace="${2}"
			else
				echo "ERROR: no value provided for sysdig_namespace endpoint option, use -h | --help for $(basename "${0}") Usage"
				exit 1
			fi
			shift
			;;
		-y|--yes)
			prompt_yes=0
			;;
		-h|--help)
			help
			exit 1
			;;
		*)
			echo "ERROR: Invalid option: ${1}, use -h | --help for $(basename "${0}") Usage"
			exit 1
			;;
	esac
	shift
done


if [ -z "$resource_group" ] || [ -z "$cluster_name" ]; then
    echo "Error: one or more required parameters missing."
    echo
    help
fi

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

## Work dir
WORKDIR=$(mktemp -d /tmp/sysdig-aks-audit-log.XXXXXX)

echo "AKS audit log integration with Sysdig agent"
echo
echo "This script will create and set up resources to forward AKS audit log to Sysdig Secure"
echo
echo "Destination:"
echo "  * Resource group: $resource_group"
echo "  * AKS cluster: $cluster_name"
echo "  * Sysdig agent namespace: $sysdig_namespace"
echo "Resources to install:"
echo "  * Activate diagnostic setting $diagnostic_name in the cluster"
echo "  * Storage account: $storage_account"
echo "    * Blob container: $blob_container"
echo "  * Event Hubs namespace: $ehubs_name"
echo "    * Hub namespace: $ehubs_name"
echo "  * In the Kubernetes cluster's namespace: $sysdig_namespace"
echo "    * Kubernetes service: sysdig-agent"
echo "    * Kubernetes deployment: aks-audit-log-forwarder"
echo "Using temp directory: $WORKDIR"
echo

if [ "$prompt_yes" != "0" ]; then
    read -n 1 -s -r -p "Press ENTER to continue"
    echo
fi


check_commands_installed
check_cluster
check_az_resources

get_region

create_event_hubs
create_diagnostic
create_storage_account
create_deployment

echo "Installation complete."
