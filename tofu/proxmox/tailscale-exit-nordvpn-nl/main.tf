# Tailscale Exit Node via NordVPN Amsterdam
# OpenTofu creates LXC + TUN config; Ansible handles provisioning

locals {
  vmid            = 200
  hostname        = "exit-nordvpn-nl"
  alpine_template = "alpine-3.22-default_20250617_amd64.tar.xz"
  proxmox_ssh     = "nuc13"
}

# ------------------------------------------------------------------------------
# LXC Container
# ------------------------------------------------------------------------------

resource "proxmox_virtual_environment_container" "exit_node" {
  node_name     = var.proxmox_node
  vm_id         = local.vmid
  description   = "Tailscale exit node via NordVPN Amsterdam"
  tags          = ["tailscale", "exit-node", "nordvpn", "nl"]
  started       = true
  start_on_boot = true

  initialization {
    hostname = local.hostname
    ip_config {
      ipv4 { address = "dhcp" }
    }
  }

  unprivileged = false # Required for /dev/net/tun

  operating_system {
    template_file_id = "diskstation:vztmpl/${local.alpine_template}"
    type             = "alpine"
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 256
  }

  disk {
    datastore_id = "local-lvm"
    size         = 1
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
# TUN Device Configuration (required for WireGuard/Tailscale in LXC)
# Cannot be done via API token - requires SSH to Proxmox host
# ------------------------------------------------------------------------------

resource "null_resource" "tun_config" {
  depends_on = [proxmox_virtual_environment_container.exit_node]

  connection {
    type  = "ssh"
    user  = "root"
    host  = local.proxmox_ssh
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "pct set ${local.vmid} --features nesting=1",
      "grep -q 'lxc.cgroup2.devices.allow: c 10:200' /etc/pve/lxc/${local.vmid}.conf || echo 'lxc.cgroup2.devices.allow: c 10:200 rwm' >> /etc/pve/lxc/${local.vmid}.conf",
      "grep -q 'lxc.mount.entry: /dev/net/tun' /etc/pve/lxc/${local.vmid}.conf || echo 'lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file' >> /etc/pve/lxc/${local.vmid}.conf",
      "pct reboot ${local.vmid} || true",
      "sleep 10"
    ]
  }

  triggers = { container_id = proxmox_virtual_environment_container.exit_node.id }
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
      # Install and configure SSH
      "pct exec ${local.vmid} -- apk add --no-cache openssh",
      "pct exec ${local.vmid} -- rc-update add sshd default",
      "pct exec ${local.vmid} -- rc-service sshd start",
      # Add SSH key for Ansible access
      "pct exec ${local.vmid} -- mkdir -p /root/.ssh",
      "pct exec ${local.vmid} -- chmod 700 /root/.ssh",
      "pct push ${local.vmid} ${var.ssh_public_key_path} /root/.ssh/authorized_keys",
      "pct exec ${local.vmid} -- chmod 600 /root/.ssh/authorized_keys",
    ]
  }

  triggers = { tun_config = null_resource.tun_config.id }
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
  value       = proxmox_virtual_environment_container.exit_node.initialization[0].ip_config[0].ipv4[0].address
}
