#!/bin/bash

docker build -f AKSKubeAuditReceiver/Dockerfile . \
        -t aks-audit-log-forwarder \
        -t aks-audit-log-forwarder:dev \
        -t sysdiglabs/aks-audit-log-forwarder \
        -t sysdiglabs/aks-audit-log-forwarder:dev &&
    docker push sysdiglabs/aks-audit-log-forwarder:dev
