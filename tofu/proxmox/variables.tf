variable "proxmox_api_url" {
  description = "The URL of the Proxmox API (e.g., https://proxmox-server:8006/api2/json)"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_id" {
  description = "The Proxmox API token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "The Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_datastore_name" {
  description = "The name of the Proxmox datastore"
  type        = string
  default     = "diskstation"
}

variable "proxmox_node_name" {
  description = "The name of the Proxmox node"
  type        = string
  default     = "nuc13"
}
