# =============================================================================
# S3 Buckets for TrustFix Demo
# =============================================================================
# These buckets are properly configured (encrypted, not public).
# They are referenced by the vulnerable roles to demonstrate permissions.
# =============================================================================

resource "aws_s3_bucket" "demo_data" {
  bucket = "trustfix-demo-data-${random_id.suffix.hex}"

  tags = {
    Name         = "TrustFix Demo Data"
    Purpose      = "Referenced by vulnerable IAM roles"
    TrustFixDemo = "true"
  }
}

resource "aws_s3_bucket_versioning" "demo_data" {
  bucket = aws_s3_bucket.demo_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "demo_data" {
  bucket = aws_s3_bucket.demo_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "demo_data" {
  bucket = aws_s3_bucket.demo_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "demo_artifacts" {
  bucket = "trustfix-demo-artifacts-${random_id.suffix.hex}"

  tags = {
    Name         = "TrustFix Demo Artifacts"
    Purpose      = "CI/CD artifacts storage"
    TrustFixDemo = "true"
  }
}

resource "aws_s3_bucket_versioning" "demo_artifacts" {
  bucket = aws_s3_bucket.demo_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "demo_artifacts" {
  bucket = aws_s3_bucket.demo_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "demo_artifacts" {
  bucket = aws_s3_bucket.demo_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "demo_readme" {
  bucket  = aws_s3_bucket.demo_data.id
  key     = "README.txt"
  content = <<-EOT
    TrustFix Demo Environment
    =========================

    This bucket is part of the TrustFix demo environment.
    It is used to demonstrate IAM role permissions.

    WARNING: This environment contains intentionally vulnerable
    configurations. Do not store sensitive data here.
  EOT

  tags = {
    TrustFixDemo = "true"
  }
}
