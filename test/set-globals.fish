# fish script

set -x ran (cat /dev/random | LC_ALL=C tr -dc "[:alpha:]" | head -c 8)

set -Ux my_resource_group AKSAuditLogTest-Group-"$ran"
set -Ux my_cluster_name AKSAuditLogTest-Cluster-"$ran"
set -Ux my_sysdig_namespace my-sysdig-agent

echo "Resource group: $my_resource_group"
echo "Cluster name: $my_cluster_name"
