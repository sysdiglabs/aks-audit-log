# Instructions and code to connect Azure Kubernetes Service audit logs to Sysdig agent

## Introduction

This repo show steps to enable the log for Kubernetes commands that Azure exposes for AKS clusters.

**THIS IS A WORK IN PROGRESS**

## Motivation

We want the Sysdig agent to be able to ingets this log as it does for other managed Kubernetes installations to be able to trigger security policies based on Kubernetes runtime activity.

## Summary

There is a sample of the logs obtained in this way in the [aks_audit.csv](./aks_audit.csv) file.

## Dependencies

Tested with AKS created with Kubernetes version 1.15.10

## Steps

1. Create several Azure resources:
  * Resource Group
  * Create an Events Hub in the Resource Group
  * Create a Log Analytics Workspace (take note of the zone used)  
    We will use it to test queries for the logs, but it's not required. 

2. Create AKS cluster, using a new Log Analytics Workspace in the same Resource Group and using the same zone as the Log Analytics Workspace.  
Take into consideration that if you create the Log Analytics in the same step that the AKS cluster, it will not be created in your Resource group, even if it says it will be.

3. Visit "Diagnostics settings" in cluster, activate:
   * log:
       * kube-apiserver: No
       * kube-audit: Yes
       * kube-controller-manager: No
       * kube-scheduler: No
       * cluster-autoscaler: No
   * metric:
       * AllMetrics: No
   * Send to Log Analytics: Yes
       * Subscription: \<your subscription>
       * Log Analytics workspace: \<your Log Analytics workspace>
   * Stream to an event hub
       * Subscription: \<your subscription>
       * Event hub namespace: \<your Event Hubs>
       * Event hub name: (leave blank)
       * Event hub policy name: RootManagedSharedAccessKey (default value)
   * Archite to a storage account: No
   * Stream to an event hub: Yes
       * Subscription: \<your subscription>
       * Event hub namespace: \<your Event Hubs>
       * Event hub name (optional): (leave blank)
       * Event hub policy name: RootManageSharedAccessKey (default)

4. Set up `kubectl` access to the cluster

```bash
az login
az az aks get-credentials --resource-group $group --name $cluster_name
```

5. If your cluster is empty, deploy an Nginx pod to test the logs

```bash
kubectl apply -f nginx.yaml
```

6. Visit Log Analytics workspace  
   Click on the **Logs** section, and run some test queries (you may have to wait a while until results show).
   Your results should look like the ones from [aks_audit.csv](./aks_audit.csv).

```
AzureDiagnostics
| where Category == "kube-audit"
| project log_s
```

7. Install Sysdig agent

   * Log into your Sysdig dashboard, click on your profile, and Agent Installation on Settings section.
   * Copy your Sysdig _access key_ to use for installation.
   * Install the agent using the [Helm chart](https://github.com/helm/charts/blob/master/stable/sysdig/README.md):

```
SYSDIG_AGENT_ACCESS_KEY=<your Sysdig access key>
helm install sysdig-agent --set sysdig.accessKey=$SYSDIG_AGENT_ACCESS_KEY stable/sysdig \
  --set auditLog.enabled=true
```

8. Set up Forwarding in Event Hubs  
   * Open your Event Hubs in the Resource Group, open your Event Hubs, 
   * Click on events, and choose "Web Hook"
   * Fill the details of the Web Hook
     * Name: SysdigAuditLog (choose an unique name)
     * Event Schema: Event Grid Schema
     * Filter to Event Types: Capture File Created
     * Endpoint type: Web Hook (WIP)
       * Endpoint: `http://\<endpoint_ip>` (WIP)


## References

### Main Azure documendation:

* [Enable and review Kubernetes master node logs in Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/view-master-logs)

* [Stream Azure platform logs to Azure Event Hubs](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/resource-logs-stream-event-hubs)

* [Azure Event Hubs as an Event Grid source](https://docs.microsoft.com/en-us/azure/event-grid/event-schema-event-hubs)


### Sysdig documentations and repositories:

* [Sysdig documentation for Kubernetes audit log integrations](https://docs.sysdig.com/en/kubernetes-audit-logging.html)

* [Sysdig agent Helm chart](https://github.com/helm/charts/blob/master/stable/sysdig/README.md)

* [GitHub repo: EKS Kubernetes audit log integration](https://github.com/sysdiglabs/ekscloudwatch)

* [GitHub repo: GKE Kubernetes audit log integration](https://github.com/sysdiglabs/stackdriver-webhook-bridge)

### Related documentation:

* [GitHub repo folder: Falco samples for Kubernetes audit log events](https://github.com/falcosecurity/falco/tree/master/test/trace_files/k8s_audit)

* [Get kubelet logs from Azure Kubernetes Service (AKS) cluster nodes](https://docs.microsoft.com/en-us/azure/aks/kubelet-logs)

* [Connect with SSH to Azure Kubernetes Service (AKS) cluster nodes for maintenance or troubleshooting](https://docs.microsoft.com/en-us/azure/aks/ssh)




