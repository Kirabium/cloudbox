/**
 * CloudBox - Serverless File Storage API
 * 
 * This is the main Terraform configuration file for CloudBox,
 * a serverless REST API for file uploads, downloads, and management.
 * 
 * Author: Virgile Fantauzzi
 */

# Set a random suffix for globally unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# Create a directory for Lambda deployment packages if it doesn't exist
resource "null_resource" "create_dist_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/../dist"
  }
}

# AWS X-Ray for tracing (optional)
resource "aws_xray_sampling_rule" "cloudbox" {
  rule_name      = "${var.app_name}-sampling-rule-${local.environment}"
  priority       = 1000
  reservoir_size = 1
  fixed_rate     = 0.05
  url_path       = "/*"
  host           = "*"
  http_method    = "*"
  service_name   = "*"
  service_type   = "*"
  
  attributes = {
    Environment = local.environment
  }
}

# For multi-region deployments (optional)
data "aws_regions" "available" {}

# Initial version info (for tracking updates)
locals {
  version_info = {
    terraform_version = "v1.0.0"
    app_version       = "v1.0.0"
    deployed_at       = timestamp()
  }
}
