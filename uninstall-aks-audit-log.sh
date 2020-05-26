#!/bin/bash

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
# blob_container='kubeauditlogcontainer'
# hub_name='insights-logs-kube-audit'
diagnostic_name='auditlogdiagnostic'


# -----------------------------------------------------------------------------

echo "AKS audit log integration with Sysdig agent"
echo
echo "Uninstall AKS audit log integration resources"
echo "Resource group: $resource_group"
echo "AKS cluster: $cluster_name"
echo "Sysdig agent namespace: $sysdig_namespace"
echo

echo "This script will delete resources for AKS audit log integration:"
echo "  * Diagnostic setting $diagnostic_name in the cluster"
echo "  * Storage account $storage_account and all its containers"
echo "  * Event Hubs namespace $ehubs_name and all its hubs"
echo "  * Kubernetes deployment: aks-audit-log-forwarder"
echo "  * Kubernetes service: sysdig-agent"
echo

if [[ "$prompt_yes" == "1" ]]; then
    read -n 1 -s -r -p "Press ENTER to continue"
	echo
fi

echo "[1/5] Deleting diagnostic settings: $diagnostic_name"
az monitor diagnostic-settings delete \
 --resource "$cluster_name" \
 --resource-group "$resource_group" \
 --resource-type "Microsoft.ContainerService/ManagedClusters" \
 --name "$diagnostic_name" --output none


echo "[2/5] Deleting deployment: aks-audit-log-forwarder"
echo kubectl delete deployment aks-audit-log-forwarder -n "$sysdig_namespace"
kubectl delete deployment aks-audit-log-forwarder -n "$sysdig_namespace"


echo "[3/5] Deleting storage account: $storage_account"
az storage account delete --name "$storage_account" --yes --output none

echo "[4/5] Deleting service: sysdig-agent"
echo kubectl delete service sysdig-agent -n "$sysdig_namespace"
kubectl delete service sysdig-agent -n "$sysdig_namespace"

echo "[5/5] Deleting event hubs namespace: $ehubs_name"
az eventhubs namespace delete --resource-group "$resource_group" --name "$ehubs_name" --output none

az aks get-credentials \
    --name "$cluster_name" \
    --resource-group "$resource_group" --file - \
    > tempkubeconfig

echo
echo "Delete commands sent, it may take some minutes to complete."
echo