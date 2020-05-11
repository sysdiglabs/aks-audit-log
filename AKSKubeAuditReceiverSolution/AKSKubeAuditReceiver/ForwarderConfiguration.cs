using System;
using System.Collections.Generic;
using System.Text;

namespace AKSKubeAuditReceiver
{
    public class ForwarderConfiguration
    {
        public string EhubNamespaceConnectionString;
        public string EventHubName;
        public string BlobStorageConnectionString;
        public string BlobContainerName;
        public string WebSinkURL;

        public bool ConsoleOutputKubeAuditEvents = false;
        public bool ConsoleOutputPostResponse = true;
        public bool PostEventsToWebhook = true;

        public void InitConfig()
        {
            EhubNamespaceConnectionString = Environment.GetEnvironmentVariable("EhubNamespaceConnectionString");
            EventHubName = Environment.GetEnvironmentVariable("EventHubName");
            BlobStorageConnectionString = Environment.GetEnvironmentVariable("BlobStorageConnectionString");
            BlobContainerName = Environment.GetEnvironmentVariable("BlobContainerName");
            WebSinkURL = Environment.GetEnvironmentVariable("WebSinkURL");

        }
    }
}