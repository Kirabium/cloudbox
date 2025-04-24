variable "aws_region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "The name of the application"
  type        = string
  default     = "cloudbox"
}

variable "lambda_runtime" {
  description = "The runtime for the Lambda functions"
  type        = string
  default     = "nodejs16.x"
}

variable "lambda_memory_size" {
  description = "The memory allocation for Lambda functions in MB"
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "The timeout for Lambda functions in seconds"
  type        = number
  default     = 30
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket for file storage"
  type        = string
  # This will be overridden in tfvars files
  default     = ""
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table for file metadata"
  type        = string
  # This will be overridden in tfvars files
  default     = ""
}

variable "dynamodb_billing_mode" {
  description = "The billing mode for the DynamoDB table"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "api_gateway_name" {
  description = "The name of the API Gateway"
  type        = string
  default     = "CloudBox API"
}

variable "api_gateway_stage_name" {
  description = "The name of the API Gateway stage"
  type        = string
  default     = "v1"
}

variable "api_gateway_logging_level" {
  description = "The logging level for API Gateway"
  type        = string
  default     = "INFO"
}

variable "enable_cognito_auth" {
  description = "Whether to enable Cognito authentication"
  type        = bool
  default     = false
}

variable "api_keys" {
  description = "A map of user IDs to API keys"
  type        = map(string)
  # This will be overridden in tfvars files
  default     = {}
  sensitive   = true
}

variable "jwt_secret" {
  description = "The secret for JWT token verification"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cloudwatch_log_retention_days" {
  description = "The number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
