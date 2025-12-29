# Garage S3 Infrastructure Stack

This stack manages Garage S3 resources for OpenTofu state storage using the [jkossis/garage](https://registry.terraform.io/providers/jkossis/garage) provider.

## Resources Managed

- **garage_key.tofu**: Access credentials for OpenTofu state operations (`opentofu-state`)
- **garage_bucket_permission.tofu_tfstate**: Read/write/owner permissions on the tfstate bucket

## Prerequisites

- Garage S3 running at `https://s3.home.alborworld.com`
- Admin API exposed at `https://admin.s3.home.alborworld.com`
- Secrets decrypted from `.env.sops.enc`

## State Locking

S3-native state locking is enabled via `use_lockfile = true`. Garage supports conditional writes (`If-None-Match` header), so concurrent operations will fail safely instead of corrupting state.

## Usage

```bash
cd tofu/garage

# Decrypt secrets
make -C ../.. tofu-decrypt-garage

# Source environment (aliases TOFU_* to AWS_*)
source ../scripts/tofu-env.sh

# Run tofu commands
tofu plan
tofu apply
```

## Environment Variables

| Variable | Description | Source |
|----------|-------------|--------|
| `GARAGE_ADMIN_TOKEN` | Admin API authentication | `docker/diskstation/.env` |
| `TOFU_KEY_ID` | S3 access key ID | Garage key |
| `TOFU_KEY_SECRET` | S3 secret access key | Garage key |

The `tofu-env.sh` script aliases `TOFU_KEY_ID` → `AWS_ACCESS_KEY_ID` and `TOFU_KEY_SECRET` → `AWS_SECRET_ACCESS_KEY` for S3 backend compatibility.
