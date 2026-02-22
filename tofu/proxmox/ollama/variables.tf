# Proxmox Connection
variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (e.g., user@realm!tokenname)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
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

# SSH Bootstrap
variable "ssh_public_key_path" {
  description = "Path to SSH public key on Proxmox host (for Ansible access)"
  type        = string
  default     = "/root/.ssh/id_rsa.pub"
}
