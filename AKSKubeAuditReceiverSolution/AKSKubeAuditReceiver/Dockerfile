#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/core/runtime:3.1-buster-slim AS base
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
EXPOSE 1234
ENTRYPOINT ["dotnet", "AKSKubeAuditReceiver.dll"]
