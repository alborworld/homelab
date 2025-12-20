# Ansible Configuration

Ansible playbooks for provisioning and configuring homelab nodes.

## Structure

```
ansible/
├── ansible.cfg          # Ansible configuration
├── inventory.yml        # Host inventory
└── playbooks/
    └── tailscale.yml    # Tailscale subnet router setup
```

## Hosts

| Host         | Role                    |
|--------------|-------------------------|
| raspberrypi5 | Edge node, subnet router|
| diskstation  | NAS                     |
| dockerhost   | Proxmox VM              |

## Playbooks

### Tailscale Subnet Router

Installs Tailscale and configures it as a subnet router for remote access.

```bash
cd ansible
ansible-playbook playbooks/tailscale.yml
```

**Post-run:** Approve the advertised routes in the [Tailscale admin console](https://login.tailscale.com/admin/machines).
