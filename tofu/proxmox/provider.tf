terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.50.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "proxmox" {
  # Configuration options
  endpoint = var.proxmox_api_url

  # API token authentication
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"

  # Optional: Uncomment if you need to skip TLS verification (not recommended for production)
  insecure = true

  # Optional: Timeout settings
  # timeout = 300
}
