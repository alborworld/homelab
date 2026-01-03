# Proxmox Connection
variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL (e.g., https://pve.home.alborworld.com)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (e.g., user@realm!tokenname)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret (UUID)"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "nuc13"
}

# Tailscale
variable "tailscale_authkey" {
  description = "Tailscale auth key (reusable, with exit node capability)"
  type        = string
  sensitive   = true
}

# NordVPN WireGuard
variable "wireguard_private_key" {
  description = "NordVPN WireGuard private key"
  type        = string
  sensitive   = true
}

variable "nordvpn_endpoint" {
  description = "NordVPN WireGuard server endpoint"
  type        = string
  default     = "nl1092.nordvpn.com:51820"
}

variable "nordvpn_public_key" {
  description = "NordVPN WireGuard server public key"
  type        = string
  default     = "5p4RkybdRU5uaDi90eu4KZPTFif0lKCg4Qp6t1c4F30="
}
