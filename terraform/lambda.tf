# CloudWatch log group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = var.cloudwatch_log_retention_days
  
  tags = local.common_tags
}

# Lambda function for API
resource "aws_lambda_function" "api" {
  function_name = local.lambda_function_name
  description   = "CloudBox API Lambda function"
  
  # Deployment package (ZIP file)
  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  
  # Runtime configuration
  handler     = "index.handler"
  runtime     = var.lambda_runtime
  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout
  
  # IAM role
  role = aws_iam_role.lambda_execution.arn
  
  # Environment variables
  environment {
    variables = {
      DYNAMODB_TABLE       = aws_dynamodb_table.metadata.name
      S3_BUCKET            = aws_s3_bucket.files.id
      API_KEYS_SECRET_NAME = aws_secretsmanager_secret.api_keys.name
      JWT_SECRET_NAME      = aws_secretsmanager_secret.jwt_secret.name
      ENVIRONMENT          = local.environment
    }
  }
  
  # Ensure CloudWatch log group exists before Lambda
  depends_on = [
    aws_cloudwatch_log_group.lambda_logs
  ]
  
  tags = local.common_tags
}

# Create deployment package for Lambda
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/../api"
  output_path = "${path.module}/../dist/lambda-${local.environment}.zip"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  
  # Allow invocation from API Gateway stage
  source_arn = "${aws_api_gateway_rest_api.cloudbox.execution_arn}/*/*"
}

# CloudWatch alarm for Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.lambda_function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This alarm monitors Lambda function errors"
  
  dimensions = {
    FunctionName = aws_lambda_function.api.function_name
  }
  
  alarm_actions = []  # Add SNS topic ARNs here if needed
  
  tags = local.common_tags
}
