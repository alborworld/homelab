# Tailscale Exit Node via NordVPN Amsterdam
# Alpine LXC that routes Tailscale exit traffic through NordVPN WireGuard

locals {
  vmid            = 200
  hostname        = "exit-nordvpn-nl"
  alpine_template = "alpine-3.22-default_20250617_amd64.tar.xz"
  proxmox_ssh     = "nuc13" # SSH alias for Proxmox host
}

# ------------------------------------------------------------------------------
# LXC Container
# ------------------------------------------------------------------------------

resource "proxmox_virtual_environment_container" "exit_node" {
  node_name     = var.proxmox_node
  vm_id         = local.vmid
  description   = "Tailscale exit node routing traffic through NordVPN Amsterdam"
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

  # NOTE: Cannot set features via API token - requires root@pam password auth
  # Features (nesting) will be added via SSH in null_resource.tun_config

  operating_system {
    template_file_id = "diskstation:vztmpl/${local.alpine_template}"
    type             = "alpine"
  }

  cpu { cores = 1 }
  memory { dedicated = 256 }
  disk { datastore_id = "local-lvm"; size = 4 }
  network_interface { name = "eth0"; bridge = "vmbr0" }

  lifecycle { ignore_changes = [started] }
}

# ------------------------------------------------------------------------------
# TUN Device Configuration
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
# Provisioning
# ------------------------------------------------------------------------------

resource "null_resource" "provision" {
  depends_on = [null_resource.tun_config]

  connection {
    type  = "ssh"
    user  = "root"
    host  = local.proxmox_ssh
    agent = true
  }

  # Copy all config files to Proxmox host
  provisioner "file" {
    content = templatefile("${path.module}/wireguard.conf.tpl", {
      private_key = var.wireguard_private_key
      public_key  = var.nordvpn_public_key
      endpoint    = var.nordvpn_endpoint
    })
    destination = "/tmp/wg0.conf"
  }

  provisioner "file" {
    source      = "${path.module}/nftables.nft"
    destination = "/tmp/exit-node.nft"
  }

  provisioner "file" {
    source      = "${path.module}/health-check.sh"
    destination = "/tmp/health-check.sh"
  }

  provisioner "file" {
    source      = "${path.module}/auto-upgrade.sh"
    destination = "/tmp/auto-upgrade.sh"
  }

  provisioner "file" {
    source      = "${path.module}/setup.sh"
    destination = "/tmp/setup.sh"
  }

  # Push files into container and run setup
  provisioner "remote-exec" {
    inline = [
      # Push config files
      "pct push ${local.vmid} /tmp/wg0.conf /etc/wireguard/wg0.conf",
      "pct push ${local.vmid} /tmp/exit-node.nft /etc/nftables.d/exit-node.nft --mkdir",
      "pct push ${local.vmid} /tmp/health-check.sh /usr/local/bin/health-check.sh --mkdir",
      "pct push ${local.vmid} /tmp/auto-upgrade.sh /etc/periodic/weekly/auto-upgrade --mkdir",
      "pct push ${local.vmid} /tmp/setup.sh /tmp/setup.sh",

      # Run setup
      "pct exec ${local.vmid} -- sh /tmp/setup.sh '${var.tailscale_authkey}'",

      # Cleanup
      "rm -f /tmp/wg0.conf /tmp/exit-node.nft /tmp/health-check.sh /tmp/auto-upgrade.sh /tmp/setup.sh",
    ]
  }

  triggers = {
    tun_config       = null_resource.tun_config.id
    nordvpn_endpoint = var.nordvpn_endpoint
    setup_hash       = filemd5("${path.module}/setup.sh")
    nftables_hash    = filemd5("${path.module}/nftables.nft")
    healthcheck_hash = filemd5("${path.module}/health-check.sh")
    autoupgrade_hash = filemd5("${path.module}/auto-upgrade.sh")
  }
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

output "vmid" {
  description = "LXC VM ID"
  value       = local.vmid
}

output "hostname" {
  description = "Tailscale hostname"
  value       = local.hostname
}
