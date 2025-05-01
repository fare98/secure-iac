#!/usr/bin/env bash
set -euo pipefail

##############################################################################
# basic input → tfvars
##############################################################################
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

read -rp "How many VMs? "        VM_COUNT
read -rp "vCPU per VM? "         VCPU
read -rp "RAM per VM (MB)? "     RAM
read -rp "Template name? "       OS_TEMPLATE

cat > "${REPO_ROOT}/terraform/terraform.tfvars.json" <<EOF
{
  "vm_count"     : ${VM_COUNT},
  "vm_cpu"       : ${VCPU},
  "vm_memory_mb" : ${RAM},
  "vm_template"  : "${OS_TEMPLATE}"
}
EOF
echo "Wrote terraform/terraform.tfvars.json"

##############################################################################
# Jenkins trigger (crumb-aware)
##############################################################################
JENKINS_URL="http://192.168.178.50:8080"
JENKINS_USER="admin"
JENKINS_TOKEN="11070510890378cb97b87c9809bd0f9fad"

# 1. fetch crumb (field:value)
CRUMB=$(curl -s -u "${JENKINS_USER}:${JENKINS_TOKEN}" \
        "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

# 2. trigger build with crumb header
curl -s -u "${JENKINS_USER}:${JENKINS_TOKEN}" -H "${CRUMB}" \
     -X POST "${JENKINS_URL}/job/secure-idp/build"

echo "Triggered Jenkins build."