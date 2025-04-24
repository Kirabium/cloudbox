import os

# Define the directory structure for CloudBox
structure = [
    "cloudbox/terraform/env",
    "cloudbox/api/utils",
    "cloudbox/scripts",
    "cloudbox/.github/workflows",
    "cloudbox/monitoring",
    "cloudbox/docs/screenshots"
]

# Define base files to be created with placeholder content
files = {
    "cloudbox/terraform/main.tf": "",
    "cloudbox/terraform/variables.tf": "",
    "cloudbox/terraform/outputs.tf": "",
    "cloudbox/terraform/backend.tf": "",
    "cloudbox/terraform/provider.tf": "",
    "cloudbox/terraform/s3.tf": "",
    "cloudbox/terraform/dynamodb.tf": "",
    "cloudbox/terraform/lambda.tf": "",
    "cloudbox/terraform/api-gateway.tf": "",
    "cloudbox/terraform/iam.tf": "",
    "cloudbox/terraform/secrets-manager.tf": "",
    "cloudbox/terraform/locals.tf": "",
    "cloudbox/terraform/env/dev.tfvars": "",
    "cloudbox/terraform/env/prod.tfvars": "",
    "cloudbox/api/index.js": "",
    "cloudbox/api/upload.js": "",
    "cloudbox/api/list.js": "",
    "cloudbox/api/download.js": "",
    "cloudbox/api/delete.js": "",
    "cloudbox/api/package.json": "",
    "cloudbox/api/utils/s3.js": "",
    "cloudbox/scripts/build.sh": "",
    "cloudbox/.github/workflows/deploy.yml": "",
    "cloudbox/monitoring/cloudwatch-dashboard.json": "",
    "cloudbox/monitoring/datadog-config.json": "",
    "cloudbox/docs/README.md": "",
    "cloudbox/docs/cloudbox-demo.mp4": "",
    "cloudbox/README.md": "",
    "cloudbox/.gitignore": "",
    "cloudbox/.nvmrc": "",
    "cloudbox/journal.md": ""
}

# Create directories
for dir in structure:
    os.makedirs(dir, exist_ok=True)

# Create files
for file_path, content in files.items():
    with open(file_path, "w") as f:
        f.write(content)

"Arborescence CloudBox générée avec succès."