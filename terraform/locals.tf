locals {
  environment = terraform.workspace
  
  # Derive resource names with environment prefix
  s3_bucket_name     = var.s3_bucket_name != "" ? var.s3_bucket_name : "${var.app_name}-files-${local.environment}"
  dynamodb_table_name = var.dynamodb_table_name != "" ? var.dynamodb_table_name : "${var.app_name}-metadata-${local.environment}"
  
  # Lambda function names
  lambda_function_name = "${var.app_name}-api-${local.environment}"
  
  # API Gateway resources
  api_gateway_name = "${var.api_gateway_name} - ${title(local.environment)}"
  
  # Secret names
  api_keys_secret_name = "${var.app_name}/api-keys/${local.environment}"
  jwt_secret_name      = "${var.app_name}/jwt-secret/${local.environment}"
  
  # Common tags
  common_tags = merge(
    var.tags,
    {
      Environment = local.environment
      Project     = "CloudBox"
      ManagedBy   = "Terraform"
    }
  )
  
  # API endpoints
  api_endpoints = [
    {
      name   = "upload"
      method = "POST"
      path   = "/upload"
    },
    {
      name   = "list"
      method = "GET"
      path   = "/list"
    },
    {
      name   = "download"
      method = "GET"
      path   = "/download"
    },
    {
      name   = "delete"
      method = "DELETE"
      path   = "/delete"
    }
  ]
}
