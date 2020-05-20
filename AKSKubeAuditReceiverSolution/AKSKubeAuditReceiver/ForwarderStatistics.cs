using System;
namespace AKSKubeAuditReceiver
{
    public static class ForwarderStatistics
    {
        public static UInt64 Errors = 0;
        public static UInt64 Successes = 0;
        public static UInt64 Sent = 0;

        public static void IncreaseSuccesses()
        {
            Successes++;
        }
        public static void IncreaseErrors()
        {
            Errors++;
        }
        public static void IncreaseSent()
        {
            Errors++;
        }
        public static void PeriodicOutput()
        {
            Console.WriteLine("Stats > {0} errors, {0} successes, {0} sent, {0} waiting",
                Errors, Successes, Sent, Sent - Successes - Errors);

        }
    }
}
