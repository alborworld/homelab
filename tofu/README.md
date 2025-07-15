# Tofu Configuration Directory

This directory contains Tofu (Terraform) configurations for managing infrastructure as code in the homelab.

## Directory Structure

```
tofu/
├── cloudflare/         # Cloudflare infrastructure configuration
│   ├── main.tf        # Main Terraform configuration
│   ├── variables.tf   # Input variables
│   └── outputs.tf     # Output values
├── proxmox/           # Proxmox infrastructure configuration
│   ├── main.tf        # Main Terraform configuration
│   ├── variables.tf   # Input variables
│   └── outputs.tf     # Output values
└── modules/           # Reusable Terraform modules
```

## Purpose

This directory contains Tofu (Terraform) configurations for managing different aspects of the homelab infrastructure:
- Cloudflare DNS and security settings
- Proxmox virtualization infrastructure
- Additional infrastructure configurations as needed

## Security Note

Sensitive information (API keys, credentials) should be encrypted using SOPS. See the repository's root Makefile for encryption/decryption instructions.

## Usage

1. Initialize Tofu:
   ```bash
   cd tofu/cloudflare
   tofu init
   ```

2. Plan changes:
   ```bash
   tofu plan
   ```

3. Apply changes:
   ```bash
   tofu apply
   ```

## Adding New Configurations

To add a new Tofu configuration:
1. Create a new subdirectory under `tofu/`
2. Add your main.tf configuration
3. Create variables.tf and outputs.tf as needed
4. Add any required modules to the modules/ directory
5. Encrypt sensitive variables using SOPS

## License

See the [LICENSE](../LICENSE) file for details.