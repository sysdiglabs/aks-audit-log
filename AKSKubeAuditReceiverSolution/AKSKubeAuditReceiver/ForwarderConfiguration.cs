using System;
using System.Collections.Generic;
using System.Text;

namespace AKSKubeAuditReceiver
{
    class ForwarderConfiguration
    {
        public string EhubNamespaceConnectionString;
        public string EventHubName;
        public string BlobStorageConnectionString;
        public string BlobContainerName;
        public string WebSinkURL;

        public void InitConfig()
        {
            EhubNamespaceConnectionString = Environment.GetEnvironmentVariable("EhubNamespaceConnectionString");
            EventHubName = Environment.GetEnvironmentVariable("EventHubName");
            BlobStorageConnectionString = Environment.GetEnvironmentVariable("BlobStorageConnectionString");
            BlobContainerName = Environment.GetEnvironmentVariable("BlobContainerName");
            WebSinkURL = Environment.GetEnvironmentVariable("WebSinkURL");

            EhubNamespaceConnectionString = "Endpoint=sb://kubeauditlogeventhub2.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=u/y6I8F4Y6hyBWhGam6c/3/+l000eEuILcWevcLrss4=";
            EventHubName = "insights-logs-kube-audit";
            BlobStorageConnectionString = "DefaultEndpointsProtocol=https;AccountName=storagekubeauditlog;AccountKey=9h4BHg+RHXq6K/x4GfZrufGWrJR03jHOjeGMeyQH2oBFIJ5TlmaK5DZ2RkYEW6WNhiD1OzaxfssEO8W0//IV5A==;EndpointSuffix=core.windows.net";
            BlobContainerName = "kubeauditlogcontainer";
            WebSinkURL = "http://sysdig-agent.sysdig-agent.svc.cluster.local:7765/k8s_audit";

        }
    }
}