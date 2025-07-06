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