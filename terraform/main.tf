terraform {
  required_version = ">= 1.7.0"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://192.168.178.10:8006/api2/json"   # adjust if Proxmox IP differs
  pm_api_token_id     = "proxmox-token"
  pm_api_token_secret = "root@pam!terraform=8e2529e9-7207-4468-a8d0-4817be5601d"
  pm_tls_insecure     = true
}

module "vm" {
  source         = "./modules/vm"
  vm_count       = var.vm_count
  vm_cpu         = var.vm_cpu
  vm_memory_mb   = var.vm_memory_mb
  vm_template    = var.vm_template
  proxmox_node   = "pve"
}