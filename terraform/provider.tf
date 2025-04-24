provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "CloudBox"
      Environment = terraform.workspace
      ManagedBy   = "Terraform"
      Owner       = "Virgile Fantauzzi"
    }
  }
}
