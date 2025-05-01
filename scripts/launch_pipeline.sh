#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

read -rp "How many VMs? "        VM_COUNT
read -rp "vCPU per VM? "         VCPU
read -rp "RAM per VM (MB)? "     RAM
read -rp "Template name? "       OS_TEMPLATE

cat > "${REPO_ROOT}/terraform/terraform.tfvars.json" <<EOF
{
  "vm_count"     : $VM_COUNT,
  "vm_cpu"       : $VCPU,
  "vm_memory_mb" : $RAM,
  "vm_template"  : "$OS_TEMPLATE"
}
EOF
echo "Wrote terraform.tfvars.json"


JENKINS_USER="admin"
JENKINS_TOKEN="11070510890378cb97b87c9809bd0f9fad"  

curl -sS "http://${JENKINS_USER}:${JENKINS_TOKEN}@192.168.178.50:8080/job/secure-idp/build"

