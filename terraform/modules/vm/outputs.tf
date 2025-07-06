output "vm_names" {
  value = proxmox_vm_qemu.this[*].name
}

output "vm_ids" {
  description = "Proxmox VM IDs"
  value = proxmox_vm_qemu.this[*].vmid
}

output "vm_ips" {
  description = "IP addresses of created VMs (DHCP assigned)"
  value = proxmox_vm_qemu.this[*].default_ipv4_address
}

output "ansible_inventory" {
  description = "Ansible inventory configuration"
  value = {
    for i in range(var.vm_count) : 
    proxmox_vm_qemu.this[i].name => {
      ansible_host = proxmox_vm_qemu.this[i].default_ipv4_address
      ansible_user = var.cloud_init_user
    }
  }
}
