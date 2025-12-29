# S3 Backend Configuration for Garage
#
# BOOTSTRAP NOTE:
# Initially run with local state. After first apply:
# 1. Uncomment the backend block below
# 2. Run: tofu init -migrate-state
# 3. Confirm state migration to S3

# terraform {
#   backend "s3" {
#     bucket                      = "tfstate"
#     key                         = "alborworld/garage.tfstate"
#     region                      = "main"
#     skip_credentials_validation = true
#     skip_requesting_account_id  = true
#     skip_metadata_api_check     = true
#     skip_region_validation      = true
#     use_path_style              = true
#     endpoints = {
#       s3 = "https://s3.home.alborworld.com"
#     }
#   }
# }
