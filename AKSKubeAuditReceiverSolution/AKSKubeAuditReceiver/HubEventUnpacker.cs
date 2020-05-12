using System;
using System.Text;
using Newtonsoft.Json.Linq;
using Azure.Messaging.EventHubs.Processor;


namespace AKSKubeAuditReceiver
{
    class HubEventUnpacker
    {
        private ForwarderConfiguration ForwarderConfiguration;
        private WebhookPoster WebhookPoster;
        public HubEventUnpacker(ForwarderConfiguration forwarderConfiguration)
        {
            ForwarderConfiguration = forwarderConfiguration;
            WebhookPoster = new WebhookPoster(forwarderConfiguration);
        }

        public void Process(ProcessEventArgs eventArgs, string mainEventName = "") {

            JObject eventJObj = JObject.Parse(Encoding.UTF8.GetString(eventArgs.Data.Body.ToArray()));

            int i = 0;
            foreach (JObject record in eventJObj["records"])
            {
                try
                {
                    string kubeAuditEventStr = record["properties"]["log"].ToString();
                    if (ForwarderConfiguration.ConsoleOutputKubeAuditEvents)
                        ConsoleWriteEventSummary(kubeAuditEventStr, mainEventName, i);
                    WebhookPoster.SendPost(kubeAuditEventStr, mainEventName, i);
                    i++;
                }
                catch (Exception)
                {
                    Console.WriteLine("Error unpacking events in record");
                }

            }
        }

        private void ConsoleWriteEventSummary(string kubeAuditEventStr, string mainEventName="", int eventNumber=0)
        {
            JObject kubeAuditEvent = JObject.Parse(kubeAuditEventStr);
            Console.WriteLine("{0} {1} > {2} {3} {4} {5}",
                mainEventName, eventNumber,
                (string)kubeAuditEvent.SelectToken("user.username"),
                (string)kubeAuditEvent.SelectToken("verb"),
                (string)kubeAuditEvent.SelectToken("objectRef.resource"),
                (string)kubeAuditEvent.SelectToken("objectRef.name"));
        }
    }
}
