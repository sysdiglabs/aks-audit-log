# Azure Kubernetes Service audit log integration to Sysdig Secure

This repository contains an installation/uninstallation script, instructions and source code to integrate Azure Kubernetes Service audit log to Sysdig Secure.

[![Actions Status](https://github.com/sysdiglabs/aks-audit-log/workflows/CI/badge.svg)](https://github.com/sysdiglabs/aks-audit-log/actions)

## Installation

The installation script has some command line tool requirements:
  * [Azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) (already logged into your account)
  * envsubst (shipped with gettext package)
  * kubectl
  * curl, tr, grep

```bash
curl -s https://raw.githubusercontent.com/sysdiglabs/aks-audit-log/master/install-aks-audit-log.sh | bash -s -- YOUR_RESOURCE_GROUP_NAME YOUR_AKS_CLUSTER_NAME
```

Some resources will be created in the same resource group as your cluster:
 * Storage Account, to coordinate event consumers
 * Event Hubs, to receive audit log events
 * Diagnostic setting in the cluster, to send audit log to Event Hubs
 * Kubernetes deployment aks-audit-log-forwarder, to forward the log to Sysdig agent

## Uninstallation

```bash
curl -s https://raw.githubusercontent.com/sysdiglabs/aks-audit-log/master/uninstall-aks-audit-log.sh | bash -s -- YOUR_RESOURCE_GROUP_NAME YOUR_AKS_CLUSTER_NAME
```
