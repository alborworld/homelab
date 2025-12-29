# Garage S3 Infrastructure Stack

This stack manages Garage S3 resources for OpenTofu state storage using the [jkossis/garage](https://registry.terraform.io/providers/jkossis/garage) provider.

## Resources Managed

- **garage_key.tofu**: Access credentials for OpenTofu state operations
- **garage_bucket_permission.tofu_tfstate**: Read/write permissions on the tfstate bucket

## Prerequisites

1. Garage S3 running at `https://s3.home.alborworld.com`
2. Admin API exposed at `https://admin.s3.home.alborworld.com`
3. `tfstate` bucket already exists in Garage
4. GARAGE_ADMIN_TOKEN available (in `docker/diskstation/.env.sops.enc`)
5. Existing TOFU_KEY_ID and TOFU_KEY_SECRET to import

## Bootstrap Process

This stack has a chicken-and-egg problem: it needs S3 credentials to store its state, but it manages those credentials. Follow these steps:

### Step 1: Prepare Environment

```bash
cd tofu/garage

# Create .env from template
cp .env.template .env

# Get GARAGE_ADMIN_TOKEN from diskstation secrets
make -C ../.. show-diskstation | grep GARAGE_ADMIN_TOKEN

# Fill in .env with:
# - GARAGE_ADMIN_TOKEN
# - TOFU_KEY_ID (your existing key)
# - TOFU_KEY_SECRET (your existing secret)
```

### Step 2: Initialize and Import

```bash
# Source environment
source ../scripts/tofu-env.sh

# Initialize (uses local state initially)
tofu init

# Import existing key
TF_VAR_garage_admin_token="$GARAGE_ADMIN_TOKEN" \
TF_VAR_tofu_key_id="$TOFU_KEY_ID" \
  tofu import garage_key.tofu "$TOFU_KEY_ID"

# Plan and apply
tofu plan
tofu apply
```

### Step 3: Migrate to S3 Backend

```bash
# Edit backend.tf and uncomment the backend "s3" block

# Migrate state to S3
tofu init -migrate-state

# Confirm migration when prompted
```

### Step 4: Encrypt and Commit

```bash
# Encrypt secrets
make -C ../.. tofu-encrypt-garage

# Commit changes
git add .env.sops.enc backend.tf
git commit -m "feat(tofu): bootstrap garage stack with S3 backend"
```

## Daily Usage

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
