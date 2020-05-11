using System;
using System.Threading.Tasks;
using Azure.Storage.Blobs;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Azure.Messaging.EventHubs.Processor;

namespace AKSKubeAuditReceiver
{
    public class EventHubRunner
    {
        private static ForwarderConfiguration ForwarderConfiguration;
        private static HubEventUnpacker HubEventUnpacker;

        public EventHubRunner()
        {
            Console.WriteLine("Set up runner");
            ForwarderConfiguration = new ForwarderConfiguration();
            ForwarderConfiguration.InitConfig();
            HubEventUnpacker = new HubEventUnpacker(ForwarderConfiguration);
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

            // Wait for some events to be processed
            await Task.Delay(TimeSpan.FromSeconds(60 * 6));

            // Stop the processing
            Console.WriteLine("\n - Stopping all processors - \n");
            await processor.StopProcessingAsync();
        }

        static async Task ProcessEventHandler(ProcessEventArgs eventArgs)
        {
            string randomName = Guid.NewGuid().ToString("n").Substring(0, 8);
            Console.WriteLine("{0} > Received event pack", randomName);
            HubEventUnpacker.Process(eventArgs, randomName);
            await eventArgs.UpdateCheckpointAsync(eventArgs.CancellationToken);
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




