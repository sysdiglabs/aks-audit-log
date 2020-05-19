using System;
using System.Threading.Tasks;

namespace AKSKubeAuditReceiver
{
    public interface IWebhookPoster
    {
        public Task<bool> SendPost(string kubeAuditEventStr, string mainEventName = "", int eventNumber = 0);
        public void InitConfig();
    }
}
