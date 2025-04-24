#!/bin/bash
# CloudBox Build & Deploy Script

set -e  # Exit on any error

# Parse command line arguments
ENV="dev"
DEPLOY=false

print_usage() {
  echo "Usage: $0 [-e|--env <environment>] [-d|--deploy]"
  echo "  -e, --env       Target environment (dev or prod, default: dev)"
  echo "  -d, --deploy    Deploy after building"
  exit 1
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -e|--env) ENV="$2"; shift ;;
    -d|--deploy) DEPLOY=true ;;
    -h|--help) print_usage ;;
    *) echo "Unknown parameter: $1"; print_usage ;;
  esac
  shift
done

# Validate environment
if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "Error: Environment must be 'dev' or 'prod'"
  exit 1
fi

echo "Building CloudBox API for $ENV environment..."

# Create directories if they don't exist
mkdir -p dist

# Install dependencies
echo "Installing dependencies..."
cd api
npm ci --production
cd ..

# Create the Lambda deployment package
echo "Creating Lambda deployment package..."
cd api
zip -r ../dist/lambda-$ENV.zip . -x "*.git*" -x "node_modules/aws-sdk/*"
cd ..

echo "Lambda package created: dist/lambda-$ENV.zip"

# Deploy if requested
if [ "$DEPLOY" = true ]; then
  echo "Deploying to $ENV environment..."
  
  # Initialize Terraform
  cd terraform
  terraform init \
    -backend-config="bucket=cloudbox-tf-state" \
    -backend-config="key=$ENV/terraform.tfstate" \
    -backend-config="region=us-east-1"
  
  # Select or create workspace
  terraform workspace select $ENV || terraform workspace new $ENV
  
  # Apply Terraform changes
  terraform apply -var-file="env/$ENV.tfvars" -auto-approve
  
  # Get Lambda function name
  LAMBDA_FUNCTION=$(terraform output -raw lambda_function_name)
  
  cd ..
  
  # Update Lambda function code
  echo "Updating Lambda function code..."
  aws lambda update-function-code \
    --function-name $LAMBDA_FUNCTION \
    --zip-file fileb://dist/lambda-$ENV.zip
  
  echo "Deployment complete!"
else
  echo "Skip deployment. Run with -d or --deploy to deploy."
fi

echo "Build complete!"
