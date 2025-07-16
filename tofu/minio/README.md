# MinIO S3 Bucket Configuration

This directory contains OpenTofu configurations for managing S3 buckets in a MinIO object storage server.

## Directory Structure

```
minio/
├── provider.tf          # MinIO provider configuration
├── variables.tf         # Input variables for MinIO configuration
├── tstate_bucket.tf     # S3 bucket for Terraform state storage
└── tfstate_policy.json  # IAM policy for the state bucket
```

## Purpose

This configuration manages S3 buckets in a MinIO server, specifically:
- Creates and configures S3 buckets
- Manages bucket versioning
- Applies IAM bucket policies
- Configured for use as a Terraform backend for state storage

## Configuration

### Required Variables
- `minio_server`: MinIO server endpoint (e.g., "minio.example.com:9000")
- `minio_user`: MinIO access key or username
- `minio_password`: MinIO secret key or password

### Optional Variables
- `minio_region`: MinIO region (default: "main")
- `minio_api_version`: MinIO API version (default: "v4")
- `minio_ssl`: Enable SSL/TLS (default: false)

## Usage

1. Initialize OpenTofu:
   ```bash
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

## Security Note

Sensitive credentials (minio_user and minio_password) should be provided through environment variables or a secure secrets management system.
