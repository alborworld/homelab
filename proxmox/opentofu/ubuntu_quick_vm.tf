## Quick and dirty Ubuntu VM
resource "proxmox_virtual_environment_vm" "ubuntu_quick_vm" {
  name      = "ubuntu-quick-vm"
  node_name = "nuc"

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "virtio0"
    size         = 20
    iothread     = true
    discard      = "on"
    file_format  = "raw"
  }

  cdrom {
    enabled      = true
    file_id      = "local:iso/ubuntu-23.10-live-server-amd64.iso"
  }

  network_device {
    bridge = "vmbr0"
  }

  started = true
}