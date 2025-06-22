resource "proxmox_vm_qemu" "this" {
  count       = var.vm_count
  name        = "idp-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.vm_template

  cores   = var.vm_cpu
  sockets = 1
  memory  = var.vm_memory_mb

  # Enable QEMU Guest Agent for better VM management
  agent = 1

  # Cloud-init settings
  os_type   = "cloud-init"
  ipconfig0 = "ip=${var.vm_ip_base}.${var.vm_ip_offset + count.index}/24,gw=${var.gateway}"
  nameserver = var.nameserver
  
  # Cloud-init user configuration
  ciuser  = var.cloud_init_user
  sshkeys = var.ssh_public_key
  
  # Cloud-init will configure the user and SSH keys automatically

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Cloud-init drive (main disk comes from template)
  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = "local-lvm"
  }

  # Ensure VM starts after creation
  boot = "order=scsi0"
  onboot = true

  # Force replacement when cloud-init user changes
  lifecycle {
    ignore_changes = [disk]
    create_before_destroy = true
  }

  # Note: Connection block removed - cloud-init will handle initial setup
  # and Ansible will handle post-deployment configuration
}