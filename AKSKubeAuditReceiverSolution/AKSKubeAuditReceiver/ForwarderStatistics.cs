using Prometheus;

namespace AKSKubeAuditReceiver
{
    public static class ForwarderStatistics
    {

        private static readonly Counter Sent =
            Metrics.CreateCounter("sysdig_aks_audit_log_kube_events", "Total number of kube events sent");

        private static readonly Counter Errors =
            Metrics.CreateCounter("sysdig_aks_audit_log_kube_events_error", "Total number of kube events sent with error result");

        private static readonly Counter Successes =
            Metrics.CreateCounter("sysdig_aks_audit_log_kube_events_success", "Total number of kube events sent with success result");

        private static MetricServer Server;
        //private static KestrelMetricServer Server;

        public static void InitServer()
        {
            var diagnosticSourceRegistration = DiagnosticSourceAdapter.StartListening();

            Server = new MetricServer(port: 1234);
            Server.Start();
        }

        public static void IncreaseSuccesses()
        {
            Successes.Inc();
        }
        public static void IncreaseErrors()
        {
            Errors.Inc();
        }
        public static void IncreaseSent()
        {
            Sent.Inc();
        }

    }
}
