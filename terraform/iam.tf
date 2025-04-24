# IAM role for Lambda execution
resource "aws_iam_role" "lambda_execution" {
  name = "${var.app_name}-lambda-role-${local.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Lambda basic execution policy (for CloudWatch logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for S3 access
resource "aws_iam_policy" "s3_access" {
  name        = "${var.app_name}-s3-access-${local.environment}"
  description = "Allows Lambda to access the CloudBox S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.files.arn,
          "${aws_s3_bucket.files.arn}/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

# Custom policy for DynamoDB access
resource "aws_iam_policy" "dynamodb_access" {
  name        = "${var.app_name}-dynamodb-access-${local.environment}"
  description = "Allows Lambda to access CloudBox DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = [
          aws_dynamodb_table.metadata.arn,
          "${aws_dynamodb_table.metadata.arn}/index/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

# Custom policy for Secrets Manager access
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.app_name}-secrets-access-${local.environment}"
  description = "Allows Lambda to access CloudBox secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = [
          aws_secretsmanager_secret.api_keys.arn,
          aws_secretsmanager_secret.jwt_secret.arn
        ]
      }
    ]
  })

  tags = local.common_tags
}

# Attach custom policies to Lambda role
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.secrets_access.arn
}
