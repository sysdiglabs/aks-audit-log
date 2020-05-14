# Azure Kubernetes Service audit log integration to Sysdig Secure

This repository contains an installation/uninstallation script, instructions and source code to integrate Azure Kubernetes Service audit log to Sysdig Secure.

## Installation

The installation script has some command line tool requirements:
  * Azure-cli (already logged into your account)
  * envsubst
  * kubectl

```bash
./install-aks-audit-log-forwarder.sh YOUR_RESOURCE_GROUP_NAME YOUR_AKS_GROUP_NAME
```

Some resources will be created in the same resource group as your cluster:
 * Storage Account, to coordinate event consumers
 * Event Hubs, to receive audit log events
 * Diagnostic setting in the cluster, to send audit log to Event Hubs
 * Kubernetes deployment aks-audit-log-forwarder, to forward the log to Sysdig agent

## Uninstallation

```bash
./uninstall-aks-audit-log-forwarder.sh YOUR_RESOURCE_GROUP_NAME YOUR_AKS_GROUP_NAME
```

## Limitations

The automatic installation can automatically install resources for one AKS cluster in one namespace.