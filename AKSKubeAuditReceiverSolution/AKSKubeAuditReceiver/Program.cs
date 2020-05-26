using System;
using System.Threading.Tasks;
using AKSKubeAuditReceiver;

namespace NetCore.Docker
{
    class Program
    {
        private static readonly string Version = "0.1.3";

        static async Task Main(string[] args)
        {
            Console.WriteLine("AKS Kubernetes audit log forwarder from Event Hubs to Sysdig agent");
            Console.WriteLine("Version {0}", Version);
            Console.WriteLine("Starting Prometheus statistics");
            ForwarderStatistics.InitServer();
            Console.WriteLine("Starting program");
            EventHubRunner runner = new EventHubRunner();
            await runner.run();
            Console.WriteLine("Program ended");
        }

    }
}
