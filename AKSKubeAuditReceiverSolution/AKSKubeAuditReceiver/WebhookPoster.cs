using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AKSKubeAuditReceiver
{
    public class WebhookPoster : IWebhookPoster
    {

        private readonly ForwarderConfiguration ForwarderConfiguration;
        public IHttpHandler HttpClient = null;

        public WebhookPoster(ForwarderConfiguration forwarderConfiguration)
        {
            ForwarderConfiguration = forwarderConfiguration;
        }

        public void InitConfig()
        {
            if (HttpClient == null) HttpClient = new HttpClientHandler();
        }

        private async Task<HttpResponseMessage> PostSyncNoException(string url, HttpContent content)
        {
            HttpResponseMessage response;
            try
            {
                response = HttpClient.PostAsync(url, content).Result;
                return response;
            }
            catch (Exception e)
            {
                var response2 = new HttpResponseMessage
                {
                    StatusCode = System.Net.HttpStatusCode.Gone,
                    Content = new StringContent(e.Message, Encoding.UTF8)
                };
                return response2;
            }
            
        }

        public async Task<bool> SendPost(string kubeAuditEventStr, string mainEventName = "", int eventNumber = 0)
        {

            //TODO: If more speed is needed, have an option to post using async, without waiting or retrying errors

            var content = new StringContent(kubeAuditEventStr, Encoding.UTF8, "application/json");
            var retries = 1;
            var delay = ForwarderConfiguration.PostRetryIncrementalDelay;

            if (ForwarderConfiguration.VerboseLevel > 3)
                Console.WriteLine("{0} {1} > POST kube event to: {2}", mainEventName, eventNumber,
                    ForwarderConfiguration.WebSinkURL);

            ForwarderStatistics.IncreaseSent();
            var response = await PostSyncNoException(ForwarderConfiguration.WebSinkURL, content);     

            while ( ! response.IsSuccessStatusCode &&
                retries <= ForwarderConfiguration.PostMaxRetries)
            {
                Console.WriteLine("{0} {1} > **Error sending POST, retry {2}, result: [{3}] {4}",
                        mainEventName, eventNumber, retries, response.StatusCode, response.Content.ToString());
                retries++;
                await Task.Delay(delay);
                delay += ForwarderConfiguration.PostRetryIncrementalDelay;
                ForwarderStatistics.IncreaseRetries();
                response = await PostSyncNoException(ForwarderConfiguration.WebSinkURL, content);
            }

            if (response.IsSuccessStatusCode)
            {
                ForwarderStatistics.IncreaseSuccesses();
                if (ForwarderConfiguration.VerboseLevel > 3)
                    Console.WriteLine("{0} {1} > Post response OK", mainEventName, eventNumber);
                return true;
            }
            else
            {
                ForwarderStatistics.IncreaseErrors();
                Console.WriteLine("{0} {1} > **Error post response after max retries, gave up: [{3}] {4}",
                    mainEventName, eventNumber, response.StatusCode, response.Content.ToString());
                return false;
            }

        }
    }
}
