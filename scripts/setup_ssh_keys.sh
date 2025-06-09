#!/bin/bash

# Script to generate SSH keys for cloud-init automation

SSH_KEY_PATH="${HOME}/.ssh/idp_ansible"

if [ ! -f "${SSH_KEY_PATH}" ]; then
    echo "Generating SSH keypair for Ansible automation..."
    ssh-keygen -t rsa -b 4096 -f "${SSH_KEY_PATH}" -N "" -C "ansible@idp"
    echo "SSH keypair generated at: ${SSH_KEY_PATH}"
else
    echo "SSH keypair already exists at: ${SSH_KEY_PATH}"
fi

echo ""
echo "SSH Public Key (use this in terraform.tfvars.json):"
echo "================================================="
cat "${SSH_KEY_PATH}.pub"
echo "================================================="
echo ""
echo "Add the following to your terraform.tfvars.json:"
echo '  "ssh_public_key": "'$(cat ${SSH_KEY_PATH}.pub)'"'