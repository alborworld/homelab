terraform {
  required_providers {
    garage = {
      source  = "jkossis/garage"
      version = "~> 1.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "garage" {
  endpoint = var.garage_admin_endpoint
  token    = var.garage_admin_token
}
