# fish script

set -x ran (cat /dev/random | LC_ALL=C tr -dc "[:alpha:]" | head -c 8)

set -Ux RESOURCE_GROUP AKSAuditLogTest-Group-"$ran"
set -Ux CLUSTER_NAME AKSAuditLogTest-Cluster-"$ran"
set -Ux SYSDIG_NAMESPACE sysdig-agent

echo "Resource group: $RESOURCE_GROUP"
echo "Cluster name: $CLUSTER_NAME"
echo "Sysdig namespace: $SYSDIG_NAMESPACE"
