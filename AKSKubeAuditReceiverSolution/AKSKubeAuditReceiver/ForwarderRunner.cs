using System;
using System.Text;
using System.Threading.Tasks;
using Azure.Storage.Blobs;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Azure.Messaging.EventHubs.Processor;
using Newtonsoft.Json.Linq;
using System.Net.Http;
using System.Collections.Generic;

namespace AKSKubeAuditReceiver
{
    public class ForwarderRunner
    {
        private static readonly HttpClient client = new HttpClient();

        private static ForwarderConfiguration ForwarderConfiguration;

        public ForwarderRunner()
        {
            Console.WriteLine("Set up runner");
            ForwarderConfiguration = new ForwarderConfiguration();
            ForwarderConfiguration.InitConfig();
        }

        public async Task run() {
            Console.WriteLine("Executing runner");
            string ehubNamespaceConnectionString = ForwarderConfiguration.EhubNamespaceConnectionString;
            string eventHubName = ForwarderConfiguration.EventHubName;
            string blobStorageConnectionString = ForwarderConfiguration.BlobStorageConnectionString;
            string blobContainerName = ForwarderConfiguration.BlobContainerName;

            // Read from the default consumer group: $Default
            string consumerGroup = EventHubConsumerClient.DefaultConsumerGroupName;

            // Create a blob container client that the event processor will use 
            BlobContainerClient storageClient = new BlobContainerClient(blobStorageConnectionString, blobContainerName);

            // Create an event processor client to process events in the event hub
            EventProcessorClient processor = new EventProcessorClient(storageClient, consumerGroup, ehubNamespaceConnectionString, eventHubName);

            // Register handlers for processing events and handling errors
            processor.ProcessEventAsync += ProcessEventHandler;
            processor.ProcessErrorAsync += ProcessErrorHandler;

            // Start the processing
            Console.WriteLine("Starting proccessors to read Kubernetes audit events from Event Hubs");
            await processor.StartProcessingAsync();

            // Wait for 10 seconds for the events to be processed
            await Task.Delay(TimeSpan.FromSeconds(60 * 5));

            // Stop the processing
            Console.WriteLine("\n - Stopping all processors - \n");
            await processor.StopProcessingAsync();
        }

        static async Task ProcessEventHandler(ProcessEventArgs eventArgs)
        {
            string randomName = Guid.NewGuid().ToString("n").Substring(0, 8);
            Console.WriteLine("{0} > Recevied event", randomName);

            JObject eventJObj = JObject.Parse(Encoding.UTF8.GetString(eventArgs.Data.Body.ToArray()));

            int i = 0;
            foreach (JObject record in eventJObj["records"])
            {
                //Console.Write("{0}: ", i++);

                try
                {
                    JObject kubeAuditEvent = JObject.Parse(record["properties"]["log"].ToString());
                    Console.WriteLine("{0} {1} > {2} {3} {4} {5}",
                        randomName,
                        i++,
                        (string)kubeAuditEvent.SelectToken("user.username"),
                        (string)kubeAuditEvent.SelectToken("verb"),
                        (string)kubeAuditEvent.SelectToken("objectRef.resource"),
                        (string)kubeAuditEvent.SelectToken("objectRef.name"));

                    //Console.WriteLine("\n{0} ", kubeAuditEvent.ToString());
                    //Console.WriteLine("--------------------");

                }
                catch (Exception e)
                {
                    Console.WriteLine("+++++++++++++++++");
                }

                var values = new Dictionary<string, string>
                {
                    { "payload", record["properties"]["log"].ToString() }
                };

                //sendPost(values);

            }

            //Console.WriteLine("{0}", Encoding.UTF8.GetString(eventArgs.Data.Body.ToArray()));
            //Console.WriteLine();
            //Console.WriteLine("============================");
            //Console.WriteLine();

            // records.properties.log

            // Update checkpoint in the blob storage so that the app receives only new events the next time it's run
            await eventArgs.UpdateCheckpointAsync(eventArgs.CancellationToken);


        }

        async void sendPost(Dictionary<string, string> values)
        {
            //https://stackoverflow.com/questions/51134041/post-data-from-a-string-value-to-asp-net-core-web-api-controller-method

            var content = new FormUrlEncodedContent(values);
            var response = await client.PostAsync(ForwarderConfiguration.WebSinkURL, content);
            var responseString = await response.Content.ReadAsStringAsync();
            Console.WriteLine(responseString);
        }

        Task ProcessErrorHandler(ProcessErrorEventArgs eventArgs)
        {
            // Write details about the error to the console window
            Console.WriteLine($"\tPartition '{ eventArgs.PartitionId}': an unhandled exception was encountered. This was not expected to happen.");
            Console.WriteLine(eventArgs.Exception.Message);
            return Task.CompletedTask;
        }
    }
}




