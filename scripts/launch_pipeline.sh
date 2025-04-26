#!/usr/bin/env bash
# Collect user input → write tfvars.json → trigger Jenkins build

set -euo pipefail
LOG_DIR="$(dirname "$0")/logs"
mkdir -p "$LOG_DIR"

read -rp "Environment (lab/prod) [lab]: " ENV
ENV=${ENV:-lab}

read -rp "Number of VMs: " VM_COUNT
read -rp "vCPU per VM  : " VCPU
read -rp "RAM  (MB)    : " RAM
read -rp "OS template  : " OS_TEMPLATE   # e.g. ubuntu-22.04-cloud

# basic validation
"$(dirname "$0")/validate_input.sh" "$VM_COUNT" "$VCPU" "$RAM"

TFVARS=terraform/envs/$ENV/terraform.tfvars.json
cat >"$TFVARS" <<EOF
{
  "vm_count"     : $VM_COUNT,
  "vm_cpu"       : $VCPU,
  "vm_memory_mb" : $RAM,
  "vm_template"  : "$OS_TEMPLATE"
}
EOF
echo "Wrote $TFVARS"

# Trigger Jenkins
JENKINS_URL="<JENKINS_URL>"
JOB="secure-idp"
curl -sS -u "<JENKINS_USER>:<JENKINS_API_TOKEN>" \
     -X POST "$JENKINS_URL/job/$JOB/buildWithParameters" \
     --data-urlencode "ENV=$ENV" \
     --data-urlencode "GIT_COMMIT=$(git rev-parse HEAD)"

echo "Pipeline triggered – watch Jenkins for progress."
