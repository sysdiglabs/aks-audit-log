FROM mcr.microsoft.com/azure-cli

RUN apk add gettext \
 && az aks install-cli

WORKDIR /app

COPY ./install-aks-audit-log.sh .

WORKDIR /data

ENTRYPOINT [ "/app/install-aks-audit-log.sh" ]
