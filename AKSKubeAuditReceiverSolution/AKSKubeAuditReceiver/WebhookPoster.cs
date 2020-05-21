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

        public async Task<bool> SendPost(string kubeAuditEventStr, string mainEventName = "", int eventNumber = 0)
        {
            try
            {
                var content = new StringContent(kubeAuditEventStr, Encoding.UTF8, "application/json");

                if (ForwarderConfiguration.VerboseLevel > 3)
                    Console.WriteLine("{0} {1} > POST kube event to: {2}", mainEventName, eventNumber,
                        ForwarderConfiguration.WebSinkURL);

                ForwarderStatistics.IncreaseSent();
                var response = await HttpClient.PostAsync(ForwarderConfiguration.WebSinkURL, content);
                    
                if ( response.IsSuccessStatusCode == true )
                {
                    ForwarderStatistics.IncreaseSuccesses();
                    if (ForwarderConfiguration.VerboseLevel > 3)
                        Console.WriteLine("{0} {1} > Post response OK", mainEventName, eventNumber);
                    return false;
                }
                else
                {
                    ForwarderStatistics.IncreaseErrors();
                    Console.WriteLine("{0} {1} > **Error post response: {2}", mainEventName, eventNumber, response.Content.ToString());
                    return false;
                }
                
            }
            catch (Exception e)
            {
                ForwarderStatistics.IncreaseErrors();
                Console.WriteLine("{0} {1} > **Error sending post: {2}",
                    mainEventName, eventNumber, e.Message);
                return false;
            }

        }
    }
}
