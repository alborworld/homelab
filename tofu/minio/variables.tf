variable "minio_server" {
  type        = string
  description = "The MinIO server hostname and port (e.g., 'minio.example.com:9000')."
}

variable "minio_user" {
  type        = string
  description = "The MinIO access key or username."
  sensitive   = true
}

variable "minio_password" {
  type        = string
  description = "The MinIO secret key or password."
  sensitive   = true
}

variable "minio_region" {
  type        = string
  description = "The MinIO region."
  default     = "main"
}

variable "minio_api_version" {
  type        = string
  description = "The MinIO API version ('v2' or 'v4', defaults to 'v4')."
  default     = "v4"
}

variable "minio_ssl" {
  type        = bool
  description = "Set to true to enable SSL/TLS for MinIO connections."
  default     = false
}

