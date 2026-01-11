# Cloudflare Infrastructure Stack

This stack manages Cloudflare DNS records and rulesets for alborworld.com using the [cloudflare/cloudflare](https://registry.terraform.io/providers/cloudflare/cloudflare) provider.

## Resources Managed

- **DNS Records**: A, CNAME, MX, TXT records for alborworld.com
- **Rulesets**: HTTP redirect (mail.alborworld.com → Gmail)

## Prerequisites

- Cloudflare API token with DNS edit permissions
- Secrets decrypted from `.env.sops.enc`

## Usage

```bash
cd tofu/cloudflare

# Decrypt secrets
make -C ../.. tofu-decrypt STACK=cloudflare

# Source environment (aliases TOFU_* to AWS_*)
source ../scripts/tofu-env.sh

# Run tofu commands
tofu plan
tofu apply
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token |
| `CLOUDFLARE_ZONE_ID` | Zone ID for alborworld.com |
| `TOFU_KEY_ID` | S3 access key ID |
| `TOFU_KEY_SECRET` | S3 secret access key |
