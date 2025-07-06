# ───────────────────────────────────────────────────────────────
#  VM   idp-<n>  — Ubuntu cloud-init template clone
# ───────────────────────────────────────────────────────────────
resource "proxmox_vm_qemu" "this" {
  count       = var.vm_count
  name        = "idp-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.vm_template           # e.g. "ubuntu-cloud"
  full_clone  = true
  desc        = "Provisioned via Terraform & cloud-init"

  ###############
  # CPU & RAM
  ###############
  cores       = var.vm_cpu
  sockets     = 1
  memory      = var.vm_memory_mb          # 2048 in tfvars  [oai_citation:0‡terraform.tfvars.json](file-service://file-6UzEPi7S4TnLvC72hSEgA4)

  ###############
  # *Critical* hardware choices
  ###############
  agent       = 1                         # QEMU guest agent
  scsihw      = "virtio-scsi-pci"         # match template – avoids LSI driver issue
  boot        = "order=scsi0;ide2"        # boot disk first, cloud-init ISO second
  tablet      = false                     # no USB tablet
  onboot      = true

  ###############
  # Cloud-init
  ###############
  os_type     = "cloud-init"
  ipconfig0   = "ip=${var.vm_ip_base}.${var.vm_ip_offset + count.index}/24,gw=${var.gateway}"
  nameserver  = var.nameserver

  ciuser      = var.cloud_init_user
  cipassword  = var.cloud_init_password
  sshkeys     = chomp(var.ssh_public_key) # injected at boot

  # Optional: point at a custom user-data snippet you copied to /var/lib/vz/snippets
  # cicustom                = "user=local:snippets/user_data_vm-${count.index}.yml"
  # cloudinit_cdrom_storage = "local-lvm"

  ###############
  # Disks (cloud-init ISO on IDE2, real disk on SCSI0)
  ###############
  disks {
    ide {
      ide2 {                               # <- what Proxmox expects for cloud-init
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size      = 30
          storage   = "local-lvm"
          cache     = "writeback"
          iothread  = true
          discard   = true
        }
      }
    }
  }

  ###############
  # Network
  ###############
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  ###############
  # Console access
  ###############
  serial {                                # gives you “Console → Serial” in Proxmox
    id   = 0
    type = "socket"
  }
  vga { type = "std" }                    # also keeps the default VGA console

  ###############
  # Terraform book-keeping
  ###############
  lifecycle {
    ignore_changes = [
      network[0].macaddr,                 # don’t recreate when Proxmox regenerates MAC
    ]
  }

  # Give the VM a minute to finish cloud-init before the next stages run
  provisioner "local-exec" {
    command = "sleep 60"
  }
}