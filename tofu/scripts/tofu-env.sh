#!/usr/bin/env bash
# Source this file to set up OpenTofu environment variables
# Usage: source tofu-env.sh
#
# This script:
# 1. Loads variables from .env file if present
# 2. Aliases TOFU_KEY_* to AWS_* for S3 backend compatibility

# Load from .env file if present in current directory
if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

# Alias TOFU_* to AWS_* for S3 backend compatibility
# OpenTofu's S3 backend expects AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
if [[ -n "${TOFU_KEY_ID:-}" ]]; then
  export AWS_ACCESS_KEY_ID="$TOFU_KEY_ID"
fi

if [[ -n "${TOFU_KEY_SECRET:-}" ]]; then
  export AWS_SECRET_ACCESS_KEY="$TOFU_KEY_SECRET"
fi

echo "OpenTofu environment configured"
