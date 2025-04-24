terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }

  backend "s3" {
    # These values are provided during terraform init via -backend-config
    # bucket         = "cloudbox-tf-state"
    # key            = "env/terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "cloudbox-tf-locks"
    # encrypt        = true
  }
}
