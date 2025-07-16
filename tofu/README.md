# OpenTofu Configuration

This directory contains Tofu (Terraform) configurations for managing infrastructure as code in the homelab.

## Directory Structure

```
tofu/
├── cloudflare/        # Cloudflare infrastructure configuration
├── minio/             # MinIO S3 buckets configuration
├── proxmox/           # Proxmox infrastructure configuration
└── modules/           # Reusable Terraform modules
```

## Purpose

This directory contains Tofu (Terraform) configurations for managing different aspects of the homelab infrastructure:
- Cloudflare DNS and security settings
- Proxmox virtualization infrastructure
- Additional infrastructure configurations as needed

## Security Note

Sensitive information (API keys, credentials) should be encrypted using [SOPS](https://github.com/getsops/sops). Please refer to the [Secrets Management with SOPS](../docs/SECURITY.md#secrets-management-with-sops) section in the security documentation for encryption/decryption instructions.

## Usage

1. Initialize OpenTofu in any subdirectory (e.g., proxmox, minio, cloudflare):
   ```bash
   cd tofu/<subdirectory>
   tofu init
   ```

2. Plan the changes:
   ```bash
   tofu plan
   ```

3. Apply the configuration:
   ```bash
   tofu apply
   ```

## Adding New Configurations

To add a new Tofu configuration:
1. Create a new subdirectory under `tofu/`
2. Add your main.tf configuration
3. Create `variables.tf` and `outputs.tf` as needed
4. Add any required modules to the modules/ directory
5. Encrypt sensitive variables using [SOPS](https://github.com/getsops/sops)
