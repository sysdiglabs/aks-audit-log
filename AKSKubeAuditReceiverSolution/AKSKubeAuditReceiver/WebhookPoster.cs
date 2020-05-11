using System;
using System.Net.Http;
using System.Text;

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
        
        public async void SendPost(string kubeAuditEventStr, string mainEventName = "", int eventNumber = 0)
        {

            //https://stackoverflow.com/questions/51134041/post-data-from-a-string-value-to-asp-net-core-web-api-controller-method
            //https://stackoverflow.com/questions/4015324/how-to-make-an-http-post-web-request
            //https://stackoverflow.com/questions/38516610/using-json-net-to-convert-part-of-a-jobject-to-dictionarystring-string/38516699

            try
            {
                var content = new StringContent(kubeAuditEventStr, Encoding.UTF8, "application/json");
                var response = await HttpClient.PostAsync(ForwarderConfiguration.WebSinkURL, content);
                if (ForwarderConfiguration.ConsoleOutputPostResponse)
                {
                    string responseString = await response.Content.ReadAsStringAsync();
                    Console.WriteLine("{0} {1} > Response: {2}",
                        mainEventName, eventNumber, responseString);
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("{0} {1} > Couldn't POST data: {3}",
                    mainEventName, eventNumber, e.Message);
            }

        }
    }
}
