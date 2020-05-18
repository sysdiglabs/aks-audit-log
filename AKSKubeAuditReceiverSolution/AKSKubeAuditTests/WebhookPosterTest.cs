using Xunit;
using AKSKubeAuditReceiver;
using Moq;
using System.Net.Http;

namespace AKSKubeAuditTests
{
    public class WebhookPosterTest
    {
        private readonly ForwarderConfiguration ForwarderConfiguration;

        public WebhookPosterTest()
        {
            ForwarderConfiguration = new ForwarderConfiguration();
        }

        private Mock<IHttpHandler> getFakeHttpClient_returnAccepted()
        {
            //var okContent = new HttpContent();

            var okResult = new HttpResponseMessage
            {
                StatusCode = System.Net.HttpStatusCode.Accepted,
                Content = new StringContent("<html><body>Ok</body></html>")
            };

            Mock<IHttpHandler> fakeHttpClient = new Mock<IHttpHandler>();
            fakeHttpClient.Setup(m => m.PostAsync(It.IsAny<string>(), It.IsAny<HttpContent>()))
                .ReturnsAsync(okResult);

            return fakeHttpClient;
        }

        [Fact]
        public async void Test1()
        {
            string kubeEvent = "";

            Mock<IHttpHandler> fakeHttpClient = getFakeHttpClient_returnAccepted();
            var webhookPoster = new WebhookPoster(ForwarderConfiguration);
            webhookPoster.HttpClient = (IHttpHandler) fakeHttpClient.Object;

            await webhookPoster.SendPost(kubeEvent);

            fakeHttpClient.Verify(mock => mock.PostAsync(It.IsAny<string>(), It.IsAny<HttpContent>()), Times.Once());
            Assert.True(true, "Event sent using HttpClient");
        }
    }
}
