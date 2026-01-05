# Ansible Configuration

Ansible playbooks and roles for provisioning and configuring homelab nodes.

## Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory.yml            # Host inventory
├── secrets.yml.template     # Secrets template (copy to secrets.yml)
├── playbooks/
│   ├── tailscale.yml        # Tailscale subnet router setup
│   └── exit-node-nordvpn.yml # NordVPN exit node provisioning
└── roles/
    ├── exit_node_nordvpn/   # Tailscale exit node via NordVPN
    └── beszel_agent/        # Beszel monitoring agent
```

## Host Groups

| Group | Hosts | Purpose |
|-------|-------|---------|
| `homelab` | raspberrypi5, diskstation, dockerhost | General homelab nodes |
| `tailscale_subnet_routers` | raspberrypi5 | Tailscale subnet routers |
| `exit_nodes` | exit-nordvpn-nl | Tailscale exit nodes via VPN |

## Playbooks

### Tailscale Subnet Router

Installs Tailscale and configures it as a subnet router for remote access.

```bash
cd ansible
ansible-playbook playbooks/tailscale.yml
```

**Post-run:** Approve the advertised routes in the [Tailscale admin console](https://login.tailscale.com/admin/machines).

### NordVPN Exit Node

Provisions a Tailscale exit node that routes traffic through NordVPN. Requires LXC container created via OpenTofu first.

```bash
cd ansible

# Create secrets file
cp secrets.yml.template secrets.yml
# Edit with wireguard_private_key and tailscale_authkey

# Run playbook
ansible-playbook playbooks/exit-node-nordvpn.yml -e @secrets.yml
```

**Post-run:** Approve the exit node in [Tailscale admin console](https://login.tailscale.com/admin/machines).

See [`tofu/proxmox/tailscale-exit-nordvpn-nl/README.md`](../tofu/proxmox/tailscale-exit-nordvpn-nl/README.md) for full documentation.

## Roles

### exit_node_nordvpn

Provisions a Tailscale exit node that routes traffic through NordVPN WireGuard.

**Required variables:**
- `wireguard_private_key` - NordVPN WireGuard private key
- `tailscale_authkey` - Tailscale auth key with exit node capability

### beszel_agent

Installs the [Beszel](https://beszel.dev) lightweight monitoring agent.

**Required variables:**
- `beszel_agent_key` - SSH public key from Beszel hub

**Optional variables:**
- `beszel_agent_port` - Port to listen on (default: 45876)

**Usage:**
```yaml
roles:
  - beszel_agent
```

The role downloads the latest beszel-agent binary, creates an OpenRC service, and starts the agent listening on the configured port.

## Secrets Management

Sensitive variables (API keys, auth tokens) should be stored in `secrets.yml`:

```bash
# Create from template
cp secrets.yml.template secrets.yml

# Optionally encrypt with ansible-vault
ansible-vault encrypt secrets.yml

# Use with playbooks
ansible-playbook playbooks/exit-node-nordvpn.yml -e @secrets.yml --ask-vault-pass
```
