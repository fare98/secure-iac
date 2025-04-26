output "vm_names" {
  value = proxmox_vm_qemu.this[*].name
}
