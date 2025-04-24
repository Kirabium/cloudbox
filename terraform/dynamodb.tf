resource "aws_dynamodb_table" "metadata" {
  name         = local.dynamodb_table_name
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "userId"
  range_key    = "fileId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "fileId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  # Global Secondary Index for querying by creation date
  global_secondary_index {
    name               = "CreatedAtIndex"
    hash_key           = "userId"
    range_key          = "createdAt"
    write_capacity     = var.dynamodb_billing_mode == "PROVISIONED" ? 5 : null
    read_capacity      = var.dynamodb_billing_mode == "PROVISIONED" ? 5 : null
    projection_type    = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "CloudBox File Metadata"
    }
  )
}

# Optional: Create a DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.app_name}-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "CloudBox Terraform State Locks"
    }
  )
}
