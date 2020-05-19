using Xunit;
using AKSKubeAuditReceiver;
using Moq;
using Azure.Messaging.EventHubs.Processor;
using Azure.Messaging.EventHubs;
using System.Text;
using Newtonsoft.Json.Linq;
using System.Collections.Generic;
using System.Collections;

namespace AKSKubeAuditTests
{
    public class HubEventUnpackerTest
    {
        private readonly ForwarderConfiguration Configuration;

        private readonly string SampleKubeEvent = @"{""kind"":""Event"",""apiVersion"":""audit.k8s.io/v1"",""level"":""Metadata"",""auditID"":""b71eacd3-1a6b-413e-ad54-83e2d53e4f91"",""stage"":""ResponseComplete"",""requestURI"":""/api/v1?timeout=32s"",""verb"":""get"",""user"":{""username"":""system:serviceaccount:kube-system:resourcequota-controller"",""uid"":""00165e56-1707-4469-a781-498909beaf39"",""groups"":[""system:serviceaccounts"",""system:serviceaccounts:kube-system"",""system:authenticated""]},""sourceIPs"":[""172.31.9.19""],""userAgent"":""hyperkube/v1.15.10 (linux/amd64) kubernetes/059c666/system:serviceaccount:kube-system:resourcequota-controller"",""responseStatus"":{""metadata"":{},""code"":200},""requestReceivedTimestamp"":""2020-05-07T07:39:03.050399Z"",""stageTimestamp"":""2020-05-07T07:39:03.050848Z"",""annotations"":{""authorization.k8s.io/decision"":""allow"",""authorization.k8s.io/reason"":""RBAC: allowed by ClusterRoleBinding \""system: discovery\"" of ClusterRole \""system: discovery\"" to Group \""system: authenticated\""""}}";

            public HubEventUnpackerTest()
        {
            Configuration = new ForwarderConfiguration();
        }

        private Mock<IWebhookPoster> GetFakeWebhookPoster_returnsTrue()
        {
            Mock<IWebhookPoster> fakeWebhookPoster = new Mock<IWebhookPoster>();
            fakeWebhookPoster.Setup(m => m.InitConfig());
            fakeWebhookPoster.Setup(m => m.SendPost(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<int>()))
                .ReturnsAsync(true);

            return fakeWebhookPoster;
        }

        private JObject GetSampleJsonHubEvent(List<string> kubeEvents)
        {
            string records = "";
            foreach (string kubeEvent in kubeEvents)
            {
                records = records + @"{ 'properties': { 'log': " + kubeEvent + @" } },";
            }
            records = records.Substring(0, records.Length - 1);
            string json = @"{
                'records': [  "+records + @" ]
            }";
            var jsonHubEvent = JObject.Parse(json);

            return jsonHubEvent;
        }


        [Fact]
        public async void TestProcessOneEvent()
        {
            var hubEventUnpacker = new HubEventUnpacker(Configuration);
            var fakeWebhookPoster = GetFakeWebhookPoster_returnsTrue();
            hubEventUnpacker.WebhookPoster = fakeWebhookPoster.Object;
            var kubeEvents = new List<string>
            {
                SampleKubeEvent
            };

            JObject jsonHubEvent = GetSampleJsonHubEvent(kubeEvents);

            await hubEventUnpacker.Process(jsonHubEvent);

            fakeWebhookPoster.Verify(
                mock => mock.SendPost(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<int>()),
                Times.Exactly(1));

        }

        [Fact]
        public async void TestProcessThreeEvents()
        {
            var hubEventUnpacker = new HubEventUnpacker(Configuration);
            var fakeWebhookPoster = GetFakeWebhookPoster_returnsTrue();
            hubEventUnpacker.WebhookPoster = fakeWebhookPoster.Object;
            var kubeEvents = new List<string>
            {
                SampleKubeEvent,
                SampleKubeEvent,
                SampleKubeEvent
            };

            JObject jsonHubEvent = GetSampleJsonHubEvent(kubeEvents);

            await hubEventUnpacker.Process(jsonHubEvent);

            fakeWebhookPoster.Verify(
                mock => mock.SendPost(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<int>()),
                Times.Exactly(3));

        }
    }
}
