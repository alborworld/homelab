output "tfstate_bucket_id" {
  description = "ID of the tfstate bucket"
  value       = data.garage_bucket.tfstate.id
}

output "tofu_key_id" {
  description = "Access key ID for OpenTofu (use as TOFU_KEY_ID)"
  value       = garage_key.tofu.id
  sensitive   = true
}

output "tofu_key_secret" {
  description = "Secret access key for OpenTofu (use as TOFU_KEY_SECRET)"
  value       = garage_key.tofu.secret_access_key
  sensitive   = true
}
