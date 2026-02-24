# Omarchy Desktop VM
# Post-install: Ansible handles Tailscale + SSH access

locals {
  vmid     = 103
  hostname = "omarchy"
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

  boot_order = ["scsi0"]

  # VirtIO GPU for Wayland compatibility
  vga {
    type   = "virtio"
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
    ignore_changes = [started, cdrom]
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
