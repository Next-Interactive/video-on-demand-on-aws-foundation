resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_18:Ensure the S3 bucket has access logging enabled
  #checkov:skip=CKV_AWS_145:Ensure that S3 buckets are encrypted with KMS by default
  #checkov:skip=CKV_AWS_144:Ensure that S3 bucket has cross-region replication enabled
  #checkov:skip=CKV_AWS_21:Ensure all data stored in the S3 bucket have versioning enabled
  #checkov:skip=CKV2_AWS_62:Ensure S3 buckets should have event notifications enabled
  bucket        = "${var.bucket_name}-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  #checkov:skip=CKV_AWS_300:Ensure S3 lifecycle configuration sets period for aborting failed uploads
  bucket = aws_s3_bucket.this.id

  rule {
    id = "retention"

    filter {}

    expiration {
      days = 30
    }

    status = "Enabled"
  }
}
