#!/usr/bin/env bash
# Source this file to set up OpenTofu environment variables
# Usage: source tofu-env.sh
#
# This script:
# 1. Loads variables from .env file if present
# 2. Aliases variables to TF_VAR_* and AWS_* as needed

# Load from .env file if present in current directory
if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

# Alias TOFU_* to AWS_* for S3 backend compatibility
if [[ -n "${TOFU_KEY_ID:-}" ]]; then
  export AWS_ACCESS_KEY_ID="$TOFU_KEY_ID"
fi

if [[ -n "${TOFU_KEY_SECRET:-}" ]]; then
  export AWS_SECRET_ACCESS_KEY="$TOFU_KEY_SECRET"
fi

# Alias CLOUDFLARE_* to TF_VAR_cloudflare_*
if [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  export TF_VAR_cloudflare_api_token="$CLOUDFLARE_API_TOKEN"
fi

if [[ -n "${CLOUDFLARE_ZONE_ID:-}" ]]; then
  export TF_VAR_cloudflare_zone_id="$CLOUDFLARE_ZONE_ID"
fi

echo "OpenTofu environment configured"
