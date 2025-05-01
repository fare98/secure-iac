resource "proxmox_vm_qemu" "this" {
  count       = var.vm_count
  name        = "idp-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.vm_template

  cpu     = var.vm_cpu
  cores   = var.vm_cpu
  sockets = 1
  memory  = var.vm_memory_mb

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  disk {
    slot    = 0
    type    = "scsi"
    storage = "local-lvm"
    size    = "20G"
  }
}