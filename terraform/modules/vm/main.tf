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

  # Enable QEMU Guest Agent for better VM management
  agent = 1
  # Don't wait for agent during creation - we'll handle this in Jenkins
  agent_timeout = 0

  # Cloud-init settings
  os_type   = "cloud-init"
  ipconfig0 = "ip=dhcp"  # Use DHCP for automatic IP assignment
  nameserver = var.nameserver
  
  # Cloud-init user configuration
  ciuser     = var.cloud_init_user
  cipassword = "temp123"  # Temporary password for debugging (no special chars)
  sshkeys    = chomp(var.ssh_public_key)  # Remove any trailing newlines
  
  # Cloud-init will configure the user and SSH keys automatically

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Cloud-init drive
  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = "local-lvm"
  }
  
  # Remove custom cloud-init for now - Ubuntu cloud images should have guest agent
  
  # Ensure cloud-init runs on first boot
  qemu_os = "l26"
  
  # VM settings
  onboot = true
  tablet = false
  # boot = "order=scsi0;ide2;net0"  # Removed - let Proxmox handle boot order
  
  # Ensure VM is running
  vm_state = "running"
  
  # Allow provider to define connection info from QEMU guest agent
  define_connection_info = true

  lifecycle {
    ignore_changes = [disk]
  }

  # Add a null resource to wait for the VM to be fully ready
  provisioner "local-exec" {
    command = "sleep 30"  # Give VM time to boot and start services
  }
}