#!/usr/bin/env bash
set -euo pipefail
VM_COUNT=${1:-0}; VCPU=${2:-0}; RAM=${3:-0}

[[ $VM_COUNT =~ ^[0-9]+$ && $VM_COUNT -gt 0 ]] || { echo "VM count invalid"; exit 1; }
[[ $VCPU =~ ^[0-9]+$ && $VCPU -gt 0 && $VCPU -le 32 ]] || { echo "vCPU out of bounds"; exit 1; }
[[ $RAM =~ ^[0-9]+$ && $RAM -ge 512 && $RAM -le 65536 ]] || { echo "RAM out of bounds"; exit 1; }
