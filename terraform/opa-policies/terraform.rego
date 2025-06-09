package terraform.analysis

# CPU limits - prevent excessive resource allocation
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "proxmox_vm_qemu"
  resource.change.after.cores > 8
  msg = sprintf("VM '%s' has %d cores, but maximum allowed is 8", [resource.name, resource.change.after.cores])
}

# Memory limits - prevent excessive memory allocation (max 16GB)
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "proxmox_vm_qemu"
  resource.change.after.memory > 16384
  msg = sprintf("VM '%s' has %dMB memory, but maximum allowed is 16384MB (16GB)", [resource.name, resource.change.after.memory])
}

# Minimum resources - ensure VMs have adequate resources
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "proxmox_vm_qemu"
  resource.change.after.cores < 1
  msg = sprintf("VM '%s' must have at least 1 core", [resource.name])
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "proxmox_vm_qemu"
  resource.change.after.memory < 512
  msg = sprintf("VM '%s' must have at least 512MB memory", [resource.name])
}

# VM count limit - prevent accidental mass provisioning
deny[msg] {
  vm_count := count([1 | 
    resource := input.resource_changes[_]
    resource.type == "proxmox_vm_qemu"
    resource.change.actions[_] == "create"
  ])
  vm_count > 10
  msg = sprintf("Attempting to create %d VMs, but maximum allowed in a single deployment is 10", [vm_count])
}

# Disk size validation - ensure reasonable disk sizes
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "proxmox_vm_qemu"
  disk := resource.change.after.disk[_]
  disk_size := to_number(trim_suffix(disk.size, "G"))
  disk_size > 500
  msg = sprintf("VM '%s' has a %sB disk, but maximum allowed is 500GB", [resource.name, disk.size])
}

# Network validation - ensure VMs use approved bridges
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "proxmox_vm_qemu"
  network := resource.change.after.network[_]
  not network.bridge in ["vmbr0", "vmbr1", "vmbr2"]
  msg = sprintf("VM '%s' uses network bridge '%s', but only vmbr0, vmbr1, and vmbr2 are allowed", [resource.name, network.bridge])
}

# Template validation - ensure only approved templates are used
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "proxmox_vm_qemu"
  clone_template := resource.change.after.clone
  not clone_template in ["server", "ubuntu-22.04-template", "debian-12-template", "rocky-9-template"]
  msg = sprintf("VM '%s' uses template '%s', but only approved templates are allowed: server, ubuntu-22.04-template, debian-12-template, rocky-9-template", [resource.name, clone_template])
} 
