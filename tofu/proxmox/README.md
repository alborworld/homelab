# Proxmox OpenTofu Stacks

Infrastructure as Code for Proxmox VE resources.

## Stacks

| Stack | Description |
|-------|-------------|
| [`tailscale-exit-nordvpn-nl/`](tailscale-exit-nordvpn-nl/) | Tailscale exit node via NordVPN Amsterdam |

## Structure

Each stack is self-contained:

```
tofu/proxmox/
└── tailscale-exit-nordvpn-nl/
    ├── main.tf              # Resources
    ├── provider.tf          # Proxmox provider
    ├── backend.tf           # S3 state (Garage)
    ├── variables.tf         # Inputs
    ├── .env.template        # Secrets template
    ├── *.tpl, *.nft, *.sh   # Config templates
    └── README.md            # Stack documentation
```

## Usage

```bash
# Navigate to stack
cd tofu/proxmox/tailscale-exit-nordvpn-nl

# Setup secrets (first time)
cp .env.template .env
# Edit .env, then encrypt with sops

# Deploy
sops -d .env.sops.enc > .env
source ../../scripts/tofu-env.sh
tofu init
tofu plan
tofu apply
rm .env
```

## Adding New Stacks

1. Create directory: `tofu/proxmox/my-new-stack/`
2. Add standard files: `main.tf`, `provider.tf`, `backend.tf`, `variables.tf`
3. Update backend key in `backend.tf` to unique path
4. Add `.env.template` for secrets
5. Add `README.md` with documentation