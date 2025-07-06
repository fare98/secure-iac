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

# 2. Check for SSH public key
SSH_PUB_KEY_PATH="${HOME}/.ssh/idp_ansible.pub"
if [ ! -f "${SSH_PUB_KEY_PATH}" ]; then
    echo "ERROR: SSH public key not found at ${SSH_PUB_KEY_PATH}"
    echo "Please run ./scripts/setup_ssh_keys.sh first to generate SSH keys."
    exit 1
fi
SSH_PUBLIC_KEY=$(cat "${SSH_PUB_KEY_PATH}")
echo "Found SSH public key at ${SSH_PUB_KEY_PATH}"

# 3. Interactive input
read -rp "How many VMs?        " VM_COUNT
read -rp "vCPU per VM?         " VCPU
read -rp "RAM per VM (MB)?     " RAM
read -rp "Template name?       " OS_TEMPLATE

# 4. Write tfvars (including SSH public key)
TFVARS_PATH="${REPO_ROOT}/terraform/terraform.tfvars.json"

cat > "${TFVARS_PATH}" <<EOF
{
  "vm_count"       : ${VM_COUNT},
  "vm_cpu"         : ${VCPU},
  "vm_memory_mb"   : ${RAM},
  "vm_template"    : "${OS_TEMPLATE}",
  "ssh_public_key" : "${SSH_PUBLIC_KEY}"
}
EOF
echo "Wrote ${TFVARS_PATH}"

# 5. Commit & push the tfvars so Jenkins sees this exact set
cd "${REPO_ROOT}"
git add terraform/terraform.tfvars.json
git commit -m "auto(tfvars): ${VM_COUNT}×${VCPU}cpu/${RAM}MB ${OS_TEMPLATE}" \
             --author="launcher <auto@local>" || true   # 'true' avoids stopping if nothing changed
git push

# 6. Get crumb (Jenkins anti-CSRF token)
CRUMB=$(curl -s -u "${JENKINS_USER}:${JENKINS_TOKEN}" \
        "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

# 7. Trigger the build with crumb header
curl -s -u "${JENKINS_USER}:${JENKINS_TOKEN}" \
     -H "${CRUMB}" \
     -X POST "${JENKINS_URL}/job/${JOB_NAME}/build?delay=0sec"

echo "Triggered Jenkins build for ${JOB_NAME}."