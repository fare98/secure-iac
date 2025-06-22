variable "vm_count"       { type = number }
variable "vm_cpu"         { type = number }
variable "vm_memory_mb"   { type = number }
variable "vm_template"    { type = string }
variable "proxmox_node"   { type = string }

# Network configuration
variable "vm_ip_base" {
  description = "Base IP address for VMs (e.g., 192.168.178)"
  type        = string
  default     = "192.168.178"
}

variable "vm_ip_offset" {
  description = "Starting IP offset for VMs"
  type        = number
  default     = 100
}

variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.178.1"
}

variable "nameserver" {
  description = "DNS nameserver"
  type        = string
  default     = "8.8.8.8"
}

# Cloud-init configuration
variable "cloud_init_user" {
  description = "Default user for cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key for cloud-init user"
  type        = string
}