resource "aws_s3_bucket" "files" {
  bucket = local.s3_bucket_name
  
  tags = merge(
    local.common_tags,
    {
      Name = "CloudBox File Storage"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "files" {
  bucket = aws_s3_bucket.files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "files" {
  bucket = aws_s3_bucket.files.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "files" {
  bucket = aws_s3_bucket.files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "files" {
  bucket = aws_s3_bucket.files.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Optional - Create a separate bucket for deployment artifacts
resource "aws_s3_bucket" "deployment" {
  bucket = "${var.app_name}-deployment-${local.environment}"
  
  tags = merge(
    local.common_tags,
    {
      Name = "CloudBox Deployment Artifacts"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  rule {
    id     = "delete-old-artifacts"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}
