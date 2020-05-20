#!/bin/bash

set -euo pipefail

script_dir=$(dirname "$(realpath $0)")

#echo "1/4 BUILDING"
dotnet build ${script_dir}/AKSKubeAuditReceiver.sln
echo "---------------------------------"
echo "2/4 TESTING"
dotnet test ${script_dir}/AKSKubeAuditReceiver.sln
echo "---------------------------------"
echo "3/4 DOCKER BUILDING"
docker build -f ${script_dir}/AKSKubeAuditReceiver/Dockerfile ${script_dir} \
        -t aks-audit-log-forwarder \
        -t aks-audit-log-forwarder:dev \
        -t sysdiglabs/aks-audit-log-forwarder \
        -t sysdiglabs/aks-audit-log-forwarder:dev &&
echo "---------------------------------"
echo "4/4 DOCKER PUSHING "
docker push sysdiglabs/aks-audit-log-forwarder:dev
echo "---------------------------------"
echo "Pushed: sysdiglabs/aks-audit-log-forwarder:dev"