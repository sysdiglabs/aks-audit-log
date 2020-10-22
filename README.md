# Azure Kubernetes Service audit log integration to Sysdig Secure

This repository contains an installation/uninstallation script, instructions and source code to integrate Azure Kubernetes Service audit log to [Sysdig Secure](https://sysdig.com).

[![Actions Status](https://github.com/sysdiglabs/aks-audit-log/workflows/build/badge.svg)](https://github.com/sysdiglabs/aks-audit-log/actions)

## Installation

You can execute the automatic installation steps using a docker image that has all requirements, or directly using Bash if you already have the requirements in your system.

You need to know the AKS Cluster Name and the Resource Group Name that you used to create your [Azure AKS Cluster](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough).

### A. Using Docker image installer

To execute the installer using a Docker image and sharing your Azure credentials with it, execute:

```bash
docker run -it -v $HOME/.azure:/root/.azure sysdiglabs/aks-audit-log-installer:1 \
  -g YOUR_RESOURCE_GROUP_NAME -c YOUR_AKS_CLUSTER_NAME
```

To see more optional parameters, use:

```bash
docker run sysdiglabs/aks-audit-log-installer:1 --help
```

### B. Using the Bash script

The installation script has some command line tool requirements:
  * [Azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) (already logged into your account)
  * envsubst (shipped with gettext package)
  * kubectl
  * curl, tr, grep


```bash
curl -s https://raw.githubusercontent.com/sysdiglabs/aks-audit-log/master/install-aks-audit-log.sh | \
  bash -s -- -g YOUR_RESOURCE_GROUP_NAME -c YOUR_AKS_CLUSTER_NAME
```

To see more optional parameters, use:

```bash
curl -s https://raw.githubusercontent.com/sysdiglabs/aks-audit-log/master/install-aks-audit-log.sh | \
  bash -s -- --help
```

The installation script creates some resources and configurations in the same resource group as your cluster:
 * Storage Account, to coordinate event consumers
 * Event Hubs, to receive audit log events
 * Diagnostic setting in the cluster, to send audit log to Event Hubs
 * Kubernetes deployment aks-audit-log-forwarder, to forward the log to Sysdig agent

If everything worked as expected, you can verify that the audit logs are being forwarded executing:

```bash
kubectl get pods -n sysdig-agent
# take note of the pod name for aks-audit-log-forwarder
kubectl log aks-audit-log-forwarder-XXXX -f
```

## Uninstallation

Use the same parameters as for installation. The script will delete all created resources and configurations.

Using Docker image:

```bash
docker run -it -v $HOME/.azure:/root/.azure \
  --entrypoint /app/uninstall-aks-audit-log.sh \
  sysdiglabs/aks-audit-log-installer:1 \
  -g YOUR_RESOURCE_GROUP_NAME -c YOUR_AKS_CLUSTER_NAME
```

Using uninstall Bash script:

```bash
curl -s https://raw.githubusercontent.com/sysdiglabs/aks-audit-log/master/uninstall-aks-audit-log.sh | \
  bash -s -- -g YOUR_RESOURCE_GROUP_NAME -c YOUR_AKS_CLUSTER_NAME
```

## More information

Check the [developer documentation](./docs/readme-dev.md) for architecture and manual installation details.
