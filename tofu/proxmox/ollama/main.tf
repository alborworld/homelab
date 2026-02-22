# Ollama LLM Inference Server
# OpenTofu creates LXC; Ansible handles provisioning

locals {
  vmid             = 201
  hostname         = "ollama"
  ubuntu_template  = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  proxmox_ssh      = "nuc13"
}

# ------------------------------------------------------------------------------
# LXC Container
# ------------------------------------------------------------------------------

resource "proxmox_virtual_environment_container" "ollama" {
  node_name     = var.proxmox_node
  vm_id         = local.vmid
  description   = "Ollama LLM inference server"
  tags          = ["ollama", "ai", "tailscale"]
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
    cores = 4
  }

  memory {
    dedicated = 12288
  }

  disk {
    datastore_id = "local-lvm"
    size         = 30
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
# SSH Bootstrap (minimal setup for Ansible access)
# ------------------------------------------------------------------------------

resource "null_resource" "ssh_bootstrap" {
  depends_on = [proxmox_virtual_environment_container.ollama]

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

  triggers = { container_id = proxmox_virtual_environment_container.ollama.id }
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
  value       = proxmox_virtual_environment_container.ollama.initialization[0].ip_config[0].ipv4[0].address
}
