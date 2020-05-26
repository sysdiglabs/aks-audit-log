using System;
using System.Collections.Generic;
using System.Text;

namespace AKSKubeAuditReceiver
{
    public class ForwarderConfiguration
    {
        public string EhubNamespaceConnectionString="";
        public string EventHubName="";
        public string BlobStorageConnectionString="";
        public string BlobContainerName="";
        public string WebSinkURL="";

        public int VerboseLevel = 4;

        public int PostMaxRetries = 10;
        public int PostRetryIncrementalDelay = 1000;

        public void InitConfig()
        {
            EhubNamespaceConnectionString = Environment.GetEnvironmentVariable("EhubNamespaceConnectionString");
            BlobStorageConnectionString = Environment.GetEnvironmentVariable("BlobStorageConnectionString");
            WebSinkURL = Environment.GetEnvironmentVariable("WebSinkURL");

            BlobContainerName = Environment.GetEnvironmentVariable("BlobContainerName");
            if (String.IsNullOrEmpty(BlobContainerName)) BlobContainerName = "kubeauditlogcontainer";

            EventHubName = Environment.GetEnvironmentVariable("EventHubName");
            if (String.IsNullOrEmpty(EventHubName)) EventHubName = "insights-logs-kube-audit";

            WebSinkURL = Environment.GetEnvironmentVariable("WebSinkURL");
            if (String.IsNullOrEmpty(WebSinkURL)) WebSinkURL = "http://sysdig-agent.sysdig-agent.svc.cluster.local:7765/k8s_audit";

            if (Environment.GetEnvironmentVariable("VerboseLevel") != "")
            {
                try
                {
                    VerboseLevel = Int32.Parse(Environment.GetEnvironmentVariable("VerboseLevel"));
                }
                catch (Exception) { }
            }

            if (VerboseLevel > 3)
            {
                Console.WriteLine("EventHubName: {0}", EventHubName);
                Console.WriteLine("BlobContainerName: {0}", BlobContainerName);
                Console.WriteLine("WebSinkURL: {0}", WebSinkURL);
                Console.WriteLine("VerboseLevel: {0}", VerboseLevel);

                Console.WriteLine("EhubNamespaceConnectionString length: {0}",
                    EhubNamespaceConnectionString == null ? 0 : EhubNamespaceConnectionString.Length);
                Console.WriteLine("BlobStorageConnectionString length: {0}",
                    BlobStorageConnectionString == null ? 0 : BlobStorageConnectionString.Length);
            }
        }

        public bool IsValid()
        {
            return (
                !String.IsNullOrEmpty(EhubNamespaceConnectionString)  &&
                !String.IsNullOrEmpty(BlobStorageConnectionString) &&
                !String.IsNullOrEmpty(WebSinkURL) &&
                !String.IsNullOrEmpty(EventHubName) &&
                !String.IsNullOrEmpty(BlobContainerName)
            );
        }

    }
}