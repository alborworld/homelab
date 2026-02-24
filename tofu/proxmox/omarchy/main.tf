# Omarchy Desktop VM
# OpenTofu creates VM with Omarchy ISO attached; manual install via SPICE console
# Post-install: Ansible handles Tailscale + SSH access

locals {
  vmid        = 103
  hostname    = "omarchy"
  proxmox_ssh = "nuc13"
  iso_url     = "https://iso.omarchy.org/omarchy-3.3.2.iso"
  iso_file    = "omarchy-3.3.2.iso"
}

# ------------------------------------------------------------------------------
# Download Omarchy ISO to Proxmox
# ------------------------------------------------------------------------------

resource "proxmox_virtual_environment_download_file" "omarchy_iso" {
  content_type       = "iso"
  datastore_id       = "local"
  node_name          = var.proxmox_node
  url                = local.iso_url
  file_name          = local.iso_file
  checksum_algorithm = "sha256"
  checksum           = var.omarchy_iso_checksum
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
    file_id   = proxmox_virtual_environment_download_file.omarchy_iso.id
    interface = "ide2"
  }

  boot_order = ["ide2", "scsi0"]

  # SPICE display with VirtIO-GPU
  vga {
    type   = "virtio-gl"
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
