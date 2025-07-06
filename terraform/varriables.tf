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

#############################
# CLOUD-INIT PASSWORD
#############################
variable "cloud_init_password" {
  description = "Password for cloud-init user"
  type        = string
  sensitive   = true
}