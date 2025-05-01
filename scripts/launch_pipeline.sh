#!/usr/bin/env bash
# Run on the client (192.168.178.52) to trigger Jenkins

set -euo pipefail

read -rp "How many VMs? "        VM_COUNT
read -rp "vCPU per VM? "         VCPU
read -rp "RAM per VM (MB)? "     RAM
read -rp "Template name? "       OS_TEMPLATE   # e.g. ubuntu-22.04-cloud

# basic sanity:
[[ $VM_COUNT =~ ^[0-9]+$ ]] || { echo "Bad number"; exit 1; }

cat > terraform/terraform.tfvars.json <<EOF
{
  "vm_count"     : $VM_COUNT,
  "vm_cpu"       : $VCPU,
  "vm_memory_mb" : $RAM,
  "vm_template"  : "$OS_TEMPLATE"
}
EOF
echo "Wrote terraform.tfvars.json"

curl -sS -u "admin:119e754c394710b2" \
     -X POST "http://192.168.178.50:8080/job/secure-idp/build"
echo "Triggered Jenkins build."