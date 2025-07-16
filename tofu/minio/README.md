# MinIO S3 Buckets Configuration

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
