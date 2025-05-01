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