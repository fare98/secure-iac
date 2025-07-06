# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Secure Infrastructure-as-Code (IaC) monorepo that provides single-click provisioning, hardening, and compliance scanning of Proxmox VMs using a complete DevSecOps stack. The pipeline follows GitOps principles where all infrastructure changes are driven through git commits.

## Key Commands

### Terraform Operations
```bash
make lint     # Run tflint, tfsec, and checkov for linting and security scanning
make plan     # Create a Terraform plan (automatically runs lint first)
make apply    # Apply the Terraform plan
make destroy  # Destroy the infrastructure
```

### Pipeline Trigger
```bash
./scripts/launch_pipeline.sh  # Interactive wizard to configure VMs and trigger Jenkins pipeline
```

## Architecture Overview

### Pipeline Flow
1. **User Interaction**: `launch_pipeline.sh` collects VM configuration (count, CPU, RAM, template)
2. **GitOps**: Script writes to `terraform.tfvars.json`, commits, and pushes
3. **Jenkins**: Pipeline triggered via REST API
4. **Validation**: Linting with tflint, security scanning with tfsec/checkov, OPA policy checks
5. **Deployment**: Terraform apply (only on main branch)
6. **Configuration**: Ansible runs post-deployment hardening

### Key Components
- **Terraform**: Infrastructure provisioning using Proxmox provider with modular VM design
- **OPA Policies**: Enforce constraints (e.g., max 8 vCPUs per VM) in `terraform/opa-policies/terraform.rego`
- **Ansible**: Post-deployment security hardening via `ansible/roles/harden/`
- **Jenkins**: Orchestrates the entire pipeline using declarative syntax

### Security Layers
1. Pre-deployment: tflint, tfsec, checkov scanning
2. Policy enforcement: OPA validates Terraform plans
3. Post-deployment: Ansible hardening role
4. Credentials: Managed through Jenkins credentials store

## Development Guidelines

When modifying infrastructure:
- Always test changes with `make lint` before committing
- VM configuration changes should be made through `terraform.tfvars.json`
- OPA policies in `terraform/opa-policies/terraform.rego` enforce security constraints
- The Jenkins pipeline only applies changes on the main branch

## Known Issues and Planned Fixes

### VM Boot/Network Connectivity Issues
**Problem**: VMs created via Terraform are not accessible via SSH, showing "Destination Host Unreachable" errors.

**Root Cause Analysis**:
- VM configuration shows correct static IP (192.168.178.100) in Proxmox
- VM status shows "running" but console shows "failed to connect to server"
- Cloud-init appears to be generating ISO but not completing successfully
- Template may have boot/disk configuration issues

**Planned Infrastructure Improvements**:

1. **VM Disk Configuration**:
   - Change from `scsihw = "lsi"` to `scsihw = "virtio-scsi-pci"` for better Ubuntu compatibility
   - Add explicit main disk configuration to prevent unused disk issues
   - Set proper boot order: `boot = "order=scsi0;ide2"`

2. **Cloud-Init Enhancements**:
   - Add `ciupgrade = true` to force cloud-init re-run on every boot
   - Increase `additional_wait = 30` for better boot timing
   - Consider inline cloud-init configuration instead of template dependency

3. **Jenkins Pipeline Improvements**:
   - Add VM health checks via Proxmox API before SSH attempts
   - Increase wait times for cloud-init completion (5-7 minutes instead of 2)
   - Add better debugging output for VM status

4. **Template Verification**:
   - Verify Ubuntu cloud template has proper cloud-init and qemu-guest-agent
   - Document template creation process for consistency
   - Consider switching to inline cloud-init configuration

**Alternative Solutions Considered**:
- Switch to DHCP (attempted but caused more complexity)
- Inline cloud-init configuration (files prepared but not implemented)
- Template recreation with verified configuration

**Current Status**: Infrastructure works for VM creation but network connectivity fails. Static IP configuration is correct but VMs don't complete boot process properly.



main.tf 

```
resource "proxmox_vm_qemu" "this" {
  count       = var.vm_count
  name        = "idp-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.vm_template
  full_clone  = true  # Ensure full clone for proper cloud-init
  clone_wait  = 30    # Wait for clone to complete

  cores   = var.vm_cpu
  sockets = 1
  memory  = var.vm_memory_mb

  # Enable QEMU Guest Agent for proper VM management
  agent = 1

  # Cloud-init settings
  os_type   = "cloud-init"
  ipconfig0 = "ip=${var.vm_ip_base}.${var.vm_ip_offset + count.index}/24,gw=${var.gateway}"
  nameserver = var.nameserver
  
  # Cloud-init user configuration
  ciuser     = var.cloud_init_user
  cipassword = var.cloud_init_password
  sshkeys    = chomp(var.ssh_public_key)  
  
  # Cloud-init will configure the user and SSH keys automatically

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Setup the disk using new disks block format
  disks {
    ide {
      ide3 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          size         = 30
          cache        = "writeback"
          storage      = "local-lvm"
          iothread     = true
          discard      = true
        }
      }
    }
  }
  
  # Remove custom cloud-init for now - Ubuntu cloud images should have guest agent
  
  # Ensure cloud-init runs on first boot
  qemu_os = "l26"
  
  # VM settings
  onboot = true
  tablet = false
  protection = true  # Prevent accidental deletion
  boot = "order=virtio0"
  
  # Ensure VM is running
  vm_state = "running"
  
  # Use static connection info
  define_connection_info = false

  lifecycle {
    ignore_changes = []
  }

  # Wait for cloud-init to complete
  additional_wait = 30
  ciupgrade = true
  
  # Add a null resource to wait for the VM to be fully ready
  provisioner "local-exec" {
    command = "sleep 120"  # Give VM time to boot and start services
  }
}
```