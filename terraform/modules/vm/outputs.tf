output "vm_names" {
  value = proxmox_vm_qemu.this[*].name
}

output "vm_ids" {
  description = "Proxmox VM IDs"
  value = proxmox_vm_qemu.this[*].vmid
}

output "vm_ips" {
  description = "IP addresses of created VMs"
  value = [
    for i in range(var.vm_count) : 
    "${var.vm_ip_base}.${var.vm_ip_offset + i}"
  ]
}

output "ansible_inventory" {
  description = "Ansible inventory configuration"
  value = {
    for i in range(var.vm_count) : 
    proxmox_vm_qemu.this[i].name => {
      ansible_host = "${var.vm_ip_base}.${var.vm_ip_offset + i}"
      ansible_user = var.cloud_init_user
    }
  }
}
