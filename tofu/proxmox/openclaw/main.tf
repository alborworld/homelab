# OpenClaw AI Assistant
# OpenTofu creates LXC; Ansible handles provisioning

locals {
  vmid             = 202
  hostname         = "openclaw"
  ubuntu_template  = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  proxmox_ssh      = "nuc13"
}

# ------------------------------------------------------------------------------
# LXC Container
# ------------------------------------------------------------------------------

resource "proxmox_virtual_environment_container" "openclaw" {
  node_name     = var.proxmox_node
  vm_id         = local.vmid
  description   = "OpenClaw AI assistant"
  tags          = ["openclaw", "ai", "tailscale"]
  started       = true
  start_on_boot = true

  initialization {
    hostname = local.hostname
    ip_config {
      ipv4 { address = "dhcp" }
    }
  }

  unprivileged = true

  features {
    nesting = true # Required for systemd in LXC
  }

  operating_system {
    template_file_id = "diskstation:vztmpl/${local.ubuntu_template}"
    type             = "ubuntu"
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [started]
  }
}

# ------------------------------------------------------------------------------
# TUN Device Configuration (required for Tailscale in LXC)
# Cannot be done via API token - requires SSH to Proxmox host
# ------------------------------------------------------------------------------

resource "null_resource" "tun_config" {
  depends_on = [proxmox_virtual_environment_container.openclaw]

  connection {
    type  = "ssh"
    user  = "root"
    host  = local.proxmox_ssh
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "grep -q 'lxc.cgroup2.devices.allow: c 10:200' /etc/pve/lxc/${local.vmid}.conf || echo 'lxc.cgroup2.devices.allow: c 10:200 rwm' >> /etc/pve/lxc/${local.vmid}.conf",
      "grep -q 'lxc.mount.entry: /dev/net/tun' /etc/pve/lxc/${local.vmid}.conf || echo 'lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file' >> /etc/pve/lxc/${local.vmid}.conf",
      "pct reboot ${local.vmid} || true",
      "sleep 10"
    ]
  }

  triggers = { container_id = proxmox_virtual_environment_container.openclaw.id }
}

# ------------------------------------------------------------------------------
# SSH Bootstrap (minimal setup for Ansible access)
# ------------------------------------------------------------------------------

resource "null_resource" "ssh_bootstrap" {
  depends_on = [null_resource.tun_config]

  connection {
    type  = "ssh"
    user  = "root"
    host  = local.proxmox_ssh
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "pct exec ${local.vmid} -- apt-get update -qq",
      "pct exec ${local.vmid} -- apt-get install -y -qq openssh-server",
      "pct exec ${local.vmid} -- systemctl enable ssh",
      "pct exec ${local.vmid} -- systemctl start ssh",
      "pct exec ${local.vmid} -- mkdir -p /root/.ssh",
      "pct exec ${local.vmid} -- chmod 700 /root/.ssh",
      "pct push ${local.vmid} ${var.ssh_public_key_path} /root/.ssh/authorized_keys",
      "pct exec ${local.vmid} -- chmod 600 /root/.ssh/authorized_keys",
    ]
  }

  triggers = { container_id = proxmox_virtual_environment_container.openclaw.id }
}

# ------------------------------------------------------------------------------
# Outputs (for Ansible inventory)
# ------------------------------------------------------------------------------

output "vmid" {
  description = "LXC VM ID"
  value       = local.vmid
}

output "hostname" {
  description = "Container hostname"
  value       = local.hostname
}

output "ip_address" {
  description = "Container IP address (from DHCP)"
  value       = proxmox_virtual_environment_container.openclaw.initialization[0].ip_config[0].ipv4[0].address
}
