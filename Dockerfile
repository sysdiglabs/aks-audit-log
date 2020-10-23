FROM mcr.microsoft.com/azure-cli:2.9.1

RUN apk add gettext \
 && az aks install-cli

WORKDIR /app

COPY ./install-aks-audit-log.sh .
COPY ./uninstall-aks-audit-log.sh .

WORKDIR /data

ENTRYPOINT [ "/app/install-aks-audit-log.sh" ]
