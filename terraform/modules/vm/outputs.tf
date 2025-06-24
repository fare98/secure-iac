output "vm_names" {
  value = proxmox_vm_qemu.this[*].name
}

output "vm_ids" {
  description = "Proxmox VM IDs"
  value = proxmox_vm_qemu.this[*].vmid
}

output "vm_ips" {
  description = "IP addresses of created VMs retrieved from QEMU Guest Agent"
  value = [
    for vm in proxmox_vm_qemu.this : 
    vm.default_ipv4_address
  ]
}

output "ansible_inventory" {
  description = "Ansible inventory configuration"
  value = {
    for vm in proxmox_vm_qemu.this : 
    vm.name => {
      ansible_host = vm.default_ipv4_address
      ansible_user = var.cloud_init_user
    }
  }
}
