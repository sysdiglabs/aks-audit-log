#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/core/runtime:3.1-alpine AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/core/sdk:3.1-buster AS build
WORKDIR /src
COPY AKSKubeAuditReceiver/AKSKubeAuditReceiver.csproj AKSKubeAuditReceiver/
RUN dotnet restore "AKSKubeAuditReceiver/AKSKubeAuditReceiver.csproj"
COPY . .
WORKDIR "/src/AKSKubeAuditReceiver"
RUN dotnet build "AKSKubeAuditReceiver.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "AKSKubeAuditReceiver.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

ENV USER=docker
ENV UID=12345
ENV GID=23456

RUN addgroup \
        -g "$GID"  \
        "$USER" && \
    adduser \
        --disabled-password \
        --gecos "" \
        --home "$(pwd)" \
        --ingroup "$USER" \
        --no-create-home \
        --uid "$UID" \
        "$USER"

RUN chown -R $USER:$USER .

HEALTHCHECK --interval=10s --timeout=5s --retries=3 CMD wget localhost:1234/metrics -q -O - > /dev/null 2>&1

#Prometheus port
EXPOSE 1234

ENTRYPOINT ["dotnet", "AKSKubeAuditReceiver.dll"]
