terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "~> 3.6.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "minio" {
  # required
  minio_server   = var.minio_server
  minio_user     = var.minio_user
  minio_password = var.minio_password

  # optional
  minio_region      = var.minio_region
  minio_api_version = var.minio_api_version
  minio_ssl         = var.minio_ssl
}
