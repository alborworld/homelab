# S3 Backend Configuration for Garage

terraform {
  backend "s3" {
    bucket                      = "tfstate"
    key                         = "alborworld/garage.tfstate"
    region                      = "garage"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
    endpoints = {
      s3 = "https://s3.home.alborworld.com"
    }
  }
}
