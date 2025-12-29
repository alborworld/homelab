# Garage S3 Infrastructure for OpenTofu State Storage
#
# This stack manages:
# - Access key for OpenTofu state operations
# - Bucket permissions for the tfstate bucket

# Reference existing tfstate bucket (already created manually)
data "garage_bucket" "tfstate" {
  global_alias = "tfstate"
}

# Access key for OpenTofu
# Import existing key: tofu import garage_key.tofu <KEY_ID>
resource "garage_key" "tofu" {
  name = "opentofu-state"
}

# Grant read/write permissions to the key on tfstate bucket
resource "garage_bucket_permission" "tofu_tfstate" {
  bucket_id     = data.garage_bucket.tfstate.id
  access_key_id = garage_key.tofu.id
  read          = true
  write         = true
  owner         = true
}
