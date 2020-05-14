using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AKSKubeAuditReceiver
{
    class WebhookPoster
    {

        private ForwarderConfiguration ForwarderConfiguration;
        private HttpClient HttpClient;

        public WebhookPoster(ForwarderConfiguration forwarderConfiguration)
        {
            ForwarderConfiguration = forwarderConfiguration;
            HttpClient = new HttpClient();
        }
        
        public async Task<bool> SendPost(string kubeAuditEventStr, string mainEventName = "", int eventNumber = 0)
        {
            try
            {
                var content = new StringContent(kubeAuditEventStr, Encoding.UTF8, "application/json");

                if (ForwarderConfiguration.VerboseLevel > 3)
                    Console.WriteLine("{0} {1} > POST kube event to: {2}", mainEventName, eventNumber,
                        ForwarderConfiguration.WebSinkURL);

                var response = await HttpClient.PostAsync(ForwarderConfiguration.WebSinkURL, content);

                if (ForwarderConfiguration.VerboseLevel > 3)
                {
                    //TODO: Info user that requesting result log makes the POST run sync, which will be slower
                    string responseString = await response.Content.ReadAsStringAsync();
                    if (responseString == "<html><body>Ok</body></html>")
                    {
                        Console.WriteLine("{0} {1} > Response OK", mainEventName, eventNumber);
                    } else
                    {
                        Console.WriteLine("{0} {1} > Response: {2}", mainEventName, eventNumber, responseString);
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("{0} {1} > POST error: {2}",
                    mainEventName, eventNumber, e.Message);
                return false;
            }

            return true;
        }
    }
}
