resource "aws_secretsmanager_secret" "api_keys" {
  name        = local.api_keys_secret_name
  description = "API Keys for CloudBox authentication"
  
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id     = aws_secretsmanager_secret.api_keys.id
  secret_string = jsonencode({
    apiKeys = var.api_keys
  })
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name        = local.jwt_secret_name
  description = "Secret for JWT token verification"
  
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = jsonencode({
    jwtSecret = var.jwt_secret != "" ? var.jwt_secret : random_password.jwt_secret[0].result
  })
}

# Generate a random JWT secret if none is provided
resource "random_password" "jwt_secret" {
  count = var.jwt_secret == "" ? 1 : 0
  
  length           = 32
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}|;:,.<>?"
}
