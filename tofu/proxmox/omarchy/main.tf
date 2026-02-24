# Omarchy Desktop VM
# OpenTofu creates VM with Omarchy ISO attached; manual install via SPICE console
# Post-install: Ansible handles Tailscale + SSH access
#
# Prerequisites:
#   Download Omarchy ISO to diskstation before applying:
#   ssh nuc13 "wget -O /mnt/pve/diskstation/template/iso/omarchy-3.3.2.iso https://iso.omarchy.org/omarchy-3.3.2.iso"

locals {
  vmid     = 103
  hostname = "omarchy"
  iso_id   = "diskstation:iso/omarchy-3.3.2.iso"
}

# ------------------------------------------------------------------------------
# VM
# ------------------------------------------------------------------------------

resource "proxmox_virtual_environment_vm" "omarchy" {
  node_name   = var.proxmox_node
  vm_id       = local.vmid
  name        = local.hostname
  description = "Omarchy desktop (Sway + dev tools)"
  tags        = ["omarchy", "desktop", "tailscale"]
  on_boot     = false
  started     = true

  # Hardware
  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 8192
  }

  # Boot disk
  disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    interface    = "scsi0"
    iothread     = true
    size         = 50
  }

  scsi_hardware = "virtio-scsi-single"

  # Install ISO
  cdrom {
    file_id   = local.iso_id
    interface = "ide2"
  }

  boot_order = ["ide2", "scsi0"]

  # SPICE display with QXL
  vga {
    type   = "qxl"
    memory = 128
  }

  # Networking
  network_device {
    bridge = "vmbr0"
  }

  # QEMU guest agent
  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [started]
  }
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

output "vmid" {
  description = "VM ID"
  value       = local.vmid
}

output "hostname" {
  description = "VM hostname"
  value       = local.hostname
}
