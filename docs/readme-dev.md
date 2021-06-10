# Azure Kubernetes Service audit log integration to Sysdig Secure

## Introduction

This is the developmend documentation for the _AKS audit log_ integration. To read the _user documentation_, check the [main README.md] of this repo.

## Motivation

Sysdig Secure can do detections based on runtime security policies for Kubernetes commands. To be able to do so, it has to receive the Kubernetes audit log.

In vanilla Kubernetes installations, you can tell the Kubernetes API server to send it to the Sysdig agent. For managed clusters, each cloud provider requires different steps to be able for the Sysdig agent to receive the log.


## Architecture

![AKS audit log architecture diagram](aks_audit_log_architecture.png)

## Implementation

The [AKSKubeAuditReceiverSolution](../AKSKubeAuditReceiverSolution) has been implemented using .NET core 3.1 because its Event Hubs client library doesn't require to previously create a service principal to interact with a hub, so it is easier to deploy. It is packaged in a container image that you deploy in the AKS cluster.

We evaluated to use a go Event Hubs client library, but it required to create a specific Service Account for it, which is something that can be problematic in environments where the user doesn't have owner access to the whole Azure account.

You also need additional resources specified in the architecture diagram to be able to access and process the Kubernetes audit log for an AKS cluster.

A standard AKS cluster with 3 nodes and no workload will need less than 1 Mb/s of bandwidth to provide the audit log. In the case that the forwarder stops working, events will be stored in the hub until cosumed when it continues execution, as seen in the following figure.

![Kube audit events bandwidth](events-bandwidth.png)

## Dependencies

Tested with AKS created with Kubernetes version 1.15.10

## Log verbose levels

The service includes a `VerboseLevel` parameter in its deployment configuration that sets what is sent to its log:

 * Level 1: Only errors are shown
 * Level 2: A log entry is shown for every Event hub event (they pack several Kubernetes audit log inside it)
 * Level 3: Same as previous, and each Kubernetes audit log event unpacked also are shown in a log entry.
 * Level 4: Same as previous, and each POST to the service for each Kubernetes audit log event has a log entry, as well as each response to the POST. In addition, at service start some initial parameters are shown: EventHubName, BlobContainerName, WebSinkURL, VerboseLevel, EhubNamespaceConnectionString length, BlobStorageConnectionString length.

You can follow the output log with:
```
kubectl logs -l app=aks-audit-log-forwarder -f --namespace sysdig-agent
```

You can edit the ConfigMap and restart the service’s pod to change the verbose level:
```
kubectl edit deployment aks-audit-log-forwarder
```

When events and other information have an entry in the log, they do not show the full event content, but a summary log line to make it easier to debug any situation. If you are interested in capturing the full Kubernetes audit log events, see below information to activate "Send to Log Analytics" on the cluster _diagnostic settings_.

Setting a higher verbose level has a small negative impact on the service performance, that is more important in big clusters with more events. We do not show full event contents in the log to mitigate it.


## Manual deployment

1. Create several Azure resources:
   * Resource Group
   * Create an Events Hub in the Resource Group
   * Create a Log Analytics Workspace (take note of the zone used)  
    We will use it to test queries for the logs, but _it's not required_. 

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
   * Send to Log Analytics (optional): Yes
       * Subscription: \<your subscription>
       * Log Analytics workspace: \<your Log Analytics workspace>
   * Stream to an event hub: Yes
       * Subscription: \<your subscription>
       * Event hub namespace: \<your Event Hubs>
       * Event hub name: (leave blank)
       * Event hub policy name: RootManagedSharedAccessKey (default value)
   * Archite to a storage account: No

If you activate "Send to Log Analytics", you will send all Kubernetes audit log events to a Log Analytics workspace in adition to the forwarder for Sysdig.

4. Set up `kubectl` access to the cluster

```bash
az login
az aks get-credentials --resource-group $group --name $cluster_name
```

