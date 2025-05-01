#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# CONFIG –- adjust only if your URL/user/token ever change
###############################################################################
JENKINS_URL="http://192.168.178.50:8080"
JENKINS_USER="admin"
JENKINS_TOKEN="11070510890378cb97b87c9809bd0f9fad"
JOB_NAME="secure-idp"                 # Jenkins job to build
###############################################################################

# 1. Figure out repo root no matter where the script is called from
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 2. Interactive input
read -rp "How many VMs?        " VM_COUNT
read -rp "vCPU per VM?         " VCPU
read -rp "RAM per VM (MB)?     " RAM
read -rp "Template name?       " OS_TEMPLATE

# 3. Write tfvars
TFVARS_PATH="${REPO_ROOT}/terraform/terraform.tfvars.json"

cat > "${TFVARS_PATH}" <<EOF
{
  "vm_count"     : ${VM_COUNT},
  "vm_cpu"       : ${VCPU},
  "vm_memory_mb" : ${RAM},
  "vm_template"  : "${OS_TEMPLATE}"
}
EOF
echo "Wrote ${TFVARS_PATH}"

# 4. Commit & push the tfvars so Jenkins sees this exact set
cd "${REPO_ROOT}"
git add terraform/terraform.tfvars.json
git commit -m "auto(tfvars): ${VM_COUNT}×${VCPU}cpu/${RAM}MB ${OS_TEMPLATE}" \
             --author="launcher <auto@local>" || true   # 'true' avoids stopping if nothing changed
git push

# 5. Get crumb (Jenkins anti-CSRF token)
CRUMB=$(curl -s -u "${JENKINS_USER}:${JENKINS_TOKEN}" \
        "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

# 6. Trigger the build with crumb header
curl -s -u "${JENKINS_USER}:${JENKINS_TOKEN}" \
     -H "${CRUMB}" \
     -X POST "${JENKINS_URL}/job/${JOB_NAME}/build?delay=0sec"

echo "Triggered Jenkins build for ${JOB_NAME}."