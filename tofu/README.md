# OpenTofu Configuration

This directory contains OpenTofu (Terraform) configurations for managing infrastructure as code in the homelab.

## Directory Structure

```
tofu/
├── cloudflare/        # Cloudflare DNS and security settings
├── garage/            # Garage S3 infrastructure (state storage credentials)
├── proxmox/           # Proxmox virtualization infrastructure
├── modules/           # Reusable Terraform modules
└── scripts/           # Helper scripts
    └── tofu-env.sh    # Environment setup script
```

## State Storage

All stacks store their state in Garage S3 at `https://s3.home.alborworld.com` in the `tfstate` bucket.

### S3 Backend Configuration

Add this to your stack's `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket                      = "tfstate"
    key                         = "alborworld/<STACK_NAME>.tfstate"
    region                      = "garage"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
    use_lockfile                = true
    endpoints = {
      s3 = "https://s3.home.alborworld.com"
    }
  }
}
```

## Credentials Setup

OpenTofu's S3 backend expects `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`. We use custom names (`TOFU_KEY_ID` and `TOFU_KEY_SECRET`) and alias them at runtime.

### Setting Up Credentials

1. Decrypt your stack's secrets:
   ```bash
   make tofu-decrypt-<stack>
   ```

2. Source the environment script:
   ```bash
   cd tofu/<stack>
   source ../scripts/tofu-env.sh
   ```

This loads variables from `.env` and aliases `TOFU_KEY_*` to `AWS_*`.

### Secrets Management

Each stack can have encrypted secrets in `.env.sops.enc`:

```bash
# Decrypt secrets
make tofu-decrypt-garage

# Encrypt after changes
make tofu-encrypt-garage

# View without writing to disk
make tofu-show-garage

# Clean up decrypted file
make tofu-clean-garage
```

## Usage

1. Decrypt secrets and set up environment:
   ```bash
   cd tofu/<stack>
   make -C ../.. tofu-decrypt-<stack>
   source ../scripts/tofu-env.sh
   ```

2. Initialize:
   ```bash
   tofu init
   ```

3. Plan changes:
   ```bash
   tofu plan
   ```

4. Apply changes:
   ```bash
   tofu apply
   ```

## Adding New Stacks

1. Create a new subdirectory under `tofu/`
2. Add required files:
   - `provider.tf` - Provider configuration
   - `variables.tf` - Input variables
   - `main.tf` - Resources
   - `outputs.tf` - Output values
   - `backend.tf` - S3 backend configuration
   - `.env.template` - Template for secrets
3. Copy the S3 backend configuration, updating the `key` path
4. Create `.env` from template and encrypt with `make tofu-encrypt-<stack>`

## Stacks

| Stack | Purpose | Provider |
|-------|---------|----------|
| `garage/` | S3 credentials and permissions | [jkossis/garage](https://registry.terraform.io/providers/jkossis/garage) |
| `cloudflare/` | DNS records and security rules | hashicorp/cloudflare |
| `proxmox/` | VMs and containers | bpg/proxmox |
