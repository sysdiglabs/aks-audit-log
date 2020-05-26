using Xunit;
using AKSKubeAuditReceiver;
using Moq;
using System.Net.Http;
using System.Collections.Generic;

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

        private Mock<IHttpHandler> getFakeHttpClient_returnErrorThenAccepted()
        {
            var okResult = new HttpResponseMessage
            {
                StatusCode = System.Net.HttpStatusCode.Accepted,
                Content = new StringContent("<html><body>Ok</body></html>")
            };
            var errorResult = new HttpResponseMessage
            {
                StatusCode = System.Net.HttpStatusCode.RequestTimeout,
                Content = new StringContent("")
            };

            var results = new Queue<HttpResponseMessage>();
            results.Enqueue(errorResult);
            results.Enqueue(okResult);

            Mock<IHttpHandler> fakeHttpClient = new Mock<IHttpHandler>();
            fakeHttpClient.SetupSequence(m => m.PostAsync(It.IsAny<string>(), It.IsAny<HttpContent>()))
                .Throws<HttpRequestException>()
                .ReturnsAsync(okResult);

            return fakeHttpClient;
        }

        [Fact]
        public async void TestEventPosted()
        {
            string kubeEvent = "";

            Mock<IHttpHandler> fakeHttpClient = getFakeHttpClient_returnAccepted();
            var webhookPoster = new WebhookPoster(ForwarderConfiguration);
            webhookPoster.HttpClient = fakeHttpClient.Object;

            bool result = await webhookPoster.SendPost(kubeEvent);

            fakeHttpClient.Verify(mock => mock.PostAsync(
                It.IsAny<string>(), It.IsAny<HttpContent>()), Times.Once());

            Assert.True(result == true, "Returned true");

        }

        [Fact]
        public async void TestEventPostedAfterError()
        {
            string kubeEvent = "";

            Mock<IHttpHandler> fakeHttpClient = getFakeHttpClient_returnErrorThenAccepted();
            var webhookPoster = new WebhookPoster(ForwarderConfiguration);
            webhookPoster.HttpClient = fakeHttpClient.Object;

            bool result = await webhookPoster.SendPost(kubeEvent);

            fakeHttpClient.Verify(mock => mock.PostAsync(It.IsAny<string>(), It.IsAny<HttpContent>()), Times.Exactly(2));

            Assert.True(result==true, "Returned true");            

        }
    }
}
