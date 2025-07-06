terraform {
  required_version = ">= 1.7.0"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc8"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://192.168.178.200:8006/api2/json"
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
}

module "vm" {
  source     = "./modules/vm"
  providers  = { proxmox = proxmox }

  vm_count     = var.vm_count
  vm_cpu       = var.vm_cpu
  vm_memory_mb = var.vm_memory_mb
  vm_template  = var.vm_template
  proxmox_node = "pve"
  
  # SSH keys for cloud-init
  ssh_public_key  = var.ssh_public_key
  
  # Cloud-init password from Jenkins
  cloud_init_password = var.cloud_init_password
}

# Outputs for Ansible integration
output "vm_ips" {
  value = module.vm.vm_ips
}

output "ansible_inventory" {
  value = module.vm.ansible_inventory
}

# Generate Ansible inventory file
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/ansible_inventory.tpl", {
    vms = module.vm.ansible_inventory
  })
  filename = "${path.module}/../ansible/hosts_dynamic.yml"
}