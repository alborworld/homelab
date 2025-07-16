# S3 bucket for Terraform state storage

resource "minio_s3_bucket" "tfstate" {
  bucket = "tfstate"
  acl    = "private"
}

resource "minio_s3_bucket_versioning" "tfstate" {
  bucket = minio_s3_bucket.tfstate.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "minio_s3_bucket_policy" "tfstate_policy" {
  bucket = minio_s3_bucket.tfstate.bucket
  policy = file("${path.module}/tfstate_policy.json")
}
