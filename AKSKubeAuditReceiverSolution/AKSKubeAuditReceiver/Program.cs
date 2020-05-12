using System;
using System.Threading.Tasks;
using AKSKubeAuditReceiver;

namespace NetCore.Docker
{
    class Program
    {
        static async Task Main(string[] args)
        {
            Console.WriteLine("Starting program");
            EventHubRunner runner = new EventHubRunner();
            await runner.run();
            Console.WriteLine("Program ended");
        }

    }
}