5. If your cluster is empty, deploy an Nginx pod to test the logs

```bash
kubectl apply -f nginx.yaml
```

6. Visit Log Analytics workspace  
   Click on the **Logs** section, and run some test queries (you may have to wait a while until results show).
   Your results should look like the ones from [samples/aks_audit.csv](./aks_audit.csv).

```
AzureDiagnostics
| where Category == "kube-audit"
| project log_s
```

7. Install Sysdig agent

   * Install the agent using the bash script provided when you create a new Sysdig account at [./install-agent-kubernetes] using:

   
```bash
# Replace <YOUR_SYSDIG_ACCESS_KEY> and <CLUSTER_NAME>
curl -s https://download.sysdig.com/stable/install-agent-kubernetes | bash -s -- --access_key <YOUR_SYSDIG_ACCESS_KEY> --collector collector.sysdigcloud.com --collector_port 6443 --cluster_name <CLUSTER_NAME> --imageanalyzer
```

  * Deploy service definition for Sysdig's agent webhook

```bash
kubectl apply -f service.yaml -n sysdig-agent
```


8. Deploy the AKS Audit Log consumer-forwarder

  * Changing image version, pull policy and connection strings, execute:

```bash
# Replace YOUR_EVENT_HUB_CONNECTION_STRING and YOUR_BLOB_STORAGE_CONNECTION_STRING
EhubNamespaceConnectionString="YOUR_EVENT_HUB_CONNECTION_STRING" \
  BlobStorageConnectionString="YOUR_BLOB_STORAGE_CONNECTION_STRING" \
  VerboseLevel="3" \
  ImagePullPolicy="Always" \
  ImageVersion="latest" \
  envsubst < deployment.yaml.in > deployment.yaml

  kubectl apply -f deployment.yaml -n sysdig-agent
```

  * Wait until it's deployed, and you can check it's logs at:
  
```
kubectl get pods -n sysdig-agent
kubectl logs <AKS_KUBE_AUDIT_POD_NAME> -n sysdig-agent
```

## References

### Azure documendation:

* [Enable and review Kubernetes master node logs in Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/view-master-logs)

* [Stream Azure platform logs to Azure Event Hubs](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/resource-logs-stream-event-hubs)

* [Azure Event Hubs as an Event Grid source](https://docs.microsoft.com/en-us/azure/event-grid/event-schema-event-hubs)

* [Azure Event Hubs receive events](https://docs.microsoft.com/en-us/azure/event-hubs/get-started-dotnet-standard-send-v2#receive-events)

* [Azure Event Hubs receive events (old version, more detailed)](https://docs.microsoft.com/en-us/azure/event-hubs/event-hubs-dotnet-standard-getstarted-send#receive-events)

* [Azure Events Hubs go library client](https://github.com/Azure/azure-event-hubs-go)

### Sysdig documentations and repositories:

* [Sysdig documentation for Kubernetes audit log integrations](https://docs.sysdig.com/en/kubernetes-audit-logging.html)

* [Sysdig agent Helm chart](https://github.com/helm/charts/blob/master/stable/sysdig/README.md)

* [GitHub repo: EKS Kubernetes audit log integration](https://github.com/sysdiglabs/ekscloudwatch)

* [GitHub repo: GKE Kubernetes audit log integration](https://github.com/sysdiglabs/stackdriver-webhook-bridge)

### Other related documentation:

* [GitHub repo folder: Falco samples for Kubernetes audit log events](https://github.com/falcosecurity/falco/tree/master/test/trace_files/k8s_audit)

* [Get kubelet logs from Azure Kubernetes Service (AKS) cluster nodes](https://docs.microsoft.com/en-us/azure/aks/kubelet-logs)

* [Connect with SSH to Azure Kubernetes Service (AKS) cluster nodes for maintenance or troubleshooting](https://docs.microsoft.com/en-us/azure/aks/ssh)


