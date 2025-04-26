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
  pm_api_url          = "https://<PROXMOX_HOST>:8006/api2/json"
  pm_api_token_id     = "<TOKEN_ID>"
  pm_api_token_secret = "<TOKEN_SECRET>"
  pm_tls_insecure     = true
}

module "vm" {
  source         = "../../modules/vm"
  vm_count       = var.vm_count
  vm_cpu         = var.vm_cpu
  vm_memory_mb   = var.vm_memory_mb
  vm_template    = var.vm_template
  proxmox_node   = "pve"
}
