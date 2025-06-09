# Cloud-Init VM Automation Setup

This guide explains how to set up fully automated VM deployment with cloud-init on Proxmox.

## Prerequisites

### 1. Create a Cloud-Init Enabled Template in Proxmox

```bash
# Download a cloud-init enabled image (example with Ubuntu)
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create a new VM (use ID 9000 for template)
qm create 9000 --name ubuntu-22.04-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import the disk
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm

# Attach the disk
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# Add cloud-init drive
qm set 9000 --ide2 local-lvm:cloudinit

# Make it bootable
qm set 9000 --boot c --bootdisk scsi0

# Add serial console
qm set 9000 --serial0 socket --vga serial0

# Enable QEMU agent
qm set 9000 --agent enabled=1

# Convert to template
qm template 9000
```

### 2. Generate SSH Keys

Run the provided script to generate SSH keys:

```bash
./scripts/setup_ssh_keys.sh
```

This will create an SSH keypair and show you the public key to add to your configuration.

### 3. Update terraform.tfvars.json

Add the SSH public key to your `terraform.tfvars.json`:

```json
{
  "vm_count"     : 2,
  "vm_cpu"       : 1,
  "vm_memory_mb" : 2000,
  "vm_template"  : "ubuntu-22.04-template",
  "ssh_public_key": "ssh-rsa AAAAB3NzaC1... ansible@idp"
}
```

### 4. Configure Jenkins

Add the SSH private key to Jenkins:
1. Go to Jenkins → Manage Jenkins → Manage Credentials
2. Add a new "SSH Username with private key" credential
3. ID: `ansible-ssh-key`
4. Username: `ansible`
5. Private Key: Enter directly and paste the content of `~/.ssh/idp_ansible`

## How It Works

1. **Terraform creates VMs** with cloud-init configuration:
   - Static IP assignment (192.168.178.50, .51, etc.)
   - SSH key injection
   - User creation (ansible user)
   - Network configuration

2. **Cloud-init runs on first boot** and configures:
   - Networking with static IPs
   - SSH authorized keys
   - User accounts
   - Package updates

3. **Terraform generates Ansible inventory** automatically with:
   - VM names and IP addresses
   - SSH connection details

4. **Jenkins runs Ansible** to:
   - Apply security hardening
   - Configure firewall rules
   - Set up additional users/keys

## Customization

### Change IP Range
Edit module variables in `terraform/modules/vm/variables.tf`:
- `vm_ip_base`: Base network (default: "192.168.178")
- `vm_ip_offset`: Starting IP offset (default: 50)

### Change Default User
Update `cloud_init_user` variable (default: "ansible")

### Add More Cloud-Init Configuration
For advanced cloud-init features, you can:
1. Create custom user-data files
2. Use the `cicustom` parameter in the VM resource
3. Configure package installation, scripts, etc.

## Troubleshooting

### VMs Not Accessible
- Check cloud-init status: `ssh user@ip cloud-init status`
- Verify network configuration matches your environment
- Ensure the template has cloud-init installed

### SSH Connection Refused
- Verify SSH keys are correctly formatted
- Check firewall rules on Proxmox host
- Ensure cloud-init completed successfully

### Ansible Cannot Connect
- Verify the dynamic inventory was generated
- Check SSH key permissions (600)
- Test manual SSH connection first