using System;
using System.Text;
using System.Collections.Generic;
using Newtonsoft.Json.Linq;
using Azure.Messaging.EventHubs.Processor;
using System.Threading.Tasks;

namespace AKSKubeAuditReceiver
{
    public class HubEventUnpacker
    {
        private readonly ForwarderConfiguration ForwarderConfiguration;
        public IWebhookPoster WebhookPoster=null;
        public HubEventUnpacker(ForwarderConfiguration forwarderConfiguration)
        {
            ForwarderConfiguration = forwarderConfiguration;
        }

        public void InitConfig()
        {
            if ( WebhookPoster == null )
            {
                WebhookPoster = new WebhookPoster(ForwarderConfiguration);
                WebhookPoster.InitConfig();
            }
        }

        public async Task<bool> Process(ProcessEventArgs eventArgs, string mainEventName = "")
        {
            // Creating a ProcessEventArgs test object is not possible, so we use this decoration
            // https://stackoverflow.com/questions/38105679/eventhub-partitioncontext-class-design
            JObject eventJObj = JObject.Parse(Encoding.UTF8.GetString(eventArgs.Data.Body.ToArray()));
            return await Process(eventJObj, mainEventName);
        }

        public async Task<bool> Process(JObject eventJObj, string mainEventName = "")
        {

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
                catch (Exception e)
                {
                    Console.WriteLine("**Error unpacking events in record: {0}",e.Message);
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

        private void ConsoleWriteEventSummary(string kubeAuditEventStr, string mainEventName = "", int eventNumber = 0)
        {
            try
            {
                JObject kubeAuditEvent = JObject.Parse(kubeAuditEventStr);
                Console.WriteLine("{0} {1} > READ kube event: {2} {3} {4} {5}",
                    mainEventName, eventNumber,
                    (string)kubeAuditEvent.SelectToken("user.username"),
                    (string)kubeAuditEvent.SelectToken("verb"),
                    (string)kubeAuditEvent.SelectToken("objectRef.resource"),
                    (string)kubeAuditEvent.SelectToken("objectRef.name"));
            } catch(Exception e)
            {
                Console.WriteLine("{0} {1} > **Error parsing kube event, will send anyways: {2}",
                    mainEventName, eventNumber, e.Message);
            }
        }
    }
}
