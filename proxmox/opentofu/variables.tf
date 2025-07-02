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

## VM Variables
variable "bios" {
  description = "VM bios, setting to `ovmf` will automatically create a EFI disk."
  type        = string
  default     = "seabios"
  validation {
    condition     = contains(["seabios", "ovmf"], var.bios)
    error_message = "Invalid bios setting: ${var.bios}. Valid options: 'seabios' or 'ovmf'."
  }
}

variable "ci_ssh_key" {
  description = "File path to SSH key for 'default' user, e.g. `~/.ssh/id_ed25519.pub`."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
