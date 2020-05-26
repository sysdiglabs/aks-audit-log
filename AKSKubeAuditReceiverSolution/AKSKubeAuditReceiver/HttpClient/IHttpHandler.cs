using System;
using System.Net.Http;
using System.Threading.Tasks;

namespace AKSKubeAuditReceiver
{
    public interface IHttpHandler
    {
        Task<HttpResponseMessage> GetAsync(string url);
        Task<HttpResponseMessage> PostAsync(string url, HttpContent content);
    }
}
