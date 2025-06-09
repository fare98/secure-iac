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

  disk {
    slot    = "scsi0"
    type    = "disk"
    storage = "local-lvm"
    size    = "20G"
  }

  # Cloud-init drive
  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = "local-lvm"
  }

  # Ensure VM starts after creation
  boot = "order=scsi0"
  onboot = true

  # Wait for cloud-init to complete
  lifecycle {
    ignore_changes = [disk[1]]
  }

  # Connection settings for provisioners
  connection {
    type        = "ssh"
    user        = var.cloud_init_user
    private_key = var.ssh_private_key
    host        = "${var.vm_ip_base}.${var.vm_ip_offset + count.index}"
  }

  # Wait for cloud-init to finish
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
  }
}