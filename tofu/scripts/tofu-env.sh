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

# Alias PROXMOX_* to TF_VAR_proxmox_*
if [[ -n "${PROXMOX_ENDPOINT:-}" ]]; then
  export TF_VAR_proxmox_endpoint="$PROXMOX_ENDPOINT"
fi

if [[ -n "${PROXMOX_API_TOKEN_ID:-}" ]]; then
  export TF_VAR_proxmox_api_token_id="$PROXMOX_API_TOKEN_ID"
fi

if [[ -n "${PROXMOX_API_TOKEN_SECRET:-}" ]]; then
  export TF_VAR_proxmox_api_token_secret="$PROXMOX_API_TOKEN_SECRET"
fi

# Alias TAILSCALE_* to TF_VAR_tailscale_*
if [[ -n "${TAILSCALE_AUTHKEY:-}" ]]; then
  export TF_VAR_tailscale_authkey="$TAILSCALE_AUTHKEY"
fi

# Alias WIREGUARD_* to TF_VAR_wireguard_*
if [[ -n "${WIREGUARD_PRIVATE_KEY:-}" ]]; then
  export TF_VAR_wireguard_private_key="$WIREGUARD_PRIVATE_KEY"
fi

echo "OpenTofu environment configured"
