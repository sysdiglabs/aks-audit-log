#!/bin/bash

echo "Enabling http_application_routing"
az aks enable-addons \
    --resource-group AKSAuditLogTestGroup \
    --name AKSAuditLogTestCluster \
    --addons http_application_routing

echo "Getting dns name"

name=$(az aks show \
    --resource-group AKSAuditLogTestGroup \
    --name AKSAuditLogTestCluster \
    --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName \
    -o tsv)

echo $name

DNS_PREFIX=$name cat ingress.yaml.in | envsubst > deployment.yaml
