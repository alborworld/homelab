# Proxmox OpenTofu Stacks

Infrastructure as Code for Proxmox VE resources.

## Stacks

| Stack | Description | Provisioning |
|-------|-------------|--------------|
| [`tailscale-exit-nordvpn-nl/`](tailscale-exit-nordvpn-nl/) | Tailscale exit node via NordVPN Amsterdam | OpenTofu + Ansible |

## Structure

Each stack creates infrastructure; provisioning may be handled by Ansible:

```
tofu/proxmox/
└── tailscale-exit-nordvpn-nl/
    ├── main.tf              # LXC container + TUN config + SSH bootstrap
    ├── provider.tf          # Proxmox provider
    ├── backend.tf           # S3 state (Garage)
    ├── variables.tf         # Inputs
    ├── .env.template        # Secrets template
    └── README.md            # Stack documentation

ansible/roles/
├── exit_node_nordvpn/       # Provisioning (WireGuard, Tailscale, nftables)
└── beszel_agent/            # Monitoring agent
```

## Usage

### Infrastructure Only (OpenTofu)

```bash
cd tofu/proxmox/tailscale-exit-nordvpn-nl

# Decrypt secrets
make -C ../../.. tofu-decrypt STACK=proxmox/tailscale-exit-nordvpn-nl

# Deploy
source ../../scripts/tofu-env.sh
tofu init
tofu plan
tofu apply
rm .env
```

### With Ansible Provisioning

For stacks that use Ansible for configuration:

```bash
# 1. Create infrastructure with OpenTofu
cd tofu/proxmox/tailscale-exit-nordvpn-nl
source ../../scripts/tofu-env.sh
tofu apply

# 2. Provision with Ansible
cd ../../../ansible
ansible-playbook playbooks/exit-node-nordvpn.yml -e @secrets.yml
```

## Adding New Stacks

1. Create directory: `tofu/proxmox/my-new-stack/`
2. Add standard files: `main.tf`, `provider.tf`, `backend.tf`, `variables.tf`
3. Update backend key in `backend.tf` to unique path
4. Add `.env.template` for secrets
5. Add `README.md` with documentation
6. (Optional) Create Ansible role in `ansible/roles/` for provisioning
