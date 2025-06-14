#############################
# REQUIRED AT RUNTIME
#############################
variable "vm_count"      { type = number }
variable "vm_cpu"        { type = number }
variable "vm_memory_mb"  { type = number }
variable "vm_template"   { type = string }

#############################
# PROXMOX CREDENTIALS
#############################
variable "pm_api_token_id"     { type = string }   # e.g. terraform@pve!terraform-token
variable "pm_api_token_secret" { type = string }   # the long secret string

#############################
# SSH KEYS FOR CLOUD-INIT
#############################
variable "ssh_public_key" {
  description = "SSH public key to inject into VMs via cloud-init"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for Terraform provisioners"
  type        = string
  default     = "~/.ssh/id_rsa"
}