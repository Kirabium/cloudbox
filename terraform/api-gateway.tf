# API Gateway REST API
resource "aws_api_gateway_rest_api" "cloudbox" {
  name        = local.api_gateway_name
  description = "CloudBox API for file storage"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  tags = local.common_tags
}

# API Gateway resource for each endpoint
resource "aws_api_gateway_resource" "endpoints" {
  for_each = { for endpoint in local.api_endpoints : endpoint.name => endpoint }
  
  rest_api_id = aws_api_gateway_rest_api.cloudbox.id
  parent_id   = aws_api_gateway_rest_api.cloudbox.root_resource_id
  path_part   = each.key
}

# API Gateway methods for each endpoint
resource "aws_api_gateway_method" "endpoints" {
  for_each = { for endpoint in local.api_endpoints : endpoint.name => endpoint }
  
  rest_api_id   = aws_api_gateway_rest_api.cloudbox.id
  resource_id   = aws_api_gateway_resource.endpoints[each.key].id
  http_method   = each.value.method
  authorization = "NONE"
  
  # Enable API key for authentication if not using Cognito
  api_key_required = !var.enable_cognito_auth
}

# API Gateway integrations with Lambda
resource "aws_api_gateway_integration" "lambda" {
  for_each = { for endpoint in local.api_endpoints : endpoint.name => endpoint }
  
  rest_api_id             = aws_api_gateway_rest_api.cloudbox.id
  resource_id             = aws_api_gateway_resource.endpoints[each.key].id
  http_method             = aws_api_gateway_method.endpoints[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api.invoke_arn
}

# Enable CORS for each resource
resource "aws_api_gateway_method" "cors" {
  for_each = { for endpoint in local.api_endpoints : endpoint.name => endpoint }
  
  rest_api_id   = aws_api_gateway_rest_api.cloudbox.id
  resource_id   = aws_api_gateway_resource.endpoints[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors" {
  for_each = { for endpoint in local.api_endpoints : endpoint.name => endpoint }
  
  rest_api_id = aws_api_gateway_rest_api.cloudbox.id
  resource_id = aws_api_gateway_resource.endpoints[each.key].id
  http_method = aws_api_gateway_method.cors[each.key].http_method
  type        = "MOCK"
  
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "cors" {
  for_each = { for endpoint in local.api_endpoints : endpoint.name => endpoint }
  
  rest_api_id = aws_api_gateway_rest_api.cloudbox.id
  resource_id = aws_api_gateway_resource.endpoints[each.key].id
  http_method = aws_api_gateway_method.cors[each.key].http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "cors" {
  for_each = { for endpoint in local.api_endpoints : endpoint.name => endpoint }
  
  rest_api_id = aws_api_gateway_rest_api.cloudbox.id
  resource_id = aws_api_gateway_resource.endpoints[each.key].id
  http_method = aws_api_gateway_method.cors[each.key].http_method
  status_code = aws_api_gateway_method_response.cors[each.key].status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Api-Key,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "cloudbox" {
  rest_api_id = aws_api_gateway_rest_api.cloudbox.id
  
  # Trigger redeployment when API config changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.cloudbox.body,
      [for endpoint in local.api_endpoints : aws_api_gateway_resource.endpoints[endpoint.name].id],
      [for endpoint in local.api_endpoints : aws_api_gateway_method.endpoints[endpoint.name].id],
      [for endpoint in local.api_endpoints : aws_api_gateway_integration.lambda[endpoint.name].id],
    ]))
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "cloudbox" {
  deployment_id = aws_api_gateway_deployment.cloudbox.id
  rest_api_id   = aws_api_gateway_rest_api.cloudbox.id
  stage_name    = var.api_gateway_stage_name
  
  # Enable CloudWatch logs
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
    })
  }
  
  # Enable detailed metrics
  xray_tracing_enabled = true
  
  tags = local.common_tags
}

# API Gateway Usage Plan
resource "aws_api_gateway_usage_plan" "cloudbox" {
  name        = "${var.app_name}-usage-plan-${local.environment}"
  description = "CloudBox API usage plan"
  
  api_stages {
    api_id = aws_api_gateway_rest_api.cloudbox.id
    stage  = aws_api_gateway_stage.cloudbox.stage_name
  }
  
  quota_settings {
    limit  = 1000  # Requests per period
    period = "DAY"
  }
  
  throttle_settings {
    burst_limit = 20
    rate_limit  = 10
  }
  
  tags = local.common_tags
}

# API Gateway API Keys
resource "aws_api_gateway_api_key" "user_keys" {
  for_each = var.api_keys
  
  name        = "${each.key}-${local.environment}"
  description = "API Key for user ${each.key}"
  enabled     = true
  
  tags = local.common_tags
}

# API Gateway Usage Plan Key associations
resource "aws_api_gateway_usage_plan_key" "main" {
  for_each = var.api_keys
  
  key_id        = aws_api_gateway_api_key.user_keys[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.cloudbox.id
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.cloudbox.id}/${var.api_gateway_stage_name}"
  retention_in_days = var.cloudwatch_log_retention_days
  
  tags = local.common_tags
}

# CloudWatch Alarm for API Gateway errors
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx" {
  alarm_name          = "${var.app_name}-api-gateway-5xx-${local.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This alarm monitors API Gateway 5XX errors"
  
  dimensions = {
    ApiName = aws_api_gateway_rest_api.cloudbox.name
    Stage   = aws_api_gateway_stage.cloudbox.stage_name
  }
  
  alarm_actions = []  # Add SNS topic ARNs here if needed
  
  tags = local.common_tags
}
