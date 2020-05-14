#!/bin/bash

docker build -f Dockerfile . \
        -t aks-audit-log \
        -t aks-audit-log:dev \
        -t sysdiglabs/aks-audit-log \
        -t sysdiglabs/aks-audit-log:dev &&
    docker push sysdiglabs/aks-audit-log:dev
