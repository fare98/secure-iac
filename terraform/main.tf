terraform {
  required_version = ">= 1.7.0"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.9"
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
}