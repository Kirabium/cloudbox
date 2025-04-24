output "api_url" {
  description = "URL of the CloudBox API"
  value       = "${aws_api_gateway_deployment.cloudbox.invoke_url}${aws_api_gateway_stage.cloudbox.stage_name}"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for file storage"
  value       = aws_s3_bucket.files.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for metadata"
  value       = aws_dynamodb_table.metadata.name
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.api.function_name
}

output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.cloudbox.id
}

output "api_endpoints" {
  description = "Available API endpoints"
  value = {
    for endpoint in local.api_endpoints :
    endpoint.name => "${aws_api_gateway_deployment.cloudbox.invoke_url}${aws_api_gateway_stage.cloudbox.stage_name}${endpoint.path}"
  }
}

output "environment" {
  description = "Current environment (from Terraform workspace)"
  value       = local.environment
}

output "api_keys_secret_arn" {
  description = "ARN of the Secrets Manager secret containing API keys"
  value       = aws_secretsmanager_secret.api_keys.arn
}

output "jwt_secret_arn" {
  description = "ARN of the Secrets Manager secret containing JWT secret"
  value       = aws_secretsmanager_secret.jwt_secret.arn
}
