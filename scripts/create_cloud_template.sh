#!/bin/bash
# Script to create a cloud-init enabled template in Proxmox

# Configuration
TEMPLATE_NAME="ubuntu-cloud-template"
TEMPLATE_ID="9000"  # Change if this ID is already used
STORAGE="local-lvm"  # Change to your storage pool
NODE="pve"  # Your Proxmox node name

echo "Creating Ubuntu Cloud-Init Template..."

# Download Ubuntu 22.04 LTS cloud image
echo "Downloading Ubuntu Cloud Image..."
wget -q --show-progress https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create a new VM
echo "Creating VM..."
qm create $TEMPLATE_ID --name $TEMPLATE_NAME --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import the downloaded disk to the VM
echo "Importing disk..."
qm importdisk $TEMPLATE_ID jammy-server-cloudimg-amd64.img $STORAGE

# Configure the VM
echo "Configuring VM..."
qm set $TEMPLATE_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$TEMPLATE_ID-disk-0
qm set $TEMPLATE_ID --boot c --bootdisk scsi0
qm set $TEMPLATE_ID --ide2 $STORAGE:cloudinit
qm set $TEMPLATE_ID --serial0 socket --vga serial0
qm set $TEMPLATE_ID --agent enabled=1

# IMPORTANT: Set the disk size (optional, but recommended)
echo "Resizing disk to 20G..."
qm resize $TEMPLATE_ID scsi0 20G

# Convert to template
echo "Converting to template..."
qm template $TEMPLATE_ID

# Clean up
rm -f jammy-server-cloudimg-amd64.img

echo "Template created successfully!"
echo "Template ID: $TEMPLATE_ID"
echo "Template Name: $TEMPLATE_NAME"
echo ""
echo "To use this template, update your terraform.tfvars.json:"
echo '  "vm_template": "'$TEMPLATE_NAME'"'