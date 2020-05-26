using System.Net.Http;
using System.Threading.Tasks;

namespace AKSKubeAuditReceiver
{
    public class HttpClientHandler : IHttpHandler
    {
        private readonly HttpClient _client = new HttpClient();

        public async Task<HttpResponseMessage> GetAsync(string url)
        {
            return await _client.GetAsync(url);
        }

        public async Task<HttpResponseMessage> PostAsync(string url, HttpContent content)
        {
            return await _client.PostAsync(url, content);
        }

    }
}
