variable "garage_admin_endpoint" {
  type        = string
  description = "Garage Admin API endpoint URL"
  default     = "https://admin.s3.home.alborworld.com"
}

variable "garage_admin_token" {
  type        = string
  description = "Garage Admin API token (from GARAGE_ADMIN_TOKEN)"
  sensitive   = true
}

variable "tofu_key_id" {
  type        = string
  description = "Existing Garage access key ID to import"
}
