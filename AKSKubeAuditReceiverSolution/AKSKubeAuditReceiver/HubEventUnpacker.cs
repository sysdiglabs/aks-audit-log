using System;
using System.Text;
using System.Collections.Generic;
using Newtonsoft.Json.Linq;
using Azure.Messaging.EventHubs.Processor;
using System.Threading.Tasks;

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

        public async Task<bool> Process(ProcessEventArgs eventArgs, string mainEventName = "") {

            JObject eventJObj = JObject.Parse(Encoding.UTF8.GetString(eventArgs.Data.Body.ToArray()));

            JToken records = eventJObj["records"];
            var results = new List<Task>();

            int i = 0;
            bool ok = true;
            foreach (JObject record in records)
            {
                try
                {
                    string kubeAuditEventStr = record["properties"]["log"].ToString();
                    if (ForwarderConfiguration.VerboseLevel > 2)
                        ConsoleWriteEventSummary(kubeAuditEventStr, mainEventName, i);
                    results.Add(WebhookPoster.SendPost(kubeAuditEventStr, mainEventName, i));
                    i++;
                }
                catch (Exception)
                {
                    Console.WriteLine("Error unpacking events in record");
                    ok = false;
                }
            }

            if (!ok) return false;
            foreach (Task<bool> result in results)
            {
                ok = ok && (await result);
            }

            return ok;
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
